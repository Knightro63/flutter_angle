#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
import libEGL
import libGLESv2

public class MTLRender: NSObject, FlutterTexture {
    var metalTextureCache:CVMetalTextureCache?;
    var metalTextureCVRef:CVMetalTexture?;
    var metalTexture:MTLTexture?;
    var metalAsEGLImage:EGLImageKHR?;
    var metalAsGLTexture:GLuint = 0;
    
    var targetPixelBuffer: CVPixelBuffer?;
    var pixelData:CVPixelBuffer?;
    
    var width: Int;
    var height: Int;
    var sharedContext:EGLContext;
    
    init(
        _ width:Int,
        _ height:Int,
        _ sharedContext:EGLContext
    ) {
        self.width = width;
        self.height = height;
        self.sharedContext = sharedContext;
        
        super.init();
        self.initGL(context: sharedContext);
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
    
    func initGL(context: EGLContext) {
        var options:NSDictionary = [
          kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        var status:CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, options, &pixelData);
        if (status != 0){
          print("CVPixelBufferCreate error %d", status);
        }
        
        CVPixelBufferLockBaseAddress(pixelData!, CVPixelBufferLockFlags(rawValue: 0));
        self.createMtlTextureFromCVPixBufferWithSize(width,height);
    }
    
    public func createMtlTextureFromCVPixBufferWithSize(_ width:Int, _ height:Int){
      let display = eglGetPlatformDisplay(EGLenum(EGL_ANGLE_device_metal), nil, nil);
      // Create Metal texture backed by CVPixelBuffer
      var mtlDevice:MTLDevice? = MTLCreateSystemDefaultDevice();
      // if mtlDevice is nil, fall-back to CPU readback via glReadPixels
      if (mtlDevice == nil){
          return;
      }

      var status:CVReturn = CVMetalTextureCacheCreate(
        kCFAllocatorDefault,
        nil,
        mtlDevice!,
        nil,
        &metalTextureCache
      );
        
      if (status != 0){
          print("CVMetalTextureCacheCreate error %d", status);
      }

      status = CVMetalTextureCacheCreateTextureFromImage(
        kCFAllocatorDefault,
        metalTextureCache!,
        targetPixelBuffer!,
        nil,
        MTLPixelFormat.bgra8Unorm,
        width, height,
        0,
        &metalTextureCVRef
      );
      if (status != 0){
        print("CVMetalTextureCacheCreateTextureFromImage error %d", status);
      }
        
      metalTexture = CVMetalTextureGetTexture(metalTextureCVRef!);

      // Create EGL image backed by Metal texture
      let attribs:[EGLint] = [
          EGL_NONE
      ];
        EGLDisplay dpy, EGLContext ctx, EGLenum target, EGLClientBuffer buffer, const EGLAttrib *attrib_list
      metalAsEGLImage = eglCreateImage(
          display,
          EGL_NO_CONTEXT,
          EGL_MTL_TEXTURE_MGL,
          (__bridge EGLClientBuffer)(_metalTexture),
          attribs
      );

      // Create a texture target to bind the egl image
      glGenTextures(1, &metalAsGLTexture);
      glBindTexture(GL_TEXTURE_2D, metalAsGLTexture);
      
      var glEGLImageTargetTexture2DOES = eglGetProcAddress("glEGLImageTargetTexture2DOES");
      glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, metalAsEGLImage);
    }
    
    func dispose(){
        // TODO: deallocate GL resources
        metalTexture = nil;
        if (metalTextureCVRef != nil) {
            metalTextureCVRef = nil;
        }
        if (metalTextureCache != nil) {
            metalTextureCache = nil;
        }
    }
}

public class MTLEglEnv : NSObject {
  var context:EGLContext?;
  var dummySurface:EGLSurface?;
  var display:EGLDisplay?;
  var dummySurfaceForDartSide:EGLSurface?;
  
  func setupRender() {
      display = eglGetPlatformDisplay(EGLenum(EGL_ANGLE_device_metal), nil, nil);
      
      var major:EGLint = 0;
      var minor:EGLint = 0;
        
      let initializeResult:UInt32 = eglInitialize(display,&major,&minor);
      
      if (initializeResult != 1){
          print("No OpenGL context returned error \(eglGetError())")
        return;
      }
        
      var configAttribs:[EGLint] = [
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 24,
        EGL_STENCIL_SIZE, 8,
        EGL_NONE
      ];

      let configs = UnsafeMutablePointer<EGLConfig?>.allocate(capacity: 1)
      defer { configs.deallocate() }

      var numConfigs: EGLint = 0
      guard eglChooseConfig(display, &configAttribs, configs, 1, &numConfigs) != 0 else {
          print("eglChooseConfig() returned error \(eglGetError())")
          return
      }
      guard let config = configs.pointee else {
        return;
      }
      
      let dummyLayer:CALayer = CALayer();//[[CALayer alloc] init];
      dummyLayer.frame = CGRectMake(0, 0, 1, 1);
      let dummyLayer2:CALayer = CALayer();//[[CALayer alloc] init];
      dummyLayer2.frame = CGRectMake(0, 0, 1, 1);
        
      dummySurface = eglCreateWindowSurface(display, config, unsafeBitCast(dummyLayer, to: EGLNativeWindowType.self), nil);
      dummySurfaceForDartSide = eglCreateWindowSurface(display, config, unsafeBitCast(dummyLayer2, to: EGLNativeWindowType.self), nil);
      
      makeCurrent();
  }
  func makeCurrent() {
    if (eglMakeCurrent(display, dummySurface, dummySurface, context) != 1){
      print("MakeCurrent failed: %d",eglGetError());
    }
  }
  
  func getContext() -> Int64 {
    // todo two different context object hashValue is always different???
    return Int64(self.context.hashValue);
  }

  func dispose() {
    self.context = nil;
  }
  
}

enum MyError: Error {
  case runtimeError(String)
}
