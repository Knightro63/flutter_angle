#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif

import libEGL
import libGLESv2

// MARK: - EGL Constants
private let EGL_DEFAULT_DISPLAY: Int32 = 0
private let EGL_CONTEXT_CLIENT_VERSION: Int32 = 0x3098
private let EGL_NONE: Int32 = 0x3038
private let EGL_RED_SIZE: Int32 = 0x3024
private let EGL_GREEN_SIZE: Int32 = 0x3023
private let EGL_BLUE_SIZE: Int32 = 0x3022
private let EGL_ALPHA_SIZE: Int32 = 0x3021
private let EGL_DEPTH_SIZE: Int32 = 0x3025
private let EGL_STENCIL_SIZE: Int32 = 0x3026
private let EGL_CONFIG_ID: Int32 = 0x3028
private let EGL_SURFACE_TYPE: Int32 = 0x3033
private let EGL_PBUFFER_BIT: Int32 = 0x0001
private let EGL_WINDOW_BIT: Int32 = 0x0004
private let EGL_RENDERABLE_TYPE: Int32 = 0x3040
private let EGL_OPENGL_ES2_BIT: Int32 = 0x0004
private let EGL_OPENGL_ES3_BIT: Int32 = 0x0040
private let EGL_WIDTH: Int32 = 0x3057
private let EGL_HEIGHT: Int32 = 0x3056
private let EGL_CONTEXT_OPENGL_DEBUG: Int32 = 0x31B0
private let EGL_TRUE: Int32 = 1

// MARK: - GL Constants
private let GL_FRAMEBUFFER: UInt32 = 0x8D40
private let GL_RENDERBUFFER: UInt32 = 0x8D41
private let GL_COLOR_ATTACHMENT0: UInt32 = 0x8CE0
private let GL_RGBA8: UInt32 = 0x8058
private let GL_DEPTH24_STENCIL8: UInt32 = 0x88F0
private let GL_DEPTH_ATTACHMENT: UInt32 = 0x8D00
private let GL_FRAMEBUFFER_COMPLETE: UInt32 = 0x8CD5
private let GL_VENDOR: UInt32 = 0x1F00
private let GL_RENDERER: UInt32 = 0x1F01
private let GL_VERSION: UInt32 = 0x1F02

public class FlutterAngleSimPlugin: NSObject, FlutterTexture{
  // MARK: - EGL Properties
  private var eglDisplay: UnsafeMutableRawPointer? = nil
  private var eglContext: UnsafeMutableRawPointer? = nil
  private var eglSurface: UnsafeMutableRawPointer? = nil
  private var eglConfig: UnsafeMutableRawPointer? = nil
  private var eglConfigId: Int32 = 0
  private var lastError: String = ""
  
