#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

import OpenGL
import OpenGL.GL
import libEGL
import libGLESv2

public class OpenGLRender2: NSObject, FlutterTexture {
    var targetPixelBuffer: CVPixelBuffer?;
    var textureCache: CVOpenGLTextureCache?;
    var textureRef: CVOpenGLTexture?;
    var openGLAsTexture:GLuint = 0;
    
    var frameBuffer: GLuint = 0;
    
    var width: Int;
    var height: Int;
    var eglEnv:OGLEglEnv;
    var dartEglEnv:OGLEglEnv;
    
    var sharedContext:EGLContext;
    var eglDisplay:EGLDisplay;
    
    init(
        _ width:Int,
        _ height:Int,
        _ sharedContext:EGLContext
    ) {
        self.sharedContext = sharedContext;
        self.width = width;
        self.height = height;
        
        dartEglEnv = OGLEglEnv();
        dartEglEnv.setupRender(shareContext: sharedContext);

        eglEnv = OGLEglEnv();
        eglEnv.setupRender(shareContext: sharedContext);
        eglEnv.makeCurrent();
        
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
    
    func initGL(_ context: EGLContext) {
        eglDisplay = eglGetDisplay(EGL_ANGLE_device_metal);
        self.createOpenGLFromCVBufferWithSize(self.width, self.height,context: context);
        openGLAsTexture = CVOpenGLTextureGetName(self.textureRef!);
    }
    
    func getEgl() -> Array<Int64> {
        var _egls = [Int64](repeating: 0, count: 6);
        _egls[2] = eglEnv.getContext();
        _egls[5] = dartEglEnv.getContext();
        return _egls;
    }
    
    public func createOpenGLFromCVBufferWithSize(_ width:Int, _ height:Int, context:EGLContext) {
        let err:CVReturn = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, nil, context.cglContextObj!, context.pixelFormat.cglPixelFormatObj!, nil, &textureCache);
        
        let attrs = [
            kCVPixelBufferOpenGLCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary
        
        var cvret = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &targetPixelBuffer);
        assert(cvret == kCVReturnSuccess, "CVPixelBuffer")
        
        cvret = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, targetPixelBuffer!,nil, &textureRef);
        
        assert(cvret == kCVReturnSuccess, "CVOpenGLTextureCacheCreateTextureFromImage")
    }
    
    func dispose(){
        // TODO: deallocate GL resources
        glDeleteFramebuffers(1, &frameBuffer);
        if (openGLAsTexture != 0) {
            glDeleteTextures(1, &openGLAsTexture);
        }
    }
}
