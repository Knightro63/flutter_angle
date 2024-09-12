#import "FlutterAngle.h"
#import "libEGL/EGL/egl.h"
#import "libEGL/EGL/eglext.h"
#import "libEGL/EGL/eglext_angle.h"
#include "libGLESv2/angle_gl.h"

// Get metal device used by MetalANGLE.
// This can return nil if the MetalANGLE is not currently using Metal back-end. For example, the
// target device is running iOS version < 11.0 or macOS version < 13.0
static id<MTLDevice> GetANGLEMtlDevice(EGLDisplay display){
    EGLAttrib angleDevice = 0;
    EGLAttrib device      = 0;
    if (eglQueryDisplayAttribEXT(display, EGL_DEVICE_EXT, &angleDevice) != EGL_TRUE)
        return nil;

    if (eglQueryDeviceAttribEXT((EGLDeviceEXT)(angleDevice), EGL_MTL_DEVICE_ANGLE, &device) != EGL_TRUE)
        return nil;

    return (__bridge id<MTLDevice>)(void *)(device);
}

@implementation OpenGLException

- (instancetype) initWithMessage: (NSString*) message andError: (int) error{
    self = [super init];
    if (self){
        _message = message;
        _errorCode = error;
    }
    return self;
}

@end

@interface FlutterGlTexture() {
    CVMetalTextureCacheRef _metalTextureCache;
    CVMetalTextureRef _metalTextureCVRef;
    id<MTLTexture> _metalTexture;
    EGLImageKHR _metalAsEGLImage;
}
@end

@implementation FlutterGlTexture
- (instancetype)initWithWidth:(int) width andHeight:(int)height registerWidth:(NSObject<FlutterTextureRegistry>*) registry{
    self = [super init];
    if (self){
        _width = width;
        _height = height;
        NSDictionary* options = @{
          (NSString*)kCVPixelBufferMetalCompatibilityKey : @YES
        };

        CVReturn status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            (__bridge CFDictionaryRef)options,
            &_pixelData
        );

        if (status != 0){
            NSLog(@"CVPixelBufferCreate error %d", (int)status);
        }
        
        CVPixelBufferLockBaseAddress(_pixelData, 0);
        [self createMtlTextureFromCVPixBufferWithWidth:width andHeight:height];

        _flutterTextureId = [registry registerTexture:self];
    }
    
    return self;
}

- (void)dealloc {
    // TODO: deallocate GL resources
    _metalTexture = nil;
    if (_metalTextureCVRef) {
        CFRelease(_metalTextureCVRef);
        _metalTextureCVRef = nil;
    }
    if (_metalTextureCache) {
        CFRelease(_metalTextureCache);
        _metalTextureCache = nil;
    }
    CVPixelBufferRelease(_pixelData);
}

- (void)createMtlTextureFromCVPixBufferWithWidth:(int) width andHeight:(int)height {
    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    // Create Metal texture backed by CVPixelBuffer
    id<MTLDevice> mtlDevice = GetANGLEMtlDevice(display);
    // if mtlDevice is nil, fall-back to CPU readback via glReadPixels
    if (!mtlDevice)
        return;

    CVReturn status = CVMetalTextureCacheCreate(
        kCFAllocatorDefault,
        nil,
        mtlDevice,
        nil,
        &_metalTextureCache
    );
    if (status != 0){
        NSLog(@"CVMetalTextureCacheCreate error %d", (int)status);
    }

    status = CVMetalTextureCacheCreateTextureFromImage(
        kCFAllocatorDefault,
        _metalTextureCache,
        _pixelData,
        nil,
        MTLPixelFormatBGRA8Unorm,
        width,
        height,
        0,
        &_metalTextureCVRef
    );
    if (status != 0){
        NSLog(@"CVMetalTextureCacheCreateTextureFromImage error %d", (int)status);
    }
    _metalTexture = CVMetalTextureGetTexture(_metalTextureCVRef);

    // Create EGL image backed by Metal texture
    EGLint attribs[] = {
        EGL_NONE,
    };
    _metalAsEGLImage = eglCreateImageKHR(
        display,
        EGL_NO_CONTEXT,
        EGL_MTL_TEXTURE_MGL,
        (__bridge EGLClientBuffer)(_metalTexture),
        attribs
    );

    // Create a texture target to bind the egl image
    glGenTextures(1, &_metalAsGLTexture);
    glBindTexture(GL_TEXTURE_2D, _metalAsGLTexture);
    
    PFNGLEGLIMAGETARGETTEXTURE2DOESPROC glEGLImageTargetTexture2DOES = (PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)eglGetProcAddress("glEGLImageTargetTexture2DOES");
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, _metalAsEGLImage);
}

#pragma mark - FlutterTexture

- (CVPixelBufferRef)copyPixelBuffer {
    CVBufferRetain(_pixelData);
    return _pixelData;
}

@end
