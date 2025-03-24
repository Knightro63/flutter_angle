#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

import libEGL
import libGLESv2

public class FlutterAnglePlugin: NSObject, FlutterPlugin {
    let registry: FlutterTextureRegistry
    var flutterGLTexture:FlutterGlTexture?
    var context:EGLContext?
    var surface:EGLSurface?
    var display:EGLDisplay?

    init(_ registry: FlutterTextureRegistry) {
        self.registry = registry
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let method = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger())
        let instance = FlutterAnglePlugin(registrar.textures())
        #elseif os(macOS)
        let method = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger)
        let instance = FlutterAnglePlugin(registrar.textures)
        #endif
        registrar.addMethodCallDelegate(instance, channel: method)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initOpenGL":
            result(initOpenGL())
            break;
        case "createTexture":
            guard let arguments = call.arguments as? [String:Any],
                let width:Int = arguments["width"] as? Int else {
                result(FlutterError(code: "No arguments", message: "Couldn't find width", details: nil))
                return
            }
            let height = arguments["height"] as? Int;
            if(height == nil){
                result(FlutterError(code: "No arguments", message: "Couldn't find height", details: nil))
                return
            }
            
            if(flutterGLTexture == nil){
                eglMakeCurrent(self.display, self.surface, self.surface, self.context)
                flutterGLTexture = FlutterGlTexture(registry, width, height!)
            }
            
            result([
                "textureId": flutterGLTexture!.flutterTextureId!,
                //"metalAsGLTexture": flutterGLTexture?.texture,
                "rbo": flutterGLTexture!.rbo,
            ]);
            break;
        case "updateTexture":
            guard let arguments = call.arguments as? [String:Any],
                  let _textureId:Int64 = arguments["textureId"] as? Int64 else {
                result(FlutterError(code: "ERROR", message: "Couldn't find textureId", details: nil))
                return
            }
            
            let currentTexture:FlutterGlTexture! = flutterGLTexture;

            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), currentTexture.fbo);
            glReadPixels(0, 0, GLsizei(currentTexture.width), GLsizei(currentTexture.height), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &currentTexture.pixelData);
     
            registry.textureFrameAvailable(currentTexture!.flutterTextureId!)
            
            result(nil);
            break;
        case "getAll":
            result([
                "appName": Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String,
                "packageName" : Bundle.main.bundleIdentifier,
                "version" : Bundle.main.infoDictionary!["CFBundleShortVersionString"],
                "buildNumber" : Bundle.main.infoDictionary!["CFBundleVersion"]
            ]);
            break;
        case "deleteTexture":
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
        
    }
    
    func initOpenGL() -> [String:UInt]?{
        guard let display = eglGetPlatformDisplay(EGLenum(EGL_PLATFORM_ANGLE_ANGLE), nil, nil) else {
            NSLog("eglGetPlatformDisplay() returned error \(eglGetError())")
            return nil
        }
        self.display = display
        var major:EGLint = 0
        var minor:EGLint = 0
        guard eglInitialize(display, &major, &minor) != 0 else {
            NSLog("eglInitialize() returned error \(eglGetError())")
            return nil
        }

        var configAttribs: [EGLint] = [
            EGL_RENDERABLE_TYPE,
            EGL_OPENGL_ES3_BIT,
            EGL_RED_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_BLUE_SIZE, 8,
            EGL_ALPHA_SIZE, 8,
            EGL_DEPTH_SIZE, 24,
            EGL_STENCIL_SIZE, 8,
            EGL_NONE
        ]

        let configs = UnsafeMutablePointer<EGLConfig?>.allocate(capacity: 1)
        defer { configs.deallocate() }

        var numConfigs: EGLint = 0
        guard eglChooseConfig(display, &configAttribs, configs, 1, &numConfigs) != 0 else {
            NSLog("eglChooseConfig() returned error \(eglGetError())")
            return nil
        }

        guard let config = configs.pointee else {
            NSLog("Empty config returned in eglChooseConfig()")
            return nil
        }
        
        var configId:EGLint = 0;
        eglGetConfigAttrib(display,config,EGL_CONFIG_ID,&configId);
        
        var contextAttribs: [EGLint] = [
            EGL_CONTEXT_CLIENT_VERSION,
            3,
            EGL_NONE
        ]

        guard let context = eglCreateContext(display, config, nil, &contextAttribs) else {
            NSLog("eglCreateContext() returned error \(eglGetError())")
            return nil
        }

//         // This is just a dummy surface that it needed to make an OpenGL context current (bind it to this thread)
//        let dummyLayer:CALayer = CALayer()//[[CALayer alloc] init];
//        dummyLayer.frame = CGRectMake(0, 0, 1, 1);
//        let dummyLayer2:CALayer = CALayer()//[[CALayer alloc] init];
//        dummyLayer2.frame = CGRectMake(0, 0, 1, 1);
//        
//
//        guard let dummySurface = eglCreateWindowSurface(display, config, unsafeBitCast(dummyLayer2, to: EGLNativeWindowType.self), nil) else {
//            NSLog("eglCreateWindowSurface() returned error \(eglGetError())")
//            return nil
//        }
//        guard let dummySurfaceForDartSide = eglCreateWindowSurface(display, config, unsafeBitCast(dummyLayer, to: EGLNativeWindowType.self), nil) else {
//            NSLog("eglCreateWindowSurface() returned error \(eglGetError())")
//            return nil
//        }
        
        let surfaceAttributes:[EGLint] = [
          EGL_WIDTH, 16,
          EGL_HEIGHT, 16,
          EGL_NONE
        ];
        let dummySurface = eglCreatePbufferSurface(display, config, surfaceAttributes);
        let dummySurfaceForDartSide = eglCreatePbufferSurface(display, config, surfaceAttributes);
        
        if (eglMakeCurrent(display, dummySurface, dummySurface, context) != 1){
             NSLog("MakeCurrent failed: %d",eglGetError());
            return nil
         }
        
        self.surface = dummySurface
        self.context = context
        
        return [
            "context": UInt(bitPattern: self.context),
            "dummySurface": UInt(bitPattern: dummySurfaceForDartSide),
            "eglConfigId": UInt(configId)
        ]
    }

}

