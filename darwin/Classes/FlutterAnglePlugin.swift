#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
import libEGL
import libGLESv2

public class FlutterAnglePlugin: NSObject, FlutterPlugin {
  var registry: FlutterTextureRegistry;
  var textureId: Int64?;
  var pixelData:CVPixelBuffer?;
  var mtlRenders: [Int64:MTLRender];
  var oglRenders: [Int64:OpenGLRender];
    
  var width:Int = 0;
  var height:Int = 0;
    
  var mtlContext:MTLEglEnv?;
  var openGlContext:OGLEglEnv?;
  
  init(textureRegistry: FlutterTextureRegistry) {
      self.mtlRenders = [Int64: MTLRender]();
      self.oglRenders = [Int64: OpenGLRender]();
    self.registry = textureRegistry;
  }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let channel = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger())
      let instance = FlutterAnglePlugin(textureRegistry: registrar.textures())
    #elseif os(macOS)
    let channel = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger)
      let instance = FlutterAnglePlugin(textureRegistry: registrar.textures)
    #endif
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "initOpenGL":
      if mtlContext != nil{
        return;
      }
      else{
//        mtlContext = MTLEglEnv();
//        mtlContext!.setupRender();
      }
           
      if openGlContext == nil{
          openGlContext = OGLEglEnv();
          openGlContext!.setupRender();
      }
      result([
        "context" : mtlContext == nil ? nil : mtlContext!.getContext(),
        "openGLContext": openGlContext!.getContext(0),
        "dummySurface" : openGlContext!.getContext(2)
      ]);
      return;
    case "createTexture":
      guard let arguments = call.arguments as? [String:Any] else{
        result(FlutterError(code: "No arguments", message: "No arguments received by the native part of FlutterGL.deleteTexture", details: nil));
          return;
      }
      guard let width:Int = arguments["width"] as? Int else {
        result(FlutterError(code: "CreateTexture Error", message: "No width received by the native part of FlutterGL.createTexture",details:nil))
        return
      }
      guard let height:Int = arguments["height"] as? Int else {
        result(FlutterError(code: "CreateTexture Error", message: "No height received by the native part of FlutterGL.createTexture",details:nil))
        return
      }

      if(mtlContext != nil){
        let render = MTLRender(
          width,
          height,
          mtlContext!.context!
        );
        self.textureId = Int64( self.registry.register(render) );
        self.mtlRenders[textureId!] = render;
        result([
          "textureId": textureId,
          "rbo": render.frameBuffer,
          "metalAsGLTexture": render.metalAsGLTexture
        ]);
      }
      else{
        let render = OpenGLRender(
          width,
          height,
          openGlContext!
        );
        self.textureId = Int64( self.registry.register(render) );
        self.oglRenders[textureId!] = render;
        result([
          "textureId": textureId,
          "rbo": render.frameBuffer,
          "metalAsGLTexture": render.openGLAsTexture
        ]);
    }

        return;
    case "updateTexture":
      guard let arguments = call.arguments as? [String:Any] else{
        result(FlutterError(code: "No arguments", message: "No arguments received by the native part of FlutterGL.deleteTexture", details: nil));
          return;
      }
      guard let data:Int64 = arguments["textureId"] as? Int64 else {
        result(FlutterError(code: "updateTexture Error", message: "no texture id received by the native part of FlutterGL.updateTexture", details: nil));
        return;
      }

      self.registry.textureFrameAvailable(self.textureId!)
      result(nil);
      return;
    case "deleteTexture":
      guard let arguments = call.arguments as? [String:Any] else{
        result(FlutterError(code: "No arguments", message: "No arguments received by the native part of FlutterGL.deleteTexture", details: nil));
          return;
      }
      guard let data:Int64 = arguments["textureId"] as? Int64 else {
        result(FlutterError(code: "updateTexture Error", message: "no texture id received by the native part of FlutterGL.updateTexture", details: nil));
        return;
      }
        
        registry.unregisterTexture(textureId!);
        let render = self.mtlRenders[textureId!];
         render?.dispose();
        self.mtlRenders.removeValue(forKey: textureId!);
      
        let orender = self.oglRenders[textureId!];
         orender?.dispose();
        self.oglRenders.removeValue(forKey: textureId!);
      result(nil);
      return;

    case "getAll":
      result([
        "appName": Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String,
        //"packageName" : Bundle.main.infoDictionary?[kMDItemCFBundleIdentifier as String] as? String,
        "version" : Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String,
        "buildNumber" : Bundle.main.infoDictionary?[kCFBundleIdentifierKey as String] as? String,
      ]);
    default:
      result(FlutterMethodNotImplemented);
    }
  }
}
