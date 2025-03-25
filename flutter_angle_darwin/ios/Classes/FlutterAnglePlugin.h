#if TARGET_OS_IOS
    #import <Flutter/Flutter.h>
#elif TARGET_OS_MAC
    #import <FlutterMacOS/FlutterMacOS.h>
#endif
#define GL_SILENCE_DEPRECATION

@interface FlutterAnglePlugin : NSObject<FlutterPlugin>
@end

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
