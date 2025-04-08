#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif
import IOSurface

@objc public class FlutterAnglePlugin: NSObject, FlutterPlugin {
    // Flutter texture-related
    private var textureRegistry: FlutterTextureRegistry
    
    #if targetEnvironment(simulator)
    private var renders: [Int64: FlutterAngleSimPlugin];
    #else
    private var renders: [Int64: FlutterAngleOSPlugin];
    #endif
    
    init(textureRegistry: FlutterTextureRegistry) {
      self.textureRegistry = textureRegistry;
        #if targetEnvironment(simulator)
            self.renders = [Int64: FlutterAngleSimPlugin]();
        #else
            self.renders = [Int64: FlutterAngleOSPlugin]();
        #endif
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
            #if targetEnvironment(simulator)
                simPlugin?.createTexture(width: width, height: height, ftr: self ,result: result);
            #else
                var textureId: Int64?;
                let render = FlutterAngleOSPlugin(textureRegistry: textureRegistry);
                textureId = render.textureId;
                self.renders[textureId!] = render;
                print("Texture ID is: \(textureId)")
                self.renders[textureId!]!.createTexture(width: width, height: height, result: result)
            #endif
        case "disposeTexture":
            guard let textureId = call.arguments as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
                return
            }
            #if targetEnvironment(simulator)
                simPlugin?.disposeTexture(textureId: textureId)
            #else
                self.renders[textureId]!.disposeTexture(textureId: textureId)
            #endif
        case "getIOSurfaceHandle":
            guard let textureId = call.arguments as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
                return
            }
            #if !targetEnvironment(simulator)
                self.renders[textureId]!.getIOSurfaceHandle(result: result)
            #endif
        case "textureFrameAvailable":
            guard let textureId = call.arguments as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
                return
            }
            #if !targetEnvironment(simulator)
                self.renders[textureId]!.textureFrameAvailable(result: result)
            #endif
        case "initOpenGL":
            #if targetEnvironment(simulator)
                simPlugin?.initOpenGL()
            #else
                result(["isSimulator": false])
            #endif
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
