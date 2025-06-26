#ifndef FLUTTER_GL_TEXTURE_H_
#define FLUTTER_GL_TEXTURE_H_

#include "include/flutter_angle_windows/flutter_angle_windows_plugin.h"
#include "include/gl32.h"
#include "include/egl.h"

#include <d3d.h>
#include <d3d11.h>

#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#if defined(__cplusplus)
extern "C" {
#endif

struct TextureInfo {
    uint32_t rboId = 0;
    uint32_t fboId = 0;
    uint32_t wTextureId = 0;
    int frameCount;
};

struct EGLInfo {
    EGLDisplay eglDisplay;
    EGLContext eglContext;
    EGLSurface eglSurface;
};

class FlutterGLTexture{
    public:
        FlutterGLTexture(flutter::TextureRegistrar* textureRegistrar);
        virtual ~FlutterGLTexture();

        static EGLInfo initOpenGL(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
        void setInfo(EGLInfo info);
        void createTexture(int width, int height,std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
        void changeSize(int width, int height);
        void textureFrameAvailable(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);

        int64_t textureId;

    private:
        void createD3DTextureFromPixBuffer(int width, int height);
        void setupOpenGLResources(bool useRenderBuf);
        const FlutterDesktopPixelBuffer *copyPixelBuffer();
        ID3D11Device* getANGLED3DDevice(EGLDisplay display);

        int width;
        int height;

        std::unique_ptr<uint8_t> pixels;
        EGLInfo eglInfo;
        
        TextureInfo textures;
        std::unique_ptr<FlutterDesktopPixelBuffer> pixelBuffer;
        std::unique_ptr<FlutterDesktopGpuSurfaceDescriptor> gpuTexture;
        flutter::TextureRegistrar* textureRegistrar;

        std::unique_ptr<flutter::TextureVariant> flutterTexture;
};

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_GL_TEXTURE_H_