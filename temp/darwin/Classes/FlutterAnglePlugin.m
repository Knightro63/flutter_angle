#import "FlutterAnglePlugin.h"
#import "libEGL/EGL/egl.h"
#import "libEGL/EGL/eglext.h"
#import "libEGL/EGL/eglext_angle.h"
#import "libEGL/EGL/eglplatform.h"
#import "libEGL/KHR/khrplatform.h"
#import "libGLESv2/angle_gl.h"

#import <Metal/Metal.h>
#import <simd/simd.h>
#import <MetalKit/MetalKit.h>

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

@implementation EGLENV
- (instancetype)init{
    #if TARGET_OS_MAC
        NSOpenGLPixelFormatAttribute attr[] = {
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAStencilSize, 8,
            NSOpenGLPFAAllowOfflineRenderers,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFAMultisample,
            NSOpenGLPFASampleBuffers, 1,
            NSOpenGLPFASamples, 4,
            NSOpenGLPFAMinimumPolicy,
            NSOpenGLPFAOpenGLProfile,
            NSOpenGLProfileVersion4_1Core,
            0
        };

        NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
          
        _context = [[NSOpenGLContext alloc] initWithFormat:format shareContext:nil];
    #else
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSAssert(_openGLContext, @"Could Not Create OpenGL ES Context");
        
        BOOL isSetCurrent = [EAGLContext setCurrentContext:_openGLContext];
        
        NSAssert(isSetCurrent, @"Could not make OpenGL ES context current");
    #endif
    return self;
}
    
- (void)makeCurrentContext
{
#if TARGET_OS_MAC
    [_context makeCurrentContext];
#else
    [EAGLContext setCurrentContext:_context];
#endif
}
@end
    
@interface FlutterGlTexture() {
    CVMetalTextureCacheRef _metalTextureCache;
    CVMetalTextureRef _metalTextureCVRef;
    id<MTLTexture> _metalTexture;
    EGLImageKHR _metalAsEGLImage;
    GLuint _fbo;
    
    CVOpenGLTextureCacheRef textureCache;
    CVOpenGLTextureRef textureRef;
    NSOpenGLContext* context;
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
        //[self createMtlTextureFromCVPixBufferWithWidth:width andHeight:height];
        EGLENV* eglenv = [[EGLENV alloc] init];
        context = [eglenv context];
        [self createGLTextureWithWidth:width andHeight:height andContext:context];
        glGenFramebuffers(1, &_fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
        
        if (_texture) {
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _metalAsGLTexture, 0);
        }
        else {
            // use offscreen renderbuffer as fallback if Metal back-end is not available
            [self createTextureFromCVPixBufferWithWidth:width andHeight:height];
        }
        
        int frameBufferCheck = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE){
            NSLog(@"GFramebuffer error %d\n", frameBufferCheck);
            @throw [[OpenGLException alloc] initWithMessage: @"Framebuffer error"   andError: frameBufferCheck];
        }
        int error = glGetError() ;
        if( error != GL_NO_ERROR){
            NSLog(@"GlError while allocating Renderbuffer %d\n", error);
        }
        
        _flutterTextureId = [registry registerTexture:self];
    }
    
    return self;
}

- (void)dealloc {
    glDeleteRenderbuffers(1, &_rbo);
    glDeleteFramebuffers(1, &_fbo);
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
#if TARGET_OS_MAC

/**
 On macOS, create an OpenGL texture and retrieve an OpenGL texture name using the following steps, and as annotated in the code listings below:
 */
- (void)createGLTextureWithWidth:(int) width andHeight:(int)height andContext:(NSOpenGLContext*) context
{
    CVReturn cvret;
    // 1. Create an OpenGL CoreVideo texture cache from the pixel buffer.
    cvret  = CVOpenGLTextureCacheCreate(
                    kCFAllocatorDefault,
                    nil,
                    context.CGLContextObj,
                    context.pixelFormat.CGLPixelFormatObj,
                    nil,
                    &textureCache);
    
    NSAssert(cvret == kCVReturnSuccess, @"Failed to create OpenGL Texture Cache");
    
    NSDictionary* cvBufferProperties = @{
        (__bridge NSString*)kCVPixelBufferOpenGLCompatibilityKey : @YES,
        (__bridge NSString*)kCVPixelBufferMetalCompatibilityKey : @YES,
    };
    cvret = CVPixelBufferCreate(kCFAllocatorDefault,
                            width, height,
                            kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)cvBufferProperties,
                            &_pixelData);

    NSAssert(cvret == kCVReturnSuccess, @"Failed to create CVPixelBuffer");
    
    // 2. Create a CVPixelBuffer-backed OpenGL texture image from the texture cache.
    cvret = CVOpenGLTextureCacheCreateTextureFromImage(
                    kCFAllocatorDefault,
                    textureCache,
                    _pixelData,
                    nil,
                    &_texture);
    
    NSAssert(cvret == kCVReturnSuccess, @"Failed to create OpenGL Texture From Image");
    
    // 3. Get an OpenGL texture name from the CVPixelBuffer-backed OpenGL texture image.
    _texture = CVOpenGLTextureGetName(_texture);
}

#else // if!(TARGET_IOS || TARGET_TVOS)

/**
 On iOS, create an OpenGL ES texture from the CoreVideo pixel buffer using the following steps, and as annotated in the code listings below:
 */
- (void)createGLTextureWithWidth:(int) width andHeight:(int)height
{
    CVReturn cvret;
    // 1. Create an OpenGL ES CoreVideo texture cache from the pixel buffer.
    cvret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                    nil,
                    _openGLContext,
                    nil,
                    &_CVGLTextureCache);
    
    NSAssert(cvret == kCVReturnSuccess, @"Failed to create OpenGL ES Texture Cache");
    
    // 2. Create a CVPixelBuffer-backed OpenGL ES texture image from the texture cache.
    cvret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                    _CVGLTextureCache,
                    _CVPixelBuffer,
                    nil,
                    GL_TEXTURE_2D,
                    _formatInfo->glInternalFormat,
                    width, height,
                    _formatInfo->glFormat,
                    _formatInfo->glType,
                    0,
                    &_CVGLTexture);
    
    
    NSAssert(cvret == kCVReturnSuccess, @"Failed to create OpenGL ES Texture From Image");
    
    // 3. Get an OpenGL ES texture name from the CVPixelBuffer-backed OpenGL ES texture image.
    _openGLTexture = CVOpenGLESTextureGetName(_CVGLTexture);
}

#endif // !(TARGET_IOS || TARGET_TVOS)
- (void)createTextureFromCVPixBufferWithWidth:(int) width andHeight:(int)height {
    glGenRenderbuffers(1, &_rbo);
    glBindRenderbuffer(GL_RENDERBUFFER, _rbo);
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
    int error = glGetError();
    if (error != GL_NO_ERROR)
    {
        NSLog(@"GlError while allocating Renderbuffer %d\n", error);
        @throw [[OpenGLException alloc] initWithMessage: @"GlError while allocating Renderbuffer"   andError: error];
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER,_rbo);
}

