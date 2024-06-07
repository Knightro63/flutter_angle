#import "FlutterAnglePlugin.h"
#import "MetalANGLE/EGL/egl.h"
#define GL_SILENCE_DEPRECATION
#define EGL_EGLEXT_PROTOTYPES
#import "MetalANGLE/EGL/eglext.h"
#import "MetalANGLE/EGL/eglext_angle.h"
#import "MetalANGLE/angle_gl.h"

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
        _pixelData, nil,
        MTLPixelFormatBGRA8Unorm,
        width, height,
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
//
    PFNGLEGLIMAGETARGETTEXTURE2DOESPROC glEGLImageTargetTexture2DOES = (PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)eglGetProcAddress("glEGLImageTargetTexture2DOES");
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, _metalAsEGLImage);
}

#pragma mark - FlutterTexture

- (CVPixelBufferRef)copyPixelBuffer {
    CVBufferRetain(_pixelData);
    return _pixelData;
}

@end


@interface FlutterAnglePlugin()
@property (nonatomic, strong) NSObject<FlutterTextureRegistry> *textureRegistry;
@property (nonatomic,strong) FlutterGlTexture* flutterGLTexture;

@end

@implementation FlutterAnglePlugin

- (instancetype)initWithTextures:(NSObject<FlutterTextureRegistry> *)textures {
    self = [super init];
    if (self) {
        _textureRegistry = textures;
    }
    return self;
}


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"flutter_angle" binaryMessenger:[registrar messenger]];
    FlutterAnglePlugin* instance = [[FlutterAnglePlugin alloc] initWithTextures:[registrar textures]];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"initOpenGL"]) {
        static EGLContext  context;
        if (context != NULL)
        {
          result([NSNumber numberWithLong: (long)context]);
          return;
        }

        EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        EGLint major;
        EGLint minor;
        int initializeResult = eglInitialize(display,&major,&minor);
        if (initializeResult != 1){
            result([FlutterError errorWithCode: @"No OpenGL context" message: @"eglInit failed"  details:NULL]);
            return;
        }
        
        const EGLint attribute_list[] = {
          EGL_RED_SIZE, 8,
          EGL_GREEN_SIZE, 8,
          EGL_BLUE_SIZE, 8,
          EGL_ALPHA_SIZE, 8,
          EGL_DEPTH_SIZE, 16,
          EGL_NONE
        };

        EGLint num_config;
        EGLConfig config;
        EGLBoolean chooseConfigResult = eglChooseConfig(display,attribute_list,&config,1,&num_config);
        if (chooseConfigResult != 1){
            result([FlutterError errorWithCode: @"EGL InitError" message: @"Failed to call eglCreateWindowSurface()"  details:NULL]);
            return;
        }

        // This is just a dummy surface that it needed to make an OpenGL context current (bind it to this thread)
        CALayer* dummyLayer       = [[CALayer alloc] init];
        dummyLayer.frame = CGRectMake(0, 0, 1, 1);
        CALayer* dummyLayer2       = [[CALayer alloc] init];
        dummyLayer2.frame = CGRectMake(0, 0, 1, 1);

        EGLSurface dummySurfaceForDartSide = eglCreateWindowSurface(display, config,(__bridge EGLNativeWindowType)dummyLayer, NULL);
        EGLSurface dummySurface = eglCreateWindowSurface(display, config,(__bridge EGLNativeWindowType)dummyLayer2, NULL);
        
        if ((dummySurfaceForDartSide == EGL_NO_SURFACE) || (dummySurface == EGL_NO_SURFACE)){
            result([FlutterError errorWithCode: @"EGL InitError" message: @"Dummy Surface creation failed"  details:NULL]);
            return;
        }
        if (eglMakeCurrent(display, dummySurface, dummySurface, context)!=1){
            NSLog(@"MakeCurrent failed: %d",eglGetError());
        }
        
        result(@{
            @"context" : [NSNumber numberWithLong: (long)context],
            @"dummySurface" : [NSNumber numberWithLong: (long)dummySurfaceForDartSide]
        });
        return;
    }
    if ([call.method isEqualToString:@"createTexture"]) {
        NSNumber* width;
        NSNumber* height;
        if (call.arguments) {
            width = call.arguments[@"width"];
            if (width == NULL){
                result([FlutterError errorWithCode: @"CreateTexture Error" message: @"No width received by the native part of FlutterGL.createTexture"  details:NULL]);
                return;
            }
            height = call.arguments[@"height"];
            if (height == NULL){
                result([FlutterError errorWithCode: @"CreateTexture Error" message: @"No height received by the native part of FlutterGL.createTexture"  details:NULL]);
                return;
            }
        }
        else{
          result([FlutterError errorWithCode: @"No arguments" message: @"No arguments received by the native part of FlutterGL.createTexture"  details:NULL]);
          return;
        }

        @try{
            _flutterGLTexture = [[FlutterGlTexture alloc] initWithWidth:width.intValue andHeight:height.intValue registerWidth:_textureRegistry];
        }
        @catch (OpenGLException* ex){
            result([FlutterError errorWithCode: [@( [ex errorCode]) stringValue] message: [@"Error creating FlutterGLTextureObjec: " stringByAppendingString:[ex message]] details:NULL]);
            return;
        }

        //flutterGLTextures.insert(TextureMap::value_type(flutterGLTexture->flutterTextureId, std::move(flutterGLTexture)));
        result(@{
           @"textureId" : [NSNumber numberWithLongLong: [_flutterGLTexture flutterTextureId]],
           @"metalAsGLTexture": [NSNumber numberWithLongLong: [_flutterGLTexture  metalAsGLTexture]]
        });
        return;
    }
    if ([call.method isEqualToString:@"updateTexture"]) {
        NSNumber* textureId;
        if (call.arguments) {
            textureId = call.arguments[@"textureId"];
            if (textureId == NULL){
                result([FlutterError errorWithCode: @"updateTexture Error" message: @"no texture id received by the native part of FlutterGL.updateTexture"  details:NULL]);
                return;
            }
        }
        else{
            result([FlutterError errorWithCode: @"No arguments" message: @"No arguments received by the native part of FlutterGL.updateTexture"  details:NULL]);
            return;
        }

        FlutterGlTexture* currentTexture = _flutterGLTexture;

        [_textureRegistry textureFrameAvailable:[currentTexture flutterTextureId]];
        result(nil);
        return;
    }   
    if ([call.method isEqualToString:@"getAll"]) {
        result(@{
          @"appName" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [NSNull null],
          @"packageName" : [[NSBundle mainBundle] bundleIdentifier] ?: [NSNull null],
          @"version" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: [NSNull null],
          @"buildNumber" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: [NSNull null],
        });
    } 
    if ([call.method isEqualToString:@"deleteTexture"]) {
        NSNumber* textureId;
        if (call.arguments) {
            textureId = call.arguments[@"textureId"];
            if (textureId == NULL){
                result([FlutterError errorWithCode: @"deleteTexture Error" message: @"no texture id received by the native part of FlutterGL.deleteTexture"  details:NULL]);
                return;
            }
        }
        else{
            result([FlutterError errorWithCode: @"No arguments" message: @"No arguments received by the native part of FlutterGL.deleteTexture"  details:NULL]);
            return;
        }
        result(nil);
        return;
    } 
    else {
        result(FlutterMethodNotImplemented);
    }
}
@end
