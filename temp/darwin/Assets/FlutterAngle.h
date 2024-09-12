#if TARGET_OS_IOS
    #import <Flutter/Flutter.h>
#elif TARGET_OS_MAC
    #import <FlutterMacOS/FlutterMacOS.h>
#endif
#define GL_SILENCE_DEPRECATION
#define EGL_MTL_DEVICE_ANGLE 0x33A2
#define EGL_MTL_TEXTURE_MGL 0x3456

#import "FlutterAngle.h"
#import "libEGL/EGL/egl.h"
#import "libEGL/EGL/eglext.h"
#import "libEGL/EGL/eglext_angle.h"
#include "libGLESv2/angle_gl.h"

EGLAPI EGLBoolean EGLAPIENTRY eglQueryDisplayAttribEXT (EGLDisplay dpy, EGLint attribute, EGLAttrib *value);
EGLAPI EGLBoolean EGLAPIENTRY eglQueryDeviceAttribEXT (EGLDeviceEXT device, EGLint attribute, EGLAttrib *value);
EGLAPI EGLImageKHR EGLAPIENTRY eglCreateImageKHR (EGLDisplay dpy, EGLContext ctx, EGLenum target, EGLClientBuffer buffer, const EGLint *attrib_list);
EGLAPI EGLBoolean EGLAPIENTRY eglDestroyImageKHR (EGLDisplay dpy, EGLImageKHR image);

@interface OpenGLException: NSException
- (instancetype) initWithMessage: (NSString*) message andError: (int) error;
@property (nonatomic,assign) GLint errorCode;
@property (nonatomic,assign) NSString* message;
@end
        
@interface FlutterGlTexture : NSObject<FlutterTexture>
- (instancetype)initWithWidth:(int) width andHeight:(int)height registerWidth:(NSObject<FlutterTextureRegistry>*) registry;
@property (nonatomic,assign) int width;
@property (nonatomic,assign) int height;
@property (nonatomic,assign) int64_t flutterTextureId;
@property (nonatomic) CVPixelBufferRef  pixelData;
// Metal -> GL interop texture
@property (nonatomic, readonly) GLuint metalAsGLTexture;


@end