public class FlutterGlTexture: NSObject, FlutterTexture{
    var width:Int = 0;
    var height:Int = 0;
    var pixelData:CVPixelBuffer!
    var flutterTextureId:Int64?
    let registry: FlutterTextureRegistry
    
    var texture:GLuint = 0;
    var fbo:GLuint = 0
    var rbo:GLuint = 0
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if pixelData == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(pixelData!);
    }
    
    init(_ registry: FlutterTextureRegistry,_ width:Int, _ height: Int){
        self.registry = registry
        super.init()
        self.width = width;
        self.height = height;
        let options:CFDictionary = [
            kCVPixelBufferOpenGLCompatibilityKey : true,
          kCVPixelBufferMetalCompatibilityKey : true
        ] as CFDictionary

        let status:CVReturn  = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            options,
            &pixelData
        );

        if (status != 0){
            NSLog("CVPixelBufferCreate error %d", status);
        }
        
        CVPixelBufferLockBaseAddress(pixelData!, CVPixelBufferLockFlags(rawValue: 0));
        let f = FlutterGlTexture(registry,width,height);
        //f.createMtlTextureFromCVPixBuffer(width,height);
        createTextureFromCVPixBuffer(width,height);
        self.flutterTextureId = self.registry.register(self)
    }
    
    @objc func createTextureFromCVPixBuffer(_ width:Int, _ height: Int){
        
        //let size = width * height * 4;
        glGenFramebuffers(1, &fbo);
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), fbo);

        glGenRenderbuffers(1, &rbo);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), rbo);

        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_RGBA8), GLsizei(width), GLsizei(height));
        var error = glGetError();
        if (error != GL_NO_ERROR){
            NSLog("GlError while allocating Renderbuffer %d", error);
        }
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER),rbo);
        let frameBufferCheck = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER));
        if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE)
        {
            NSLog("Framebuffer Error while creating Texture %d", frameBufferCheck);
        }

        error = glGetError() ;
        if( error != GL_NO_ERROR){
            NSLog("GlError while allocating Renderbuffer %d", error);
        }
    }
}
