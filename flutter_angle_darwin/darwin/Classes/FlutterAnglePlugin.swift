#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif
import IOSurface

@objc public class FlutterAnglePlugin: NSObject, FlutterPlugin, FlutterTexture {
    // Flutter texture-related
    private var textureRegistry: FlutterTextureRegistry?
    private var pixelBuffer: CVPixelBuffer?
    private var width: Int = 0
    private var height: Int = 0
    
    // Texture tracking - map texture IDs to their corresponding IOSurfaces
    private var textures: [Int64: IOSurfaceRef] = [:]
    private var textureToPixelBuffer: [Int64: CVPixelBuffer] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let method = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger())
        let instance = FlutterAnglePlugin()
        instance.textureRegistry = registrar.textures()
        #elseif os(macOS)
        let method = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger)
        let instance = FlutterAnglePlugin()
        instance.textureRegistry = registrar.textures
        #endif

        registrar.addMethodCallDelegate(instance, channel: method)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            
        case "createTexture":
            guard let args = call.arguments as? [String: Any],
                  let width = args["width"] as? Int,
                  let height = args["height"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            createTexture(width: width, height: height, result: result)
            
        case "disposeTexture":
            guard let textureId = call.arguments as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
                return
            }
            disposeTexture(textureId: textureId, result: result)
            
        case "getIOSurfaceHandle":
            guard let textureId = call.arguments as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
                return
            }
            getIOSurfaceHandle(textureId: textureId, result: result)
            
        case "textureFrameAvailable":
            guard let textureId = call.arguments as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid texture ID", details: nil))
                return
            }
            textureFrameAvailable(textureId: textureId, result: result)
            
        case "initOpenGL":
            result("ios dummy initOpenGL completes")
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func textureFrameAvailable(textureId: Int64, result: @escaping FlutterResult) {
        guard textures[textureId] != nil else {
            result(FlutterError(code: "INVALID_TEXTURE_ID", message: "Unknown texture ID", details: nil))
            return
        }
        
        // Notify the Flutter texture registry that a new frame is available
        textureRegistry?.textureFrameAvailable(textureId)
        result(nil)
    }
    
    // MARK: - Texture Creation
    private func createTexture(width: Int, height: Int, result: @escaping FlutterResult) {
        self.width = width
        self.height = height

        // Create IOSurface
        NSLog("Creating texture with physical dimensions: \(width) x \(height)")

        // Configure IOSurface properties
        let pixelFormat = kCVPixelFormatType_32BGRA
        let bytesPerElement = 4
        let bytesPerRow = IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, width * bytesPerElement)
        let totalBytes = IOSurfaceAlignProperty(kIOSurfaceAllocSize, bytesPerRow * height)

        let options: [String: Any] = [
            kIOSurfaceWidth as String: width,
            kIOSurfaceHeight as String: height,
            kIOSurfacePixelFormat as String: pixelFormat,
            kIOSurfaceBytesPerElement as String: bytesPerElement,
            kIOSurfaceBytesPerRow as String: bytesPerRow,
            kIOSurfaceAllocSize as String: totalBytes
        ]

        // Create the IOSurface
        let ioSurface = IOSurfaceCreate(options as CFDictionary)
        if ioSurface == nil {
            result(FlutterError(code: "IOSURFACE_ERROR", message: "Failed to create IOSurface", details: nil))
            return
        }

        print("Created IOSurface: \(width)x\(height)")

        // Create CVPixelBuffer from IOSurface
        var pixBuffer: CVPixelBuffer?
        if !createPixelBufferFromIOSurface(ioSurface!, pixelBuffer: &pixBuffer) {
            result(FlutterError(code: "PIXELBUFFER_ERROR", message: "Failed to create CVPixelBuffer", details: nil))
            return
        }

        // Register with Flutter texture registry
        let textureId = textureRegistry?.register(self) ?? -1
        if textureId == -1 {
            result(FlutterError(code: "TEXTURE_REGISTRATION_ERROR", message: "Failed to register texture", details: nil))
            return
        }

        // Store in our texture maps
        textures[textureId] = ioSurface
        if let pixBuffer = pixBuffer {
            textureToPixelBuffer[textureId] = pixBuffer
        }

        // Convert the pointer to UInt64 for safe passage through Flutter codec
        let surfacePointer = UInt64(bitPattern: Int64(Int(bitPattern: Unmanaged.passUnretained(ioSurface!).toOpaque())))
        print("IOSurface pointer as UInt64: \(surfacePointer)")
        
        result(["textureId": textureId, "surfacePointer": surfacePointer])
    }
    
    private func disposeTexture(textureId: Int64, result: @escaping FlutterResult) {
        if let textureRegistry = textureRegistry {
            textureRegistry.unregisterTexture(textureId)
        }
        
        // Clean up our maps
        textures.removeValue(forKey: textureId)
        textureToPixelBuffer.removeValue(forKey: textureId)
        
        result(nil)
    }
    
    // MARK: - IOSurface Access
    private func getIOSurfaceHandle(textureId: Int64, result: @escaping FlutterResult) {
        guard let surface = textures[textureId] else {
            result(FlutterError(code: "NO_IOSURFACE", message: "No IOSurface available for this texture ID", details: nil))
            return
        }
        
        // Return the IOSurface ID (not the pointer itself) for safety
        let surfaceID = IOSurfaceGetID(surface)
        result(surfaceID)
    }
    
    // MARK: - Pixel Buffer Creation
    private func createPixelBufferFromIOSurface(_ surface: IOSurfaceRef, pixelBuffer: inout CVPixelBuffer?) -> Bool {
        // Fix: Change the type to Unmanaged<CVPixelBuffer>? to match what the function expects
        var unmanagedPixelBuffer: Unmanaged<CVPixelBuffer>?
        let status = CVPixelBufferCreateWithIOSurface(
            kCFAllocatorDefault,
            surface,
            nil,
            &unmanagedPixelBuffer
        )
        
        if status != kCVReturnSuccess {
            print("Failed to create CVPixelBuffer from IOSurface: \(status)")
            return false
        }
        
        guard let unmanagedBuffer = unmanagedPixelBuffer else {
            print("CVPixelBuffer is nil")
            return false
        }
        
        // Take ownership of the buffer created by Core Foundation
        pixelBuffer = unmanagedBuffer.takeRetainedValue()
        return true
    }
    
    // MARK: - FlutterTexture Protocol
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        // In a complex implementation with multiple textures, we'd need a way to know
        // which texture is being requested. For now, we'll use a simple approach:
        // Either return the most recently used texture or the first texture in the map
        
        // If we have no textures registered, return nil
        guard !textureToPixelBuffer.isEmpty else {
            return nil
        }
        
        // Return the first available texture's pixel buffer
        // In a more sophisticated implementation, we would track the active texture ID
        if let pixBuffer = textureToPixelBuffer.first?.value {
            return Unmanaged.passRetained(pixBuffer)
        }
        
        return nil
    }
}
