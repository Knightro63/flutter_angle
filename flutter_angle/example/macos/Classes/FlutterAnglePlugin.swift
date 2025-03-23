import FlutterMacOS
import Foundation
import AppKit
import CoreVideo
import CoreGraphics

// MARK: - EGL Constants
private let EGL_DEFAULT_DISPLAY: Int = 0
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

public class FlutterAnglePlugin: NSObject, FlutterPlugin, FlutterTexture {
  // MARK: - EGL Properties
  private var eglHandle: UnsafeMutableRawPointer? = nil
  private var glesHandle: UnsafeMutableRawPointer? = nil
  private var eglDisplay: UnsafeMutableRawPointer? = nil
  private var eglContext: UnsafeMutableRawPointer? = nil
  private var eglSurface: UnsafeMutableRawPointer? = nil
  private var eglConfig: UnsafeMutableRawPointer? = nil
  private var eglConfigId: Int32 = 0
  private var lastError: String = ""
  
  // MARK: - EGL Function Types
  private typealias EGLGetDisplayFunc = @convention(c) (Int) -> UnsafeMutableRawPointer?
  private typealias EGLInitializeFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<Int32>?, UnsafeMutablePointer<Int32>?) -> UInt32
  private typealias EGLChooseConfigFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<Int32>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?, Int32, UnsafeMutablePointer<Int32>?) -> UInt32
  private typealias EGLCreateContextFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafePointer<Int32>?) -> UnsafeMutableRawPointer?
  private typealias EGLCreatePbufferSurfaceFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafePointer<Int32>?) -> UnsafeMutableRawPointer?
  private typealias EGLMakeCurrentFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> UInt32
  private typealias EGLGetConfigAttribFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<Int32>?) -> UInt32
  private typealias EGLGetErrorFunc = @convention(c) () -> UInt32
  
  // Cache these function pointers to avoid looking them up repeatedly
  private var eglGetDisplay: EGLGetDisplayFunc?
  private var eglInitialize: EGLInitializeFunc?
  private var eglChooseConfig: EGLChooseConfigFunc?
  private var eglCreateContext: EGLCreateContextFunc?
  private var eglCreatePbufferSurface: EGLCreatePbufferSurfaceFunc?
  private var eglMakeCurrent: EGLMakeCurrentFunc?
  private var eglGetConfigAttrib: EGLGetConfigAttribFunc?
  private var eglGetError: EGLGetErrorFunc?
  
  // MARK: - Texture related properties
  private var textureRegistry: FlutterTextureRegistry? = nil
  private var textures: [Int64: TextureInfo] = [:]
  private var currentTextureId: Int64? = nil
  private var isDebugContext: Bool = false
  
  // MARK: - Plugin Registration
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_angle", binaryMessenger: registrar.messenger)
    let instance = FlutterAnglePlugin()
    
    // Store the texture registry from registrar
    instance.textureRegistry = registrar.textures
    
    registrar.addMethodCallDelegate(instance, channel: channel)
    NSLog("FlutterAnglePlugin registered with texture registry: \(instance.textureRegistry != nil)")
  }
  
  // MARK: - Method Channel Handler
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    NSLog("FlutterAnglePlugin received method call: \(call.method)")
    
    switch call.method {
    case "getPlatformVersion":
      result(getPlatformVersion())
      
    case "initOpenGL":
      let glResult = initOpenGL()
      // Log the result for debugging
      NSLog("initOpenGL returning: \(glResult)")
      
      // Make sure we always have a context value
      if glResult["context"] == nil && glResult["error"] == nil {
        var modifiedResult = glResult
        if let context = eglContext {
          modifiedResult["context"] = Int(bitPattern: context)
          NSLog("Added missing context to result: \(Int(bitPattern: context))")
        } else {
          modifiedResult["error"] = "Failed to create or get OpenGL context"
          NSLog("No valid context available to return")
        }
        result(modifiedResult)
      } else {
        result(glResult)
      }
      
    case "createTexture":
      if let args = call.arguments as? [String: Any],
         let width = args["width"] as? Int,
         let height = args["height"] as? Int {
        result(createTexture(width: width, height: height))
      } else {
        result(FlutterError(code: "INVALID_ARGS", message: "Width and height required", details: nil))
      }
      
    case "updateTexture":
      if let args = call.arguments as? [String: Any],
         let textureId = args["textureId"] as? Int64 {
        result(updateTexture(textureId: textureId))
      } else {
        result(FlutterError(code: "INVALID_ARGS", message: "TextureId required", details: nil))
      }
      
    case "deleteTexture":
      if let args = call.arguments as? [String: Any],
         let textureId = args["textureId"] as? Int64 {
        deleteTexture(textureId: textureId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGS", message: "TextureId required", details: nil))
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - FlutterTexture protocol
  public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    guard let textureId = currentTextureId, 
          let pixelBuffer = textures[textureId]?.pixelBuffer else {
      return nil
    }
    return Unmanaged.passRetained(pixelBuffer)
  }
  
  // MARK: - System Info Methods
  private func getPlatformVersion() -> String {
    let osVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
    return "macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
  }
  
  // MARK: - EGL error handling
  private func getEglErrorString() -> String {
    guard let eglGetError = self.eglGetError else {
      return "Unknown error (eglGetError not available)"
    }
    
    let errorCode = eglGetError()
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
  
  // MARK: - EGL Initialization
  private func loadEGLFunctions() -> Bool {
    // Load EGL library if needed
    if eglHandle == nil {
      eglHandle = dlopen("libEGL.dylib", RTLD_NOW)
    }
    
    guard let handle = eglHandle else {
      lastError = "Failed to load libEGL.dylib: \(String(cString: dlerror()))"
      return false
    }
    
    // Load GLES library if needed
    if glesHandle == nil {
      glesHandle = dlopen("libGLESv2.dylib", RTLD_NOW)
      if glesHandle == nil {
        lastError = "Failed to load libGLESv2.dylib: \(String(cString: dlerror()))"
        return false
      }
    }
    
    // Get EGL function pointers
    guard let eglGetDisplaySym = dlsym(handle, "eglGetDisplay"),
          let eglInitializeSym = dlsym(handle, "eglInitialize"),
          let eglChooseConfigSym = dlsym(handle, "eglChooseConfig"),
          let eglCreateContextSym = dlsym(handle, "eglCreateContext"),
          let eglCreatePbufferSurfaceSym = dlsym(handle, "eglCreatePbufferSurface"),
          let eglMakeCurrentSym = dlsym(handle, "eglMakeCurrent"),
          let eglGetConfigAttribSym = dlsym(handle, "eglGetConfigAttrib"),
          let eglGetErrorSym = dlsym(handle, "eglGetError") else {
      lastError = "Failed to load required EGL functions"
      return false
    }
    
    // Convert function pointers to Swift callable functions
    eglGetDisplay = unsafeBitCast(eglGetDisplaySym, to: EGLGetDisplayFunc.self)
    eglInitialize = unsafeBitCast(eglInitializeSym, to: EGLInitializeFunc.self)
    eglChooseConfig = unsafeBitCast(eglChooseConfigSym, to: EGLChooseConfigFunc.self)
    eglCreateContext = unsafeBitCast(eglCreateContextSym, to: EGLCreateContextFunc.self)
    eglCreatePbufferSurface = unsafeBitCast(eglCreatePbufferSurfaceSym, to: EGLCreatePbufferSurfaceFunc.self)
    eglMakeCurrent = unsafeBitCast(eglMakeCurrentSym, to: EGLMakeCurrentFunc.self)
    eglGetConfigAttrib = unsafeBitCast(eglGetConfigAttribSym, to: EGLGetConfigAttribFunc.self)
    eglGetError = unsafeBitCast(eglGetErrorSym, to: EGLGetErrorFunc.self)
    
    return true
  }
  
  private func initOpenGL() -> [String: Any] {
    // Only initialize once
    if eglDisplay != nil && eglContext != nil {
      NSLog("EGL already initialized, returning existing context")
      let contextAddress = Int(bitPattern: eglContext!)
      let surfaceAddress = Int(bitPattern: eglSurface!)
      
      NSLog("Returning existing context: \(contextAddress), surface: \(surfaceAddress), configId: \(eglConfigId)")
      
      return [
        "context": contextAddress,
        "dummySurface": surfaceAddress,
        "eglConfigId": Int(eglConfigId),
        "openGLVersion": "OpenGL ES 3.0 ANGLE"
      ]
    }
    
    // Load EGL functions
    guard loadEGLFunctions() else {
      let errorMsg = "Failed to load EGL functions: \(lastError)"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    // Get EGL display
    guard let display = eglGetDisplay?(EGL_DEFAULT_DISPLAY) else {
      let errorMsg = "Failed to get EGL display"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    eglDisplay = display
    NSLog("Got EGL display: \(Int(bitPattern: display))")
    
    // Initialize EGL
    var major: Int32 = 0
    var minor: Int32 = 0
    guard let initialize = eglInitialize else {
      let errorMsg = "eglInitialize function not available"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    if initialize(display, &major, &minor) == 0 {
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
    
    guard let chooseConfig = eglChooseConfig else {
      let errorMsg = "eglChooseConfig function not available"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    if chooseConfig(display, configAttribs, &configs, 1, &numConfigs) == 0 {
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
    guard let getConfigAttrib = eglGetConfigAttrib else {
      let errorMsg = "eglGetConfigAttrib function not available"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    if getConfigAttrib(display, configs, EGL_CONFIG_ID, &configId) == 0 {
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
    
    guard let createPbufferSurface: FlutterAnglePlugin.EGLCreatePbufferSurfaceFunc = eglCreatePbufferSurface else {
      let errorMsg = "eglCreatePbufferSurface function not available"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    // Try to create a pbuffer surface
    var surface = createPbufferSurface(display, configs, surfaceAttribs)
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
      
      surface = createPbufferSurface(display, configs, surfaceAttribs)
      surfaceAddress = Int(bitPattern: surface)
      
      // If still failed, try one more approach
      if (surface == nil || surfaceAddress <= 1) {
        NSLog("Second pbuffer creation attempt failed, trying minimal configuration")
        surfaceAttribs = [
          EGL_WIDTH, 4,
          EGL_HEIGHT, 4,
          EGL_NONE
        ]
        
        surface = createPbufferSurface(display, configs, surfaceAttribs)
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
    
    guard let createContext = eglCreateContext else {
      let errorMsg = "eglCreateContext function not available"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    guard let context = createContext(display, configs, nil, contextAttribs) else {
      let error = getEglErrorString()
      let errorMsg = "Failed to create EGL context: \(error)"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    eglContext = context
    let contextAddress = Int(bitPattern: context)
    NSLog("Created EGL context with handle: \(contextAddress)")
    
    // Make context current
    guard let makeCurrent = eglMakeCurrent else {
      let errorMsg = "eglMakeCurrent function not available"
      NSLog(errorMsg)
      return ["error": errorMsg]
    }
    
    if makeCurrent(display, surface, surface, context) == 0 {
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
    guard let glesLib = glesHandle else {
      return nil
    }
    
    typealias GLGetStringFunc = @convention(c) (UInt32) -> UnsafePointer<UInt8>?
    guard let glGetString: GLGetStringFunc = dlsym(glesLib, "glGetString").map({ unsafeBitCast($0, to: GLGetStringFunc.self) }) else {
      return nil
    }
    
    guard let stringPtr = glGetString(name) else {
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
  
  private func createTexture(width: Int, height: Int) -> [String: Any] {
    guard let registry = textureRegistry else {
      return ["error": "Texture registry not available"]
    }
    
    // Ensure EGL is initialized
    if eglDisplay == nil || eglContext == nil {
      let initResult = initOpenGL()
      if initResult["error"] != nil {
        return initResult
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
      return ["error": "Failed to create pixel buffer: \(status)"]
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
    
    return [
      "textureId": textureId,
      "rbo": Int(info.rboId),
      "metalAsGLTexture": Int(info.metalTextureId),
      "location": 0  // For compatibility with Android
    ]
  }
  
  private func setupOpenGLResources(for textureId: Int64) {
    guard let textureInfo = textures[textureId],
          let glesLib = glesHandle else {
      NSLog("Failed to setup OpenGL resources - missing texture or GLES library")
      return
    }
    
    // Make EGL context current
    if eglContext != nil && eglDisplay != nil && eglSurface != nil {
      eglMakeCurrent?(eglDisplay!, eglSurface!, eglSurface!, eglContext!)
    }
    
    // Bind functions from OpenGL ES
    typealias GLGenFramebuffersFunc = @convention(c) (Int32, UnsafeMutablePointer<UInt32>?) -> Void
    typealias GLGenRenderbuffersFunc = @convention(c) (Int32, UnsafeMutablePointer<UInt32>?) -> Void
    typealias GLBindFramebufferFunc = @convention(c) (UInt32, UInt32) -> Void
    typealias GLBindRenderbufferFunc = @convention(c) (UInt32, UInt32) -> Void
    typealias GLRenderbufferStorageFunc = @convention(c) (UInt32, UInt32, Int32, Int32) -> Void
    typealias GLFramebufferRenderbufferFunc = @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Void
    typealias GLCheckFramebufferStatusFunc = @convention(c) (UInt32) -> UInt32
    typealias GLGetErrorFunc = @convention(c) () -> UInt32
    
    guard let glGenFramebuffers: GLGenFramebuffersFunc = dlsym(glesLib, "glGenFramebuffers").map({ unsafeBitCast($0, to: GLGenFramebuffersFunc.self) }),
          let glGenRenderbuffers: GLGenRenderbuffersFunc = dlsym(glesLib, "glGenRenderbuffers").map({ unsafeBitCast($0, to: GLGenRenderbuffersFunc.self) }),
          let glBindFramebuffer: GLBindFramebufferFunc = dlsym(glesLib, "glBindFramebuffer").map({ unsafeBitCast($0, to: GLBindFramebufferFunc.self) }),
          let glBindRenderbuffer: GLBindRenderbufferFunc = dlsym(glesLib, "glBindRenderbuffer").map({ unsafeBitCast($0, to: GLBindRenderbufferFunc.self) }),
          let glRenderbufferStorage: GLRenderbufferStorageFunc = dlsym(glesLib, "glRenderbufferStorage").map({ unsafeBitCast($0, to: GLRenderbufferStorageFunc.self) }),
          let glFramebufferRenderbuffer: GLFramebufferRenderbufferFunc = dlsym(glesLib, "glFramebufferRenderbuffer").map({ unsafeBitCast($0, to: GLFramebufferRenderbufferFunc.self) }),
          let glCheckFramebufferStatus: GLCheckFramebufferStatusFunc = dlsym(glesLib, "glCheckFramebufferStatus").map({ unsafeBitCast($0, to: GLCheckFramebufferStatusFunc.self) }),
          let glGetError: GLGetErrorFunc = dlsym(glesLib, "glGetError").map({ unsafeBitCast($0, to: GLGetErrorFunc.self) }) else {
      NSLog("Failed to get required GLES function pointers")
      return
    }
    
    // Create framebuffer
    var fbo: UInt32 = 0
    glGenFramebuffers(1, &fbo)
    glBindFramebuffer(GL_FRAMEBUFFER, fbo)
    
    // Create color renderbuffer
    var rbo: UInt32 = 0
    glGenRenderbuffers(1, &rbo)
    glBindRenderbuffer(GL_RENDERBUFFER, rbo)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, Int32(textureInfo.width), Int32(textureInfo.height))
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rbo)
    
    // Create depth renderbuffer
    var depthRbo: UInt32 = 0
    glGenRenderbuffers(1, &depthRbo)
    glBindRenderbuffer(GL_RENDERBUFFER, depthRbo)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, Int32(textureInfo.width), Int32(textureInfo.height))
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRbo)
    
    // Check framebuffer status
    let status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
    if status != GL_FRAMEBUFFER_COMPLETE {
      NSLog("Framebuffer incomplete: \(status)")
    } else {
      NSLog("Framebuffer complete")
    }
    
    // Check for GL errors
    let error = glGetError()
    if error != 0 {
      NSLog("GL error during framebuffer setup: \(error)")
    }
    
    // Update the texture info with the OpenGL IDs
    var updatedInfo = textureInfo
    updatedInfo.fboId = fbo
    updatedInfo.rboId = rbo
    textures[textureId] = updatedInfo
  }
  
  private func updateTexture(textureId: Int64) -> Bool {
    guard let textureInfo = textures[textureId],
          let glesLib = glesHandle else {
      NSLog("Failed to update texture - missing texture or GLES library")
      return false
    }
    
    // Make EGL context current
    if eglContext != nil && eglDisplay != nil && eglSurface != nil {
      eglMakeCurrent?(eglDisplay!, eglSurface!, eglSurface!, eglContext!)
    }
    
    // Bind the texture's framebuffer
    typealias GLBindFramebufferFunc = @convention(c) (UInt32, UInt32) -> Void
    typealias GLReadPixelsFunc = @convention(c) (Int32, Int32, Int32, Int32, UInt32, UInt32, UnsafeMutableRawPointer?) -> Void
    typealias GLGetIntegervFunc = @convention(c) (UInt32, UnsafeMutablePointer<Int32>?) -> Void
    typealias GLFlushFunc = @convention(c) () -> Void
    typealias GLFinishFunc = @convention(c) () -> Void
    typealias GLGetErrorFunc = @convention(c) () -> UInt32
    
    guard let glBindFramebuffer: GLBindFramebufferFunc = dlsym(glesLib, "glBindFramebuffer").map({ unsafeBitCast($0, to: GLBindFramebufferFunc.self) }),
          let glReadPixels: GLReadPixelsFunc = dlsym(glesLib, "glReadPixels").map({ unsafeBitCast($0, to: GLReadPixelsFunc.self) }),
          let glGetIntegerv: GLGetIntegervFunc = dlsym(glesLib, "glGetIntegerv").map({ unsafeBitCast($0, to: GLGetIntegervFunc.self) }),
          let glFlush: GLFlushFunc = dlsym(glesLib, "glFlush").map({ unsafeBitCast($0, to: GLFlushFunc.self) }),
          let glFinish: GLFinishFunc = dlsym(glesLib, "glFinish").map({ unsafeBitCast($0, to: GLFinishFunc.self) }),
          let glGetError: GLGetErrorFunc = dlsym(glesLib, "glGetError").map({ unsafeBitCast($0, to: GLGetErrorFunc.self) }) else {
      NSLog("Failed to get required GLES function pointers")
      return false
    }
    
    // OpenGL constants
    let GL_FRAMEBUFFER: UInt32 = 0x8D40
    let GL_RGBA: UInt32 = 0x1908
    let GL_BGRA: UInt32 = 0x80E1 // Use GL_BGRA instead of GL_RGBA to match CVPixelBuffer format
    let GL_UNSIGNED_BYTE: UInt32 = 0x1401
    let GL_READ_FRAMEBUFFER: UInt32 = 0x8CA8
    
    // Ensure we're reading from the correct framebuffer
    glBindFramebuffer(GL_READ_FRAMEBUFFER, textureInfo.fboId)
    
    // Make sure all previous GL commands are completed
    glFinish()
    
    // Copy the framebuffer content to the CVPixelBuffer
    CVPixelBufferLockBaseAddress(textureInfo.pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    let width = textureInfo.width
    let height = textureInfo.height
    let pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(textureInfo.pixelBuffer)
    
    // Actually read the pixels from framebuffer to memory
    // Use GL_BGRA instead of GL_RGBA to match macOS CVPixelBuffer format (kCVPixelFormatType_32BGRA)
    glReadPixels(0, 0, Int32(width), Int32(height), GL_BGRA, GL_UNSIGNED_BYTE, pixelBufferBaseAddress)
    
    // Check for GL errors
    let error = glGetError()
    if error != 0 {
      NSLog("GL error during readPixels: \(error)")
    } else {
      NSLog("Successfully copied framebuffer to CVPixelBuffer")
    }
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(textureInfo.pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    // Ensure all commands are submitted
    glFlush()
    
    // Mark the texture as needing update
    currentTextureId = textureId
    textureRegistry?.textureFrameAvailable(textureId)
    return true
  }
  
  private func deleteTexture(textureId: Int64) {
    guard let textureRegistry = textureRegistry,
          let textureInfo = textures[textureId],
          let glesLib = glesHandle else {
      return
    }
    
    // Make EGL context current
    if eglContext != nil && eglDisplay != nil && eglSurface != nil {
      eglMakeCurrent?(eglDisplay!, eglSurface!, eglSurface!, eglContext!)
    }
    
    // Bind functions from OpenGL ES
    typealias GLDeleteFramebuffersFunc = @convention(c) (Int32, UnsafePointer<UInt32>?) -> Void
    typealias GLDeleteRenderbuffersFunc = @convention(c) (Int32, UnsafePointer<UInt32>?) -> Void
    
    guard let glDeleteFramebuffers: GLDeleteFramebuffersFunc = dlsym(glesLib, "glDeleteFramebuffers").map({ unsafeBitCast($0, to: GLDeleteFramebuffersFunc.self) }),
          let glDeleteRenderbuffers: GLDeleteRenderbuffersFunc = dlsym(glesLib, "glDeleteRenderbuffers").map({ unsafeBitCast($0, to: GLDeleteRenderbuffersFunc.self) }) else {
      NSLog("Failed to get required GLES function pointers for deleting resources")
      return
    }
    
    // Delete framebuffer and renderbuffer
    var fbo = textureInfo.fboId
    var rbo = textureInfo.rboId
    
    if fbo != 0 {
      glDeleteFramebuffers(1, &fbo)
    }
    
    if rbo != 0 {
      glDeleteRenderbuffers(1, &rbo)
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
  deinit {
    // Delete all textures
    for textureId in textures.keys {
      deleteTexture(textureId: textureId)
    }
    
    // Clean up EGL
    if let eglHandle = eglHandle, 
       let eglDisplay = eglDisplay, 
       let eglContext = eglContext,
       let eglSurface = eglSurface {
      
      // Get EGL cleanup functions
      typealias EGLTerminateFunc = @convention(c) (UnsafeMutableRawPointer?) -> UInt32
      typealias EGLMakeCurrentFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> UInt32
      typealias EGLDestroyContextFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> UInt32
      typealias EGLDestroySurfaceFunc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> UInt32
      
      if let eglMakeCurrent: EGLMakeCurrentFunc = dlsym(eglHandle, "eglMakeCurrent").map({ unsafeBitCast($0, to: EGLMakeCurrentFunc.self) }),
         let eglDestroySurface: EGLDestroySurfaceFunc = dlsym(eglHandle, "eglDestroySurface").map({ unsafeBitCast($0, to: EGLDestroySurfaceFunc.self) }),
         let eglDestroyContext: EGLDestroyContextFunc = dlsym(eglHandle, "eglDestroyContext").map({ unsafeBitCast($0, to: EGLDestroyContextFunc.self) }),
         let eglTerminate: EGLTerminateFunc = dlsym(eglHandle, "eglTerminate").map({ unsafeBitCast($0, to: EGLTerminateFunc.self) }) {
        
        let EGL_NO_SURFACE = UnsafeMutableRawPointer(bitPattern: 0)
        let EGL_NO_CONTEXT = UnsafeMutableRawPointer(bitPattern: 0)
        
        // Release EGL resources
        let makeCurrent = eglMakeCurrent(eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)
        if makeCurrent == 0 {
          NSLog("Failed to make EGL_NO_CONTEXT current during cleanup")
        }
        
        let destroySurface = eglDestroySurface(eglDisplay, eglSurface)
        if destroySurface == 0 {
          NSLog("Failed to destroy EGL surface during cleanup")
        }
        
        let destroyContext = eglDestroyContext(eglDisplay, eglContext)
        if destroyContext == 0 {
          NSLog("Failed to destroy EGL context during cleanup")
        }
        
        let terminate = eglTerminate(eglDisplay)
        if terminate == 0 {
          NSLog("Failed to terminate EGL during cleanup")
        }
      }
    }
    
    // Close dynamic libraries
    if let eglHandle = eglHandle {
      dlclose(eglHandle)
    }
    
    if let glesHandle = glesHandle {
      dlclose(glesHandle)
    }
  }
}
