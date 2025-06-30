#if targetEnvironment(simulator)

import Flutter
import libEGL
import libGLESv2

private struct TextureInfo {
    var rboId: UInt32 = 0
    var fboId: UInt32 = 0
    var metalTextureId: UInt32 = 0
    var frameCount: Int = 0
}

public struct EGLInfo {
    var eglDisplay: UnsafeMutableRawPointer
    var eglContext: UnsafeMutableRawPointer
    var eglSurface: UnsafeMutableRawPointer
}

@objc public class FlutterAngleSimPlugin: NSObject{
    private var textureRegistry: FlutterTextureRegistry?
    private var pixelBuffer: CVPixelBuffer?

    private var textures: TextureInfo?

    private var width: Int = 0
    private var height: Int = 0

    public var textureId: Int64 = -1;
    private var eglInfo: EGLInfo?

    var textureMetalCache: CVMetalTextureCache?
    var metalImageBuf: CVMetalTexture?
    
    init(textureRegistry: FlutterTextureRegistry?){
        self.textureRegistry = textureRegistry;
        super.init();
        self.textureId = textureRegistry?.register(self) ?? -1
    }

    // MARK: - Init OpenGL
    static func initOpenGL(result: @escaping FlutterResult) -> EGLInfo?{
        // Get EGL display
        guard let display = eglGetDisplay(0) else { //EGL_DEFAULT_DISPLAY
            result(FlutterError(code: "Flutter Angle Error", message: "Failed to get EGL display", details: nil))
            return nil
        }
    
        print("Got EGL display: \(Int(bitPattern: display))")
        
        // Initialize EGL
        var major: Int32 = 0
        var minor: Int32 = 0
    
        if eglInitialize(display, &major, &minor) == 0 {
            result(FlutterError(code: "Flutter Angle Error", message: "Failed to initialize EGL", details: nil))
            return nil
        }

        print("EGL Initialized with version \(major).\(minor)")
        
        // EGL configuration attributes
        let configAttribs: [Int32] = [
            EGL_RED_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_BLUE_SIZE, 8,
            EGL_ALPHA_SIZE, 8,
            EGL_DEPTH_SIZE, 24,
            EGL_STENCIL_SIZE, 8,
            EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
            EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
            EGL_NONE
        ]
        
        // Choose EGL config
        var configs = UnsafeMutableRawPointer(bitPattern: 0)
        var numConfigs: Int32 = 0
        
        if eglChooseConfig(display, configAttribs, &configs, 1, &numConfigs) == 0 {
            result(FlutterError(code: "Flutter Angle Error", message: "Failed to choose EGL config", details: nil))
            return nil
        }
        
        guard configs != nil else {
            result(FlutterError(code: "Flutter Angle Error", message: "No valid EGL configs found", details: nil))
            return nil
        }
        
        print("Got EGL config: \(Int(bitPattern: configs))")
        
        // Get the config ID for sharing with Dart side
        var configId: Int32 = 0
        
        if eglGetConfigAttrib(display, configs, EGL_CONFIG_ID, &configId) == 0 {
            result(FlutterError(code: "Flutter Angle Error", message: "Failed to get EGL config ID", details: nil))
            return nil
        }

        let surfaceAttribs: [Int32] = [
            EGL_WIDTH, 16,
            EGL_HEIGHT, 16,
            EGL_NONE
        ];
        let buffer_attributes:[Int32] = [
            EGL_WIDTH, 16,
            EGL_HEIGHT, 16,
            EGL_TEXTURE_TARGET, EGL_TEXTURE_2D, 
            EGL_TEXTURE_FORMAT, EGL_TEXTURE_RGBA,
            EGL_NONE,
        ];
        let contextAttributes: [Int32] = [
          EGL_CONTEXT_CLIENT_VERSION,
          3,
          EGL_NONE
        ]

        guard let context = eglCreateContext(display, configs, nil, contextAttributes) else {
            result(FlutterError(code: "Flutter Angle Error", message: "Failed to create EGL context", details: nil))
            return nil
        }
        
        let dummySurface = eglCreatePbufferSurface(display, configs, surfaceAttribs)
        let dummySurfaceForDartSide = eglCreatePbufferSurface(display, configs, surfaceAttribs)
       
        if eglMakeCurrent(display, dummySurface, dummySurface, context) == 0 {
           result(FlutterError(code: "Flutter Angle Error", message: "Failed to make context current", details: nil))
           return nil
       }
        
        // Print OpenGL information
        if let version = glGetString(GLenum(GL_VERSION)),
           let vendor = glGetString(GLenum(GL_VENDOR)),
           let renderer = glGetString(GLenum(GL_RENDERER)) {
          print("OpenGL initialized: Vendor: \(vendor), Renderer: \(renderer), Version: \(version)")
        }
        
        // Ensure the context value is explicitly included
        let results: [String: Any] = [
          "isSimulator": true,
          "context": Int(bitPattern: context),
          "eglConfigId": Int(configId),
          "dummySurface": Int(bitPattern: dummySurfaceForDartSide),
          "openGLVersion": "OpenGL ES 3.0 ANGLE",
        ]
        
        print("InitOpenGL returning: \(results)")
        
        result(results)
        return EGLInfo(
            eglDisplay: display,
            eglContext: context,
            eglSurface: dummySurface!
        )
    }
    
