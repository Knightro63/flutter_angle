#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif

@objc public class FlutterAnglePlugin: NSObject, FlutterPlugin {
  // Flutter texture-related
  private var textureRegistry: FlutterTextureRegistry
  private var eglInfo: EGLInfo?
  private var renders: [Int64: FlutterAngleSimPlugin];
    
  init(textureRegistry: FlutterTextureRegistry) {
    self.textureRegistry = textureRegistry;
    self.renders = [Int64: FlutterAngleSimPlugin]();
  }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let method = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger())
    let instance = FlutterAnglePlugin(textureRegistry: registrar.textures())
    #elseif os(macOS)
    let method = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger)
    let instance = FlutterAnglePlugin(textureRegistry: registrar.textures)
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
        let render = FlutterAngleSimPlugin(textureRegistry: textureRegistry);
        textureId = render.textureId;
        self.renders[textureId!] = render;
        self.renders[textureId!]!.setInfo(info: eglInfo)
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
        return;
      case "textureFrameAvailable", "updateTexture":
        guard let args = call.arguments as? [String: Any],
          let textureId = args["textureId"] as? Int64 else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
          return
        }
        self.renders[textureId]!.textureFrameAvailable(result: result)
      case "initOpenGL":
        eglInfo = nil
        eglInfo = FlutterAngleSimPlugin.initOpenGL(result: result)
        result(["isSimulator": true])
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