- (void)createMtlTextureFromCVPixBufferWithWidth:(int) width andHeight:(int)height {
    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    // Create Metal texture backed by CVPixelBuffer
    id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();//GetANGLEMtlDevice(display);
    // if mtlDevice is nil, fall-back to CPU readback via glReadPixels
    if (!mtlDevice){
        @throw [[OpenGLException alloc] initWithMessage: @"GlError while allocating MTLDevice"   andError: 1];
        return;
    }

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
    EGLAttrib attribs[] = {
        EGL_NONE,
    };
    _metalAsEGLImage = eglCreateImage(
        display,
        EGL_NO_CONTEXT,
        EGL_COLORSPACE_sRGB,
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

        EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        EGLint major;
        EGLint minor;
        int initializeResult = eglInitialize(display,&major,&minor);
        if (initializeResult != 1){
            result([FlutterError errorWithCode: @"No OpenGL context" message: @"eglInit failed"  details:NULL]);
            return;
        }
        
        const EGLint attribute_list[] = {
            EGL_RENDERABLE_TYPE,
            EGL_OPENGL_ES3_BIT,
            EGL_RED_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_BLUE_SIZE, 8,
            EGL_ALPHA_SIZE, 8,
            EGL_DEPTH_SIZE, 24,
            EGL_STENCIL_SIZE, 8,
            EGL_NONE
        };

        EGLint num_config;
        EGLConfig config;
        EGLBoolean chooseConfigResult = eglChooseConfig(display,attribute_list,&config,1,&num_config);
        if (chooseConfigResult != 1){
            result([FlutterError errorWithCode: @"EGL InitError" message: @"Failed to call eglCreateWindowSurface()"  details:NULL]);
            return;
        }
        
        const EGLint surfaceAttributes[] = {
          EGL_WIDTH, 16,
          EGL_HEIGHT, 16,
          EGL_NONE
        };
        
        EGLSurface dummySurface = eglCreatePbufferSurface(display, config, surfaceAttributes);
        EGLSurface dummySurfaceForDartSide = eglCreatePbufferSurface(display, config, surfaceAttributes);
        
        if ((dummySurfaceForDartSide == EGL_NO_SURFACE) || (dummySurface == EGL_NO_SURFACE)){
            result([FlutterError errorWithCode: @"EGL InitError" message: @"Dummy Surface creation failed"  details:NULL]);
            return;
        }
        const EGLint contextAttribs[] = {
            EGL_CONTEXT_CLIENT_VERSION,
            3,
            EGL_NONE
        };
        _context = eglCreateContext(display, config, nil, contextAttribs);
        
        if (eglMakeCurrent(display, dummySurface, dummySurface, _context)!=1){
            NSLog(@"MakeCurrent failed: %d",eglGetError());
        }
        
        _flutterGLTextures = [[NSMutableArray alloc] init];
        
        result(@{
            @"context" : [NSNumber numberWithLong: (long)_context],
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
        
        FlutterGlTexture* temp;
        @try{
             temp = [[FlutterGlTexture alloc] initWithWidth:width.intValue andHeight:height.intValue registerWidth:_textureRegistry];
        }
        @catch (OpenGLException* ex){
            result([FlutterError errorWithCode: [@( [ex errorCode]) stringValue] message: [@"Error creating FlutterGLTextureObjec: " stringByAppendingString:[ex message]] details:NULL]);
            return;
        }
        [_flutterGLTextures addObject:temp];
        int c = (int)[_flutterGLTextures count];
        result(@{
            @"textureId" : [NSNumber numberWithLongLong: [temp flutterTextureId]],
            @"location" : [NSNumber numberWithLong: c-1],
            @"metalAsGLTexture": [NSNumber numberWithLongLong: [temp  metalAsGLTexture]],
            @"rbo": [NSNumber numberWithLongLong: [temp  rbo]]
        });
        return;
    }
    if ([call.method isEqualToString:@"updateTexture"]) {
        NSNumber* textureId;
        NSNumber* loc;
        if (call.arguments) {
            textureId = call.arguments[@"textureId"];
            if (textureId == NULL){
                result([FlutterError errorWithCode: @"updateTexture Error" message: @"no texture id received by the native part of FlutterGL.updateTexture"  details:NULL]);
                return;
            }
            loc = call.arguments[@"location"];
            if (loc == NULL){
                result([FlutterError errorWithCode: @"updateTexture Error" message: @"no texture loc received by the native part of FlutterGL.updateTexture"  details:NULL]);
                return;
            }
        }
        else{
            result([FlutterError errorWithCode: @"No arguments" message: @"No arguments received by the native part of FlutterGL.updateTexture"  details:NULL]);
            return;
        }
        FlutterGlTexture* currentTexture = [_flutterGLTextures objectAtIndex: [loc intValue]];
        if (currentTexture.metalAsGLTexture || currentTexture.texture) {
            // DO NOTHING, metal texture is automatically updated
        }
        else {
            glBindFramebuffer(GL_FRAMEBUFFER, currentTexture.fbo);
            CVPixelBufferLockBaseAddress([currentTexture pixelData], 0);
            void* buffer = (void*)CVPixelBufferGetBaseAddress([currentTexture pixelData]);
            glReadPixels(0, 0, (GLsizei)[currentTexture width], (GLsizei)currentTexture.height, GL_BGRA_IMG, GL_UNSIGNED_BYTE, (void*)buffer);
            CVPixelBufferUnlockBaseAddress([currentTexture pixelData],0);
        }
        
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
        NSNumber* loc;
        if (call.arguments) {
            textureId = call.arguments[@"textureId"];
            if (textureId == NULL){
                result([FlutterError errorWithCode: @"deleteTexture Error" message: @"no texture id received by the native part of FlutterGL.deleteTexture"  details:NULL]);
                return;
            }
            loc = call.arguments[@"location"];
            if (loc == NULL){
                result([FlutterError errorWithCode: @"updateTexture Error" message: @"no texture loc received by the native part of FlutterGL.updateTexture"  details:NULL]);
                return;
            }
        }
        else{
            result([FlutterError errorWithCode: @"No arguments" message: @"No arguments received by the native part of FlutterGL.deleteTexture"  details:NULL]);
            return;
        }
        
        [_flutterGLTextures removeObjectAtIndex:[loc intValue]];
        result(nil);
        return;
    } 
    else {
        result(FlutterMethodNotImplemented);
    }
}
@end
