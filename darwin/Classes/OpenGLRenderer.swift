#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

import OpenGL
import OpenGL.GL

public class OpenGLRender: NSObject, FlutterTexture {
    var targetPixelBuffer: CVPixelBuffer?;
    var textureCache: CVOpenGLTextureCache?;
    var textureRef: CVOpenGLTexture?;
    var openGLAsTexture:GLuint = 0;
    
    var frameBuffer: GLuint = 0;
    
    var width: Int;
    var height: Int;
    
    var sharedContext:OGLEglEnv;
    
    init(
        _ width:Int,
        _ height:Int,
        _ sharedContext:OGLEglEnv
    ) {
        self.sharedContext = sharedContext;
        self.width = width;
        self.height = height;
        
        sharedContext.makeCurrent(1);
        
        super.init();     
        initGL(sharedContext);
    }
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        var pixelBuffer: CVPixelBuffer? = nil;
        pixelBuffer = targetPixelBuffer;
        if(pixelBuffer != nil) {
            let result = Unmanaged.passRetained(pixelBuffer!);
            return result;
        } else {
            print("pixelBuffer is nil.... ");
            return nil;
        }
    }
    
    func initGL(_ context: OGLEglEnv) {
        glGenFramebuffers(1, &frameBuffer);
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer);
        
        self.createOpenGLFromCVBufferWithSize(self.width, self.height,context: context.context!);
        openGLAsTexture = CVOpenGLTextureGetName(self.textureRef!);
        
        glBindTexture(GLenum(GL_TEXTURE_2D), openGLAsTexture);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
    }
    
    func getEgl() -> Array<Int64> {
        var _egls = [Int64](repeating: 0, count: 6);
        _egls[2] = sharedContext.getContext(1);
        _egls[5] = sharedContext.getContext(2);
        return _egls;
    }
    
    public func createOpenGLFromCVBufferWithSize(_ width:Int, _ height:Int, context:NSOpenGLContext) {
        let err:CVReturn = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, nil, context.cglContextObj!, context.pixelFormat.cglPixelFormatObj!, nil, &textureCache);
        
        let attrs = [
            kCVPixelBufferOpenGLCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary
        
        var cvret = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &targetPixelBuffer);
        assert(cvret == kCVReturnSuccess, "CVPixelBuffer")
        
        cvret = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, targetPixelBuffer!,nil, &textureRef);
        
        assert(cvret == kCVReturnSuccess, "CVOpenGLTextureCacheCreateTextureFromImage 失败")
    }
    
    func dispose(){
        // TODO: deallocate GL resources
        glDeleteFramebuffers(1, &frameBuffer);
        if (openGLAsTexture != 0) {
            glDeleteTextures(1, &openGLAsTexture);
        }
    }
}


public class OGLEglEnv : NSObject {
  var context:NSOpenGLContext?;
  var dummySurface:NSOpenGLContext?;
  var dummySurfaceForDartSide:NSOpenGLContext?;
  
    func getEgl() -> Array<Int64> {
        var _egls = [Int64](repeating: 0, count: 6);
        _egls[2] = getContext(1);
        _egls[5] = getContext(2);
        return _egls;
    }

  func setupRender(){
    setupOGLEglEnv();
    self.dummySurface = setupDummy(shareContext: context);
    self.dummySurfaceForDartSide = setupDummy(shareContext: context);
  }

  func setupDummy(shareContext: NSOpenGLContext?) -> NSOpenGLContext?{
      let attr = [
          NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 24,
          NSOpenGLPixelFormatAttribute(NSOpenGLPFAAlphaSize), 8,
          NSOpenGLPixelFormatAttribute(NSOpenGLPFADepthSize), 24,
          NSOpenGLPixelFormatAttribute(NSOpenGLPFAStencilSize), 8,
          NSOpenGLPixelFormatAttribute(NSOpenGLPFAAllowOfflineRenderers),
          NSOpenGLPixelFormatAttribute(NSOpenGLPFAAccelerated),
          NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
          NSOpenGLPixelFormatAttribute(NSOpenGLPFAMultisample),
          NSOpenGLPixelFormatAttribute(NSOpenGLPFASampleBuffers), 1,
          NSOpenGLPixelFormatAttribute(NSOpenGLPFASamples), 4,
          NSOpenGLPixelFormatAttribute(NSOpenGLPFAMinimumPolicy),
          NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
          NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion4_1Core),
          0
      ]

      let format = NSOpenGLPixelFormat(attributes: attr)
      return NSOpenGLContext(format: format!, share: shareContext)
  }

    func setupOGLEglEnv(){
        if(self.context == nil) {
            let attr = [
                NSOpenGLPixelFormatAttribute(NSOpenGLPFAAllowOfflineRenderers),
                NSOpenGLPixelFormatAttribute(NSOpenGLPFAAccelerated),
                NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
                NSOpenGLPixelFormatAttribute(NSOpenGLPFAMultisample),
                NSOpenGLPixelFormatAttribute(NSOpenGLPFASampleBuffers), 1,
                NSOpenGLPixelFormatAttribute(NSOpenGLPFASamples), 4,
                NSOpenGLPixelFormatAttribute(NSOpenGLPFAMinimumPolicy),
                NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
                NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion4_1Core),
                0
            ]
            
            let format = NSOpenGLPixelFormat(attributes: attr)
            self.context = NSOpenGLContext(format: format!, share: nil)
        }
    }

  func makeCurrent(_ dummy:Int) {
    if dummy == 1{
        self.dummySurface!.makeCurrentContext();
        self.dummySurface!.update();
    }
    else if dummy == 2{
        self.dummySurfaceForDartSide!.makeCurrentContext();
        self.dummySurfaceForDartSide!.update();
    }
    else{
        self.context!.makeCurrentContext();
        self.context!.update();
    }
  }
  
  func getContext(_ dummy:Int) -> Int64 {
    if dummy == 1{
        return Int64(self.dummySurface!.hashValue);
    }
    else if dummy == 2{
        return Int64(self.dummySurfaceForDartSide!.hashValue);
    }

    // todo two different context object hashValue is always different???
    return Int64(self.context!.hashValue);
  }

  func dispose() {
    self.context = nil;
    self.dummySurface = nil;
    self.dummySurfaceForDartSide = nil;
  }
}