  // MARK: - Texture related properties
  public var textureRegistry: FlutterTextureRegistry? = nil
  private var textures: [Int64: TextureInfo] = [:]
  private var currentTextureId: Int64? = nil
  private var isDebugContext: Bool = false

    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
      guard let textureId = currentTextureId,
            let pixelBuffer = textures[textureId]?.pixelBuffer else {
        return nil
      }
      return Unmanaged.passRetained(pixelBuffer)
    }
    
  // MARK: - EGL error handling
  private func getEglErrorString() -> String {
      let errorCode = libEGL.eglGetError()
    switch errorCode {
    case 0x3000: return "EGL_SUCCESS"
    case 0x3001: return "EGL_NOT_INITIALIZED"
    case 0x3002: return "EGL_BAD_ACCESS"
    case 0x3003: return "EGL_BAD_ALLOC"
    case 0x3004: return "EGL_BAD_ATTRIBUTE"
    case 0x3005: return "EGL_BAD_CONFIG"
    case 0x3006: return "EGL_BAD_CONTEXT"
    case 0x3007: return "EGL_BAD_CURRENT_SURFACE"
    case 0x3008: return "EGL_BAD_DISPLAY"
    case 0x3009: return "EGL_BAD_MATCH"
    case 0x300A: return "EGL_BAD_NATIVE_PIXMAP"
    case 0x300B: return "EGL_BAD_NATIVE_WINDOW"
    case 0x300C: return "EGL_BAD_PARAMETER"
    case 0x300D: return "EGL_BAD_SURFACE"
    case 0x300E: return "EGL_CONTEXT_LOST"
    default: return "Unknown EGL error: \(errorCode)"
    }
  }
  
    public func initOpenGL() -> [String: Any] {
    
    #if targetEnvironment(simulator)
      let isSim = true;
    #else
      let isSim = false;
    #endif
    // Only initialize once
    if eglDisplay != nil && eglContext != nil {
      NSLog("EGL already initialized, returning existing context")
      let contextAddress = Int(bitPattern: eglContext!)
      let surfaceAddress = Int(bitPattern: eglSurface!)
      
      NSLog("Returning existing context: \(contextAddress), surface: \(surfaceAddress), configId: \(eglConfigId)")
      
      return [
        "isSimulator": isSim,
        "context": contextAddress,
        "dummySurface": surfaceAddress,
        "eglConfigId": Int(eglConfigId),
        "openGLVersion": "OpenGL ES 3.0 ANGLE"
      ]
    }
    
    // Get EGL display
      guard let display = libEGL.eglGetDisplay(EGL_DEFAULT_DISPLAY) else {
      let errorMsg = "Failed to get EGL display"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    eglDisplay = display
    NSLog("Got EGL display: \(Int(bitPattern: display))")
    
    // Initialize EGL
    var major: Int32 = 0
    var minor: Int32 = 0
    
      if libEGL.eglInitialize(display, &major, &minor) == 0 {
      let error = getEglErrorString()
      let errorMsg = "Failed to initialize EGL: \(error)"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    NSLog("EGL Initialized with version \(major).\(minor)")
    
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
    
    if libEGL.eglChooseConfig(display, configAttribs, &configs, 1, &numConfigs) == 0 {
      let error = getEglErrorString()
      let errorMsg = "Failed to choose EGL config: \(error)"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    guard configs != nil else {
      let errorMsg = "No valid EGL configs found"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    eglConfig = configs
    NSLog("Got EGL config: \(Int(bitPattern: configs))")
    
    // Get the config ID for sharing with Dart side
    var configId: Int32 = 0
    
    if libEGL.eglGetConfigAttrib(display, configs, EGL_CONFIG_ID, &configId) == 0 {
      let error = getEglErrorString()
      let errorMsg = "Failed to get EGL config ID: \(error)"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    eglConfigId = configId
    NSLog("Got EGL config ID: \(configId)")
    
    // Try different surface creation approaches
    
    // Approach 1: Create a pbuffer surface with larger dimensions (256x256)
    var surfaceAttribs: [Int32] = [
      EGL_WIDTH, 256,   // Increased size significantly
      EGL_HEIGHT, 256,  // Increased size significantly
      EGL_NONE
    ]
    
    // Try to create a pbuffer surface
    var surface = libEGL.eglCreatePbufferSurface(display, configs, surfaceAttribs)
    var surfaceAddress = Int(bitPattern: surface)
    
    // If the first attempt failed, try with different attributes
    if (surface == nil || surfaceAddress <= 1) {
      NSLog("First pbuffer creation attempt failed, trying with different attributes")
      surfaceAttribs = [
        EGL_WIDTH, 64,
        EGL_HEIGHT, 64,
        // Add explicit binding attribute
        0x3039, 0x3038, // EGL_BIND_TO_TEXTURE_RGB, EGL_NONE
        EGL_NONE
      ]
      
      surface = libEGL.eglCreatePbufferSurface(display, configs, surfaceAttribs)
      surfaceAddress = Int(bitPattern: surface)
      
      // If still failed, try one more approach
      if (surface == nil || surfaceAddress <= 1) {
        NSLog("Second pbuffer creation attempt failed, trying minimal configuration")
        surfaceAttribs = [
          EGL_WIDTH, 4,
          EGL_HEIGHT, 4,
          EGL_NONE
        ]
        
        surface = libEGL.eglCreatePbufferSurface(display, configs, surfaceAttribs)
        surfaceAddress = Int(bitPattern: surface)
      }
    }
    
    // Check if we have a valid surface
    if (surface == nil || surfaceAddress <= 1) {
      let error = getEglErrorString()
      let errorMsg = "Failed to create pbuffer surface: \(error). Surface handle: \(surfaceAddress)"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    NSLog("Created EGL pbuffer surface with handle: \(surfaceAddress)")
    eglSurface = surface
    
    // Create GLES3 context
    let contextAttribs: [Int32] = [
      EGL_CONTEXT_CLIENT_VERSION, 3,
      EGL_NONE
    ]
    
    guard let context = libEGL.eglCreateContext(display, configs, nil, contextAttribs) else {
      let error = getEglErrorString()
      let errorMsg = "Failed to create EGL context: \(error)"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    eglContext = context
    let contextAddress = Int(bitPattern: context)
    NSLog("Created EGL context with handle: \(contextAddress)")

    if libEGL.eglMakeCurrent(display, surface, surface, context) == 0 {
      let error = getEglErrorString()
      let errorMsg = "Failed to make context current: \(error). Context: \(contextAddress), Surface: \(surfaceAddress)"
      NSLog(errorMsg)
      // Don't return error here - try to continue with the context/surface we've created
    } else {
      NSLog("Successfully made context current")
    }
    
    // Print OpenGL information
    if let version = getGLString(GL_VERSION),
       let vendor = getGLString(GL_VENDOR),
       let renderer = getGLString(GL_RENDERER) {
      NSLog("OpenGL initialized: Vendor: \(vendor), Renderer: \(renderer), Version: \(version)")
    }
    
    // Ensure the context value is explicitly included
    let result: [String: Any] = [
      "isSimulator": isSim,
      "context": contextAddress,
      "eglConfigId": Int(configId),
      "dummySurface": surfaceAddress,
      "openGLVersion": "OpenGL ES 3.0 ANGLE"
    ]
    
    NSLog("InitOpenGL returning: \(result)")
    return result
  }
  
  // MARK: - OpenGL Helpers
  private func getGLString(_ name: UInt32) -> String? {
      guard let stringPtr = libGLESv2.glGetString(name) else {
      return nil
    }
    
      return String(cString: stringPtr)
  }
  
  // MARK: - Texture Management
  private struct TextureInfo {
    let width: Int
    let height: Int
    let pixelBuffer: CVPixelBuffer
    let textureId: Int64
    var rboId: UInt32 = 0
    var fboId: UInt32 = 0
    var metalTextureId: UInt32 = 0
    var frameCount: Int = 0
  }
  
    public func createTexture(width: Int, height: Int, ftr: FlutterAnglePlugin, result: @escaping FlutterResult){
    guard let registry = textureRegistry else {
        result(["error": "Texture registry not available"]);
        return
    }
    
    // Ensure EGL is initialized
    if eglDisplay == nil || eglContext == nil {
      let initResult = initOpenGL()
      if initResult["error"] != nil {
        return result(initResult)
      }
    }
    
    // Create CVPixelBuffer for the texture
    var pixelBufferOut: CVPixelBuffer?
    let options: [String: Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
      kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]
    
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                    width,
                                    height,
                                    kCVPixelFormatType_32BGRA,
                                    options as CFDictionary,
                                    &pixelBufferOut)
    
    guard status == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else {
        result(["error": "Failed to create pixel buffer: \(status)"]);
        return
    }
    
    // Register texture with Flutter
    let textureId = registry.register(self)
    
    // Setup texture info
    let textureInfo = TextureInfo(
      width: width,
      height: height,
      pixelBuffer: pixelBuffer,
      textureId: textureId
    )
    
    textures[textureId] = textureInfo
    currentTextureId = textureId
    
    // Setup OpenGL resources for the texture
    setupOpenGLResources(for: textureId)
    
    let info = textures[textureId]!
    NSLog("Created texture ID: \(textureId), FBO: \(info.fboId), RBO: \(info.rboId)")
    
    result([
      "textureId": textureId,
      "rbo": Int(info.rboId),
      "metalAsGLTexture": Int(info.metalTextureId),
      "location": 0  // For compatibility with Android
    ]);
  }
  
  private func setupOpenGLResources(for textureId: Int64) {
    guard let textureInfo = textures[textureId] else {
      NSLog("Failed to setup OpenGL resources - missing texture or GLES library")
      return
    }
    
    // Make EGL context current
    if eglContext != nil && eglDisplay != nil && eglSurface != nil {
        libEGL.eglMakeCurrent(eglDisplay!, eglSurface!, eglSurface!, eglContext!)
    }
    
    // Create framebuffer
    var fbo: UInt32 = 0
      libGLESv2.glGenFramebuffers(1, &fbo)
      libGLESv2.glBindFramebuffer(GL_FRAMEBUFFER, fbo)
    
    // Create color renderbuffer
    var rbo: UInt32 = 0
      libGLESv2.glGenRenderbuffers(1, &rbo)
      libGLESv2.glBindRenderbuffer(GL_RENDERBUFFER, rbo)
      libGLESv2.glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, Int32(textureInfo.width), Int32(textureInfo.height))
      libGLESv2.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rbo)
    
    // Create depth renderbuffer
//    var depthRbo: UInt32 = 0
//      libGLESv2.glGenRenderbuffers(1, &depthRbo)
//      libGLESv2.glBindRenderbuffer(GL_RENDERBUFFER, depthRbo)
//      libGLESv2.glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, Int32(textureInfo.width), Int32(textureInfo.height))
//      libGLESv2.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRbo)
   
    // Check framebuffer status
      let status = libGLESv2.glCheckFramebufferStatus(GL_FRAMEBUFFER)
    if status != GL_FRAMEBUFFER_COMPLETE {
      NSLog("Framebuffer incomplete: \(status)")
    } else {
      NSLog("Framebuffer complete")
    }
    
    // Check for GL errors
      let error = libGLESv2.glGetError()
    if error != 0 {
      NSLog("GL error during framebuffer setup: \(error)")
    }
    
    // Update the texture info with the OpenGL IDs
    var updatedInfo = textureInfo
    updatedInfo.fboId = fbo
    updatedInfo.rboId = rbo
    textures[textureId] = updatedInfo
  }
  
    public func updateTexture(textureId: Int64) -> Bool {
    guard let textureInfo = textures[textureId] else {
      NSLog("Failed to update texture - missing texture or GLES library")
      return false
    }
    
    // Make EGL context current
    if eglContext != nil && eglDisplay != nil && eglSurface != nil {
        libEGL.eglMakeCurrent(eglDisplay!, eglSurface!, eglSurface!, eglContext!)
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
    CVPixelBufferLockBaseAddress(textureInfo.pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    let width = textureInfo.width
    let height = textureInfo.height
    let pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(textureInfo.pixelBuffer)
    
    // Actually read the pixels from framebuffer to memory
    // Use GL_BGRA instead of GL_RGBA to match macOS CVPixelBuffer format (kCVPixelFormatType_32BGRA)
      libGLESv2.glReadPixels(0, 0, Int32(width), Int32(height), GL_BGRA, GL_UNSIGNED_BYTE, pixelBufferBaseAddress)
    
    // Check for GL errors
      let error = libGLESv2.glGetError()
    if error != 0 {
      NSLog("GL error during readPixels: \(error)")
    }
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(textureInfo.pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    // Ensure all commands are submitted
      libGLESv2.glFlush()
    
    // Mark the texture as needing update
    currentTextureId = textureId
    textureRegistry?.textureFrameAvailable(textureId)
    return true
  }
  
    public func deleteTexture(textureId: Int64) {
    guard let textureRegistry = textureRegistry,
          let textureInfo = textures[textureId] else {
      return
    }
    
    // Make EGL context current
    if eglContext != nil && eglDisplay != nil && eglSurface != nil {
        libEGL.eglMakeCurrent(eglDisplay!, eglSurface!, eglSurface!, eglContext!)
    }
    
    // Delete framebuffer and renderbuffer
    var fbo = textureInfo.fboId
    var rbo = textureInfo.rboId
    
    if fbo != 0 {
        libGLESv2.glDeleteFramebuffers(1, &fbo)
    }
    
    if rbo != 0 {
        libGLESv2.glDeleteRenderbuffers(1, &rbo)
    }
    
    // Unregister from texture registry
    textureRegistry.unregisterTexture(textureId)
    
    // Remove from our map
    textures.removeValue(forKey: textureId)
    
    if currentTextureId == textureId {
      currentTextureId = textures.keys.first
    }
  }
  
  // MARK: - Clean up resources
  public func isposeTexture(textureId: Int64) {
    // Delete all textures
    for textureId in textures.keys {
      deleteTexture(textureId: textureId)
    }
    
    // Clean up EGL
    if let eglDisplay = eglDisplay,
       let eglContext = eglContext,
       let eglSurface = eglSurface {
        
        let EGL_NO_SURFACE = UnsafeMutableRawPointer(bitPattern: 0)
        let EGL_NO_CONTEXT = UnsafeMutableRawPointer(bitPattern: 0)
        
        // Release EGL resources
        let makeCurrent = libEGL.eglMakeCurrent(eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)
        if makeCurrent == 0 {
          NSLog("Failed to make EGL_NO_CONTEXT current during cleanup")
        }
        
        let destroySurface = libEGL.eglDestroySurface(eglDisplay, eglSurface)
        if destroySurface == 0 {
          NSLog("Failed to destroy EGL surface during cleanup")
        }
        
        let destroyContext = libEGL.eglDestroyContext(eglDisplay, eglContext)
        if destroyContext == 0 {
          NSLog("Failed to destroy EGL context during cleanup")
        }
        
        let terminate = libEGL.eglTerminate(eglDisplay)
        if terminate == 0 {
          NSLog("Failed to terminate EGL during cleanup")
        }
      }
  }
}