    public func setInfo(info: EGLInfo?) {
        eglInfo = info
    }
        
    // MARK: - Texture Creation
    public func createTexture(width: Int, height: Int, result: @escaping FlutterResult) {
        self.width = width
        self.height = height

        // Create IOSurface
        print("Creating texture with physical dimensions: \(width) x \(height)")
        
        let options: [String: Any] = [
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                        width,
                                        height,
                                        kCVPixelFormatType_32BGRA,
                                        options as CFDictionary,
                                        &pixelBuffer)
        
        guard status == kCVReturnSuccess else {
            result(["error": "Failed to create pixel buffer: \(status)"]);
            return
        }
        
        textures = TextureInfo()
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        createMtlTextureFromCVPixBuffer(width: width, height: height)
        setupOpenGLResources(useRenderBuf: textures!.metalTextureId == 0)
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        result([
          "textureId": textureId,
          "rbo": Int(textures!.rboId),
          "metalAsGLTexture": Int(textures!.metalTextureId),
          "location": 0  // For compatibility with Android
        ]);
    }
    private func getANGLEMtlDevice(display: EGLDisplay) -> MTLDevice?{
       var angleDevice: EGLAttrib = 0;
       var device: EGLAttrib      = 0;
       
       if (eglQueryDisplayAttribEXT(eglInfo!.eglDisplay, EGL_DEVICE_EXT, &angleDevice) != EGL_TRUE){
           print(angleDevice);
           return nil;
       }
       
       if (eglQueryDeviceAttribEXT((EGLDeviceEXT)(bitPattern: angleDevice)!, EGL_METAL_DEVICE_ANGLE, &device) != EGL_TRUE){
           return nil;
       }

       return unsafeBitCast(device, to: MTLDevice.self);//(__bridge id<MTLDevice>)(void *)(device);
    }
    private func createMtlTextureFromCVPixBuffer(width: Int, height: Int) {
        // Create Metal texture backed by CVPixelBuffer
       guard let mtlDevice:MTLDevice =  getANGLEMtlDevice(display: eglInfo!.eglDisplay)else {
            fatalError("Could not create Metal Device")
        }//GetANGLEMtlDevice(display: eglInfo!.eglDisplay) MTLCreateSystemDefaultDevice() 

        guard CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            mtlDevice,
            nil,
            &textureMetalCache
        ) == kCVReturnSuccess else {
            print("No IOSurface available for this texture ID")
            return
        }
        guard CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureMetalCache!,
            pixelBuffer!,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &metalImageBuf
        ) == kCVReturnSuccess else {
            fatalError("CVMetalTextureCacheCreateTextureFromImage bind CVPixelBuffer to metal texture error")
       }
       
       let metalTexture = CVMetalTextureGetTexture(metalImageBuf!)

       // Call the function
       let eglImage = eglCreateImageKHR(eglInfo!.eglDisplay, nil, EGLenum(EGL_METAL_TEXTURE_ANGLE), unsafeBitCast(metalTexture!, to: EGLClientBuffer.self), [EGL_NONE])
       
       glGenTextures(1, &textures!.metalTextureId)
       glBindTexture(GLenum(GL_TEXTURE_2D), textures!.metalTextureId)
       
       let swapBuffersPtr = eglGetProcAddress("glEGLImageTargetTexture2DOES")
       let swapBuffers = unsafeBitCast(swapBuffersPtr, to: PFNGLEGLIMAGETARGETTEXTURE2DOESPROC.self)
       
       swapBuffers(GLenum(GL_TEXTURE_2D), eglImage)
       print(eglImage)
    }
    
    private func setupOpenGLResources(useRenderBuf: Bool) {
      guard let textureInfo = textures else {
        print("Failed to setup OpenGL resources - missing texture or GLES library")
        return
      }
      
      // Make EGL context current
        if eglInfo?.eglContext != nil && eglInfo?.eglDisplay != nil && eglInfo?.eglSurface != nil {
            eglMakeCurrent(eglInfo!.eglDisplay, eglInfo!.eglSurface, eglInfo!.eglSurface, eglInfo!.eglContext)
      }

      // Create framebuffer
      var fbo: UInt32 = 0
        glGenFramebuffers(1, &fbo)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), fbo)
        
      var rbo: UInt32 = 0
      if(useRenderBuf){
            glGenRenderbuffers(1, &rbo)
            glBindRenderbuffer(GLenum(GL_RENDERBUFFER), rbo)

            glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_RGBA8), Int32(width), Int32(height))
            glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), rbo)
      }
      // Check framebuffer status
      let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
      if status != GLenum(GL_FRAMEBUFFER_COMPLETE) {
        print("Framebuffer incomplete: \(status)")
      } else {
        print("Framebuffer complete")
      }
      
      // Check for GL errors
      let error = glGetError()
      if error != 0 {
        print("GL error during framebuffer setup: \(error)")
      }
      
      // Update the texture info with the OpenGL IDs
      var updatedInfo = textureInfo
      updatedInfo.fboId = fbo
      updatedInfo.rboId = rbo
      textures = updatedInfo
    }
    
    public func textureFrameAvailable(result: @escaping FlutterResult) {
        if (textures?.metalTextureId == 0) {
            CVPixelBufferLockBaseAddress(pixelBuffer!, .readOnly)
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), textures!.fboId)
            let pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer!)
            glReadPixels(0, 0, GLsizei(width), GLsizei(height), GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), pixelBufferBaseAddress)
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, .readOnly)
        }
        
        textureRegistry?.textureFrameAvailable(textureId)
        result(nil)
    }
  
    public func disposeTexture() {
        if let tr = textureRegistry {
            tr.unregisterTexture(textureId)
        }

        // Make EGL context current
        if eglInfo?.eglContext != nil && eglInfo?.eglDisplay != nil && eglInfo?.eglSurface != nil {
            eglMakeCurrent(eglInfo!.eglDisplay, eglInfo!.eglSurface, eglInfo!.eglSurface, eglInfo!.eglContext)
        }
        
        // Delete framebuffer and renderbuffer
        var fbo = textures!.fboId
        var rbo = textures!.rboId
        
        if fbo != 0 {
            glDeleteFramebuffers(1, &fbo)
        }
        
        if rbo != 0 {
            glDeleteRenderbuffers(1, &rbo)
        }
        
        // Clean up our maps
        textures = nil
        pixelBuffer = nil

        // Clean up EGL
        let eglDisplay = eglInfo!.eglDisplay
        let eglContext = eglInfo!.eglContext
        let eglSurface = eglInfo!.eglSurface
            
            let EGL_NO_SURFACE = UnsafeMutableRawPointer(bitPattern: 0)
            let EGL_NO_CONTEXT = UnsafeMutableRawPointer(bitPattern: 0)
            
            // Release EGL resources
            let makeCurrent = eglMakeCurrent(eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)
            if makeCurrent == 0 {
                print("Failed to make EGL_NO_CONTEXT current during cleanup")
            }
            
            let destroySurface = eglDestroySurface(eglDisplay, eglSurface)
            if destroySurface == 0 {
                print("Failed to destroy EGL surface during cleanup")
            }
            
            let destroyContext = eglDestroyContext(eglDisplay, eglContext)
            if destroyContext == 0 {
                print("Failed to destroy EGL context during cleanup")
            }
            
            let terminate = eglTerminate(eglDisplay)
            if terminate == 0 {
                print("Failed to terminate EGL during cleanup")
            }
        
    }
}

extension FlutterAngleSimPlugin: FlutterTexture {
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard pixelBuffer != nil else {
            print("No textureToPixelBuffer")
            return nil
        }
        if let pixBuffer = pixelBuffer {
            return Unmanaged.passRetained(pixBuffer)
        }
        return nil
    }
}
#endif
