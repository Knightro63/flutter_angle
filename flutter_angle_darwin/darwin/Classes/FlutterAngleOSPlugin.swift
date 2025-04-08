#if os(macOS)
import FlutterMacOS
#elseif os(iOS)
import Flutter
#endif

import IOSurface

@objc public class FlutterAngleOSPlugin: NSObject, FlutterTexture{
    private var textureRegistry: FlutterTextureRegistry?
    private var pixelBuffer: CVPixelBuffer?

    private var textures: IOSurfaceRef?
    private var textureToPixelBuffer: CVPixelBuffer?

    private var width: Int = 0
    private var height: Int = 0

    public var textureId: Int64 = -1;
    
    init(textureRegistry: FlutterTextureRegistry?){
        self.textureRegistry = textureRegistry;
        super.init();
        // Register with Flutter texture registry
        self.textureId = textureRegistry?.register(self) ?? -1
        print("Created Texture ID: \(self.textureId)")
    }
    
    public func textureFrameAvailable(result: @escaping FlutterResult) {
        guard textures != nil else {
            result(FlutterError(code: "INVALID_TEXTURE_ID", message: "Unknown texture ID", details: nil))
            return
        }
        
        // Notify the Flutter texture registry that a new frame is available
        textureRegistry?.textureFrameAvailable(self.textureId)
        result(nil)
    }
    
    // MARK: - Texture Creation
    public func createTexture(width: Int, height: Int, result: @escaping FlutterResult) {
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

        // Store in our texture maps
        textures = ioSurface
        if let pixBuffer = pixBuffer {
            textureToPixelBuffer = pixBuffer
        }

        // Convert the pointer to UInt64 for safe passage through Flutter codec
        let surfacePointer = UInt64(bitPattern: Int64(Int(bitPattern: Unmanaged.passUnretained(ioSurface!).toOpaque())))
        print("IOSurface pointer as UInt64: \(surfacePointer)")
        
        result(["textureId": textureId, "surfacePointer": surfacePointer])
    }
    
    public func disposeTexture(textureId: Int64) {
        if let tr = textureRegistry {
            tr.unregisterTexture(textureId)
        }
        
        // Clean up our maps
        textures = nil
        textureToPixelBuffer = nil
    }
    
    // MARK: - IOSurface Access
    public func getIOSurfaceHandle(result: @escaping FlutterResult) {
        guard let surface = textures else {
            result(FlutterError(code: "NO_IOSURFACE", message: "No IOSurface available for this texture ID", details: nil))
            return
        }
        
        // Return the IOSurface ID (not the pointer itself) for safety
        let surfaceID = IOSurfaceGetID(surface)
        result(surfaceID)
    }
    
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
        guard textureToPixelBuffer != nil else {
            return nil
        }
        
        // Return the first available texture's pixel buffer
        // In a more sophisticated implementation, we would track the active texture ID
        if let pixBuffer = textureToPixelBuffer {
            return Unmanaged.passRetained(pixBuffer)
        }  

        return nil
    }
}
