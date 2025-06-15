#if targetEnvironment(simulator)
#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif

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
    var textureOpenGLCache: CVOpenGLESTextureCache?
    var metalImageBuf: CVMetalTexture?
    var openglImageBuf: CVOpenGLESTexture?
    
    init(textureRegistry: FlutterTextureRegistry?){
        self.textureRegistry = textureRegistry;
        super.init();
        self.textureId = textureRegistry?.register(self) ?? -1
    }

    // MARK: - Init OpenGL
    static func initOpenGL(result: @escaping FlutterResult) -> EGLInfo?{
        // Get EGL display
        guard let display = libEGL.eglGetDisplay(0) else { //EGL_DEFAULT_DISPLAY
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
        if let version = libGLESv2.glGetString(GLenum(libGLESv2.GL_VERSION)),
           let vendor = libGLESv2.glGetString(GLenum(libGLESv2.GL_VENDOR)),
           let renderer = libGLESv2.glGetString(GLenum(libGLESv2.GL_RENDERER)) {
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
            eglSurface: dummySurface!,
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
            kCVPixelBufferOpenGLESCompatibilityKey as String: true,
            kCVPixelBufferOpenGLCompatibilityKey as String: true,
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

    private func createMtlTextureFromCVPixBuffer(width: Int, height: Int) {
         // Create Metal texture backed by CVPixelBuffer
         guard let mtlDevice:MTLDevice = MTLCreateSystemDefaultDevice() else {
             fatalError("Could not create Metal Device")
         }

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
             &metalImageBuf) == kCVReturnSuccess else {
             fatalError("CVMetalTextureCacheCreateTextureFromImage bind CVPixelBuffer to metal texture error")
        }
        
        let metalTexture = CVMetalTextureGetTexture(metalImageBuf!)
        
//        guard CVOpenGLESTextureCacheCreate(
//            kCFAllocatorDefault,
//            nil,
//            eglInfo!.eglContext,
//            nil,
//            &textureOpenGLCache
//        ) == kCVReturnSuccess else {
//            print("CVOpenGLESTextureCacheCreate failed")
//            return
//        }
//        
//        guard CVOpenGLESTextureCacheCreateTextureFromImage(
//            kCFAllocatorDefault,
//            textureOpenGLCache!,
//            pixelBuffer!,
//            nil,
//            GLenum(GL_TEXTURE_2D),
//            GLint(GL_RGBA),
//            GLsizei(width),
//            GLsizei(height),
//            GLenum(GL_BGRA),
//            GLenum(GL_UNSIGNED_BYTE),
//            0,
//            &openglImageBuf
//        ) == kCVReturnSuccess else {
//            print("CVOpenGLESTextureCacheCreateTextureFromImage failed")
//            return
//        }
        
        libGLESv2.glGenTextures(1, &textures!.metalTextureId)
        libGLESv2.glBindTexture(GLenum(libGLESv2.GL_TEXTURE_2D), textures!.metalTextureId)
        
        let glEGLImageTargetTexture2DOES:(Double, Double)! = eglGetProcAddress("glEGLImageTargetTexture2DOES"); //(PFNGLEGLIMAGETARGETTEXTURE2DOESPROC) PFNGLEGLIMAGETARGETTEXTURE2DOESPROC
        glEGLImageTargetTexture2DOES(GLenum(libGLESv2.GL_TEXTURE_2D), metalTexture)
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
        libGLESv2.glGenFramebuffers(1, &fbo)
        libGLESv2.glBindFramebuffer(GLenum(libGLESv2.GL_FRAMEBUFFER), fbo)
        
      var rbo: UInt32 = 0
      if(useRenderBuf){
            libGLESv2.glGenRenderbuffers(1, &rbo)
            libGLESv2.glBindRenderbuffer(GLenum(libGLESv2.GL_RENDERBUFFER), rbo)

            libGLESv2.glRenderbufferStorage(GLenum(libGLESv2.GL_RENDERBUFFER), GLenum(libGLESv2.GL_RGBA8), Int32(width), Int32(height))
            libGLESv2.glFramebufferRenderbuffer(GLenum(libGLESv2.GL_FRAMEBUFFER), GLenum(libGLESv2.GL_COLOR_ATTACHMENT0), GLenum(libGLESv2.GL_RENDERBUFFER), rbo)
      }
      // Check framebuffer status
      let status = libGLESv2.glCheckFramebufferStatus(GLenum(libGLESv2.GL_FRAMEBUFFER))
      if status != GLenum(libGLESv2.GL_FRAMEBUFFER_COMPLETE) {
        print("Framebuffer incomplete: \(status)")
      } else {
        print("Framebuffer complete")
      }
      
      // Check for GL errors
      let error = libGLESv2.glGetError()
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
            libGLESv2.glBindFramebuffer(GLenum(libGLESv2.GL_FRAMEBUFFER), textures!.fboId)
            let pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer!)
            libGLESv2.glReadPixels(0, 0, GLsizei(width), GLsizei(height), GLenum(GL_BGRA), GLenum(libGLESv2.GL_UNSIGNED_BYTE), pixelBufferBaseAddress)
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, .readOnly)
        }
        textureRegistry?.textureFrameAvailable(textureId)
        result(nil)
    }
    public func textureFrameAvailable2(result: @escaping FlutterResult) {
        guard textures != nil else {
            result(FlutterError(code: "INVALID_TEXTURE_ID", message: "Unknown texture ID", details: nil))
            return
        }
        guard let textureInfo = textures else {
            result(FlutterError(code: "INVALID_TEXTURE_ID", message: "Failed to update texture - missing texture or GLES library", details: nil))
            return
        }
        
        // Make EGL context current
        if eglInfo?.eglContext != nil && eglInfo?.eglDisplay != nil && eglInfo?.eglSurface != nil {
            eglMakeCurrent(eglInfo!.eglDisplay, eglInfo!.eglSurface, eglInfo!.eglSurface, eglInfo!.eglContext)
        }
        
        // OpenGL constants
        let GL_BGRA: UInt32 = 0x80E1 // Use GL_BGRA instead of GL_RGBA to match CVPixelBuffer format
        let GL_UNSIGNED_BYTE: UInt32 = 0x1401
        let GL_READ_FRAMEBUFFER: UInt32 = 0x8CA8
        
        // Ensure we're reading from the correct framebuffer
          libGLESv2.glBindFramebuffer(GL_READ_FRAMEBUFFER, textureInfo.fboId)
        
        // Make sure all previous GL commands are completed
          libGLESv2.glFinish()
        
        // Copy the framebuffer content to the CVPixelBuffer
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let width = width
        let height = height
        let pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        // Actually read the pixels from framebuffer to memory
        // Use GL_BGRA instead of GL_RGBA to match macOS CVPixelBuffer format (kCVPixelFormatType_32BGRA)
        libGLESv2.glReadPixels(0, 0, Int32(width), Int32(height), GL_BGRA, GL_UNSIGNED_BYTE, pixelBufferBaseAddress)
        
        // Check for GL errors
        let error = libGLESv2.glGetError()
        if error != 0 {
          print("GL error during readPixels: \(error)")
        }
        
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        // Ensure all commands are submitted
        libGLESv2.glFlush()
        
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
            libGLESv2.glDeleteFramebuffers(1, &fbo)
        }
        
        if rbo != 0 {
            libGLESv2.glDeleteRenderbuffers(1, &rbo)
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
