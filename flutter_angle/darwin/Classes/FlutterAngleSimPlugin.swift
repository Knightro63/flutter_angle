//#if targetEnvironment(simulator)

#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif
import MetalANGLE

private struct TextureInfo {
  var metalTextureId: UInt32 = 0
  var frameCount: Int = 0
  var eglImage: EGLImageKHR?
}
public struct EGLInfo {
  var eglDisplay: UnsafeMutableRawPointer
  var eglContext: EGLContext?
  var eglSurface: EGLSurface?
  var dartSurface: EGLSurface?
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

    var layer: CALayer = CALayer.init()
    layer.frame = CGRectMake(0, 0, 1, 1)
    var layer2: CALayer = CALayer.init()
    layer2.frame = CGRectMake(0, 0, 1, 1);
      
    let nativeWindow = unsafeBitCast(layer, to: EGLNativeWindowType.self)
    let surface = eglCreateWindowSurface(display, configs, nativeWindow, nil)
    let nativeWindow2 = unsafeBitCast(layer2, to: EGLNativeWindowType.self)
    let dartSurface = eglCreateWindowSurface(display, configs, nativeWindow2, nil)

    if (surface == nil || dartSurface == nil){
      result(FlutterError(code: "Flutter Angle Error", message: "Failed to get Surface", details: nil))
      return nil
    }
    
      let contextAttribs: [EGLint] = [
          EGL_CONTEXT_CLIENT_VERSION, 3, // Specify OpenGL ES 2.0
          EGL_NONE
      ]
    var context: EGLContext? = eglCreateContext(display, configs, nil, contextAttribs)
      
    if eglMakeCurrent(display, surface, surface, context) != 1 {
      result(FlutterError(code: "Flutter Angle Error", message: "Failed to get Create Context", details: nil))
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
      "dummySurface": Int(bitPattern: dartSurface),
      "openGLVersion": "OpenGL ES 3.0 ANGLE"
    ]
    
    print("InitOpenGL returning: \(results)")
    result(results)
    return EGLInfo(
      eglDisplay: display,
      eglContext: context,
      eglSurface: surface,
      dartSurface: dartSurface
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
      
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      options as CFDictionary,
      &pixelBuffer
    )
      
    guard status == kCVReturnSuccess else {
      result(["error": "Failed to create pixel buffer: \(status)"]);
      return
    }
      
    textures = TextureInfo()
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    createMtlTextureFromCVPixBuffer(width: width, height: height)
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    result([
      "textureId": textureId,
      "openglTexture": Int(textures!.metalTextureId)
    ]);
  }
  private func getANGLEMtlDevice(display: EGLDisplay) -> MTLDevice?{
    var angleDevice: EGLAttrib = 0;
    var device: EGLAttrib      = 0;
    
    if (eglQueryDisplayAttribEXT(eglInfo!.eglDisplay, EGL_DEVICE_EXT, &angleDevice) != EGL_TRUE){
      print(angleDevice);
      return nil;
    }
    
    if (eglQueryDeviceAttribEXT((EGLDeviceEXT)(bitPattern: angleDevice)!, EGL_MTL_DEVICE_ANGLE, &device) != EGL_TRUE){
      return nil;
    }

    return unsafeBitCast(device, to: MTLDevice.self);
  }
  private func createMtlTextureFromCVPixBuffer(width: Int, height: Int) {
    // Create Metal texture backed by CVPixelBuffer
    guard let mtlDevice:MTLDevice =  getANGLEMtlDevice(display: eglInfo!.eglDisplay)else {
      fatalError("Could not create Metal Device")
    }//MTLCreateSystemDefaultDevice() 

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
    textures!.eglImage = eglCreateImageKHR(eglInfo!.eglDisplay, nil, EGLenum(EGL_MTL_TEXTURE_MGL), unsafeBitCast(metalTexture!, to: EGLClientBuffer.self), [EGL_NONE])
    
    glGenTextures(1, &textures!.metalTextureId)
    glBindTexture(GLenum(GL_TEXTURE_2D), textures!.metalTextureId)
    
    let swapBuffersPtr = eglGetProcAddress("glEGLImageTargetTexture2DOES")
    let swapBuffers = unsafeBitCast(swapBuffersPtr, to: PFNGLEGLIMAGETARGETTEXTURE2DOESPROC.self)
    
    swapBuffers(GLenum(GL_TEXTURE_2D), textures!.eglImage!)
  }
  
  public func textureFrameAvailable(result: @escaping FlutterResult) {    
    textureRegistry?.textureFrameAvailable(textureId)
    result(nil)
  }

  public func resizeTexture(width: Int, height: Int, result: @escaping FlutterResult) {    
    glDeleteTextures(1, &textures!.metalTextureId)
    eglDestroyImageKHR(eglInfo!.eglDisplay, textures!.eglImage!);
    textures!.eglImage = nil
    textures = nil
    pixelBuffer = nil

    createTexture(width: width, height: height, result: result)
  }

  public func disposeTexture() {
    if let tr = textureRegistry {
      tr.unregisterTexture(textureId)
    }
      
    // Clean up EGL
    let eglDisplay = eglInfo!.eglDisplay
    
    // Release EGL resources
    let makeCurrent = eglMakeCurrent(eglDisplay, nil, nil, nil)
    if makeCurrent == 0 {
      print("Failed to make EGL_NO_CONTEXT current during cleanup")
    }

    let eglContext = eglInfo!.eglContext
    eglDestroyContext(eglDisplay,eglContext)
      
    let surface = eglInfo!.eglSurface
    let dartSurface = eglInfo!.dartSurface
    eglDestroySurface(eglDisplay, surface)
    eglDestroySurface(eglDisplay, dartSurface)
    glDeleteTextures(1, &textures!.metalTextureId)
    eglDestroyImageKHR(eglDisplay, textures!.eglImage)

    // Clean up our maps
    textures = nil
    pixelBuffer = nil

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
//#endif
