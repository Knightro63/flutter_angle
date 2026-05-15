#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif

@objc public class FlutterAngleDarwinPlugin: NSObject, FlutterPlugin {
  // Flutter texture-related
  private var textureRegistry: FlutterTextureRegistry
  #if targetEnvironment(simulator)
  private var eglInfo: EGLInfo?
  private var renders: [Int64: FlutterAngleDarwinSimPlugin];
  #else
  private var renders: [Int64: FlutterAngleDarwinOSPlugin];
  #endif
    
  init(textureRegistry: FlutterTextureRegistry) {
    self.textureRegistry = textureRegistry;
    #if targetEnvironment(simulator)
    self.renders = [Int64: FlutterAngleDarwinSimPlugin]();
    #else
    self.renders = [Int64: FlutterAngleDarwinOSPlugin]();
    #endif
  }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let method = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger())
    let instance = FlutterAngleDarwinPlugin(textureRegistry: registrar.textures())
    #elseif os(macOS)
    let method = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger)
    let instance = FlutterAngleDarwinPlugin(textureRegistry: registrar.textures)
    #endif
    
    registrar.addMethodCallDelegate(instance, channel: method)
  }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "createTexture":
        guard let args = call.arguments as? [String: Any],
          let width = args["width"] as? Int,
          let height = args["height"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid Width and Height", details: nil))
            return
        }
        var textureId: Int64?;
        #if targetEnvironment(simulator)
        let render = FlutterAngleDarwinSimPlugin(textureRegistry: textureRegistry);
        #else
        let render = FlutterAngleDarwinOSPlugin(textureRegistry: textureRegistry);
        #endif
        textureId = render.textureId;
        self.renders[textureId!] = render;
        #if targetEnvironment(simulator)
        self.renders[textureId!]!.setInfo(info: eglInfo)
        #endif
        self.renders[textureId!]!.createTexture(width: width, height: height, result: result)
      case "resizeTexture":
        guard let args = call.arguments as? [String: Any],
          let width = args["width"] as? Int,
          let height = args["height"] as? Int,
          let textureId = args["textureId"] as? Int64 else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid Width and Height", details: nil))
            return
          }
        self.renders[textureId]!.resizeTexture(width: width, height: height, result: result)
      case "deleteTexture":
        guard let args = call.arguments as? [String: Any],
          let textureId = args["textureId"] as? Int64 else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
          return
        }
        self.renders[textureId]!.disposeTexture()
        self.renders.removeValue(forKey: textureId);
      case "getIOSurfaceHandle":
        #if !targetEnvironment(simulator)
        guard let textureId = call.arguments as? Int64 else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
          return
        }
        self.renders[textureId]!.getIOSurfaceHandle(result: result)
        #endif
      case "textureFrameAvailable", "updateTexture":
        guard let args = call.arguments as? [String: Any],
          let textureId = args["textureId"] as? Int64 else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
          return
        }
        guard let render = self.renders[textureId] else {
          // A late frame callback can arrive after the texture has been disposed.
          result(nil)
          return
        }
        render.textureFrameAvailable(result: result)
      case "initOpenGL":
        #if targetEnvironment(simulator)
        eglInfo = nil
        eglInfo = FlutterAngleDarwinSimPlugin.initOpenGL(result: result)
        result(["isSimulator": true])
        #else
        result(["isSimulator": false])
        #endif
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
