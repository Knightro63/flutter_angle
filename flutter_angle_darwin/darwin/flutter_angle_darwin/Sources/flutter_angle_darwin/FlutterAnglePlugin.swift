#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif

@objc public class FlutterAnglePlugin: NSObject, FlutterPlugin {
  // Flutter texture-related
  private var textureRegistry: FlutterTextureRegistry
  private var renders: [Int64: FlutterAngleOSPlugin];
    
  init(textureRegistry: FlutterTextureRegistry) {
    self.textureRegistry = textureRegistry;
    self.renders = [Int64: FlutterAngleOSPlugin]();
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
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        var textureId: Int64?;
        let render = FlutterAngleOSPlugin(textureRegistry: textureRegistry);
        textureId = render.textureId;
        self.renders[textureId!] = render;
        self.renders[textureId!]!.createTexture(width: width, height: height, result: result)
      case "deleteTexture":
        guard let textureId = call.arguments as? Int64 else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
          return
        }
        self.renders[textureId]!.disposeTexture()
        self.renders.removeValue(forKey: textureId);
      case "getIOSurfaceHandle":
        guard let textureId = call.arguments as? Int64 else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
          return
        }
        self.renders[textureId]!.getIOSurfaceHandle(result: result)
      case "textureFrameAvailable", "updateTexture":
        guard let textureId = call.arguments as? Int64 else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
          return
        }
        self.renders[textureId]!.textureFrameAvailable(result: result)
      case "initOpenGL":
        result([])
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}