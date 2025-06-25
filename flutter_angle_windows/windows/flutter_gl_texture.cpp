#include "include/headers/flutter_gl_texture.h"
#include "include/gl32.h"
#include "include/egl.h"
#include "include/eglext_angle.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include "include/headers/opengl_exception.h"
#include "include/headers/flutter_gl_texture.h"

#include <map>
#include <memory>
#include <sstream>
#include <thread>
#include <iostream>

namespace {
    FlutterGLTexture::FlutterGLTexture(flutter::TextureRegistrar* textureRegistrar){
        this->textureRegistrar = textureRegistrar;
        flutterTexture = std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
            [this]() -> const FlutterDesktopPixelBuffer* {
            return copyPixelBuffer();
        }));

        textureId = FlutterAngleWindowsPlugin::textureRegistrar->RegisterTexture(flutterTexture.get());
    }

    static EGLInfo FlutterGLTexture::initOpenGL(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result){
        auto display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        EGLint major;
        EGLint minor;
        auto initializeResult = eglInitialize(display,&major,&minor);
        if (initializeResult != 1){
          result->Error("EGL InitError", "eglInit failed");
          return;
        }
  
        std::cerr << "EGL version in native plugin" << major << "." << minor << std::endl;
        
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
        auto chooseConfigResult = eglChooseConfig(display,attribute_list,&config,1,&num_config);
        if (chooseConfigResult != 1){
          result->Error("EGL InitError", "eglChooseConfig failed");
          return;
        }
  
        EGLint configId;
        eglGetConfigAttrib(display,config,EGL_CONFIG_ID,&configId);
  
        const EGLint surfaceAttributes[] = {
          EGL_WIDTH, 16,
          EGL_HEIGHT, 16,
          EGL_NONE
        };
  
        const EGLint contextAttributes[] ={
          EGL_CONTEXT_CLIENT_VERSION,
          3,
          EGL_NONE
        };
        const EGLContext context = eglCreateContext(display,config,EGL_NO_CONTEXT,contextAttributes);
  
        // This is just a dummy surface that it needed to make an OpenGL context current (bind it to this thread)
        auto dummySurface = eglCreatePbufferSurface(display, config, surfaceAttributes);
        auto dummySurfaceForDartSide = eglCreatePbufferSurface(display, config, surfaceAttributes);
        
        eglMakeCurrent(display, dummySurface, dummySurface, context);
  
        auto v = glGetString(GL_VENDOR);
        int error = glGetError();
        if (error != GL_NO_ERROR){
          std::cerr << "GlError" << error << std::endl;
        }    
        auto r = glGetString(GL_RENDERER);
        auto v2 = glGetString(GL_VERSION);
  
        std::cerr << v << std::endl << r << std::endl << v2 << std::endl;
  
        /// we send back the context so that the Dart side can create a linked context. 
        auto response = flutter::EncodableValue(flutter::EncodableMap{
          {flutter::EncodableValue("context"),
          flutter::EncodableValue((int64_t) context)},
          {flutter::EncodableValue("dummySurface"),
          flutter::EncodableValue((int64_t) dummySurfaceForDartSide)},
          {flutter::EncodableValue("eglConfigId"),
          flutter::EncodableValue((int64_t) configId)}
        });
        result->Success(response);

        EGLInfo returnInfo;
        returnInfo.eglDisplay = display;
        returnInfo.eglContext = context;
        returnInfo.eglSurface = dummySurface;

        return returnInfo;
    }
    void FlutterGLTexture::setInfo(EGLInfo info) {
        eglInfo.eglDisplay = info.eglDisplay;
        eglInfo.eglContext = info.eglContext;
        eglInfo.eglSurface = info.eglSurface;
    }

    void FlutterGLTexture::createTexture(GLsizei width, GLsizei height, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result){
        this->width = width;
        this->height = height;
        pixelBuffer = std::make_unique<FlutterDesktopPixelBuffer>();
        changeSize(width,height);
        createD3DTextureFromPixBuffer(width, height);
        setupOpenGLResources(textures.wTextureId == nullptr);

        auto response = flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("textureId"),
            flutter::EncodableValue(textureId)},
            {flutter::EncodableValue("rbo"),
            flutter::EncodableValue((int64_t)textures->rbo)},
            {flutter::EncodableValue("d3dAsGLTexture"),
                flutter::EncodableValue(textures.wTextureId)},
            {flutter::EncodableValue("location"),
            flutter::EncodableValue(0)}
        });

        result->Success(response);
    }

    void FlutterGLTexture::createD3DTextureFromPixBuffer(int width, int height){
        D3D11_TEXTURE2D_DESC texDesc = {0};
        texDesc.Width = width;
        texDesc.Height = height;
        texDesc.MipLevels = 1;
        texDesc.ArraySize = 1;
        texDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
        texDesc.SampleDesc.Count = 1;
        texDesc.SampleDesc.Quality = 0;
        texDesc.Usage = D3D11_USAGE_DEFAULT;
        texDesc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
        texDesc.CPUAccessFlags = 0;
        texDesc.MiscFlags = 0;
        
        D3D11_SUBRESOURCE_DATA initData = {};
        initData.pSysMem = pixelBuffer; // Pointer to your pixel data
        initData.SysMemPitch = rowPitch; // Calculate row pitch based on format and width
        initData.SysMemSlicePitch = 0; // Not needed for 2D textures
        
        ID3D11Texture2D* dTexture;
        HRESULT hr = d3dDevice->CreateTexture2D(&texDesc, &initData, &dTexture);
        
        if (!SUCCEEDED(hr)) {
            std::cerr << "Error creating ID3D11Texture2D" << std::endl;
        }

       // Call the function//EGL_NO_CONTEXT
       auto eglImage = eglCreateImageKHR(eglInfo.eglDisplay, nullptr, EGL_ANGLE_d3d_texture_client_buffer, (EGLClientBuffer)dTexture, nullptr);
       
       glGenTextures(1, &textures.wTextureId)
       glBindTexture(GLenum(GL_TEXTURE_2D), textures.wTextureId)
       
       PFNGLEGLIMAGETARGETTEXTURE2DOESPROC glEGLImageTargetTexture2DOES = (PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)eglGetProcAddress("glEGLImageTargetTexture2DOES");
       glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, eglImage);
    }

    void FlutterGLTexture::setupOpenGLResources(bool useRenderBuf){
        uint32_t fbo;
        glGenFramebuffers(1, &fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);

        uint32_t rbo;
        if(useRenderBuf){
            glGenRenderbuffers(1, &rbo);
            glBindRenderbuffer(GL_RENDERBUFFER, rbo);  

            glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
            auto error = glGetError();
            if (error != GL_NO_ERROR){
                std::cerr << "GlError while allocating Renderbuffer" << error << std::endl;
                throw new OpenGLException("GlError while allocating Renderbuffer", error);
            }
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER,rbo);
        }

        auto frameBufferCheck = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE){
            std::cerr << "Framebuffer error" << frameBufferCheck << std::endl;
            throw new OpenGLException("Framebuffer Error while creating Texture", frameBufferCheck);
        }

        error = glGetError();
        if( error != GL_NO_ERROR){
            std::cerr << "GlError" << error << std::endl;
        }

        textures.fboId = fbo;
        textures.rboId = rbo;
    }

    void FlutterGLTexture::textureFrameAvailable(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result){
        if (textures.wTextureId == nullptr) {
            glBindFramebuffer(GL_FRAMEBUFFER, textures.fboId)
            glReadPixels(0, 0, (GLsizei)pixelBuffer->width, (GLsizei)pixelBuffer->height, GL_RGBA, GL_UNSIGNED_BYTE, (void*)pixelBuffer->buffer);
        }
        
        textureRegistrar->MarkTextureFrameAvailable(textureId);
        result->Success();
    }

    FlutterGLTexture::~FlutterGLTexture() {
        FlutterAngleWindowsPlugin::textureRegistrar->UnregisterTexture(flutterTextureId);
        glDeleteRenderbuffers(1, &textures.rboId);
        glDeleteFramebuffers(1, &textures.fboId);
        pixels.reset();
        pixelBuffer.reset();
    }

    const FlutterDesktopPixelBuffer *FlutterGLTexture::copyPixelBuffer(){
        return pixelBuffer.get();
    }

    void FlutterGLTexture::changeSize(GLsizei width, GLsizei height){
        int64_t size = width * height * 4;
        pixels.reset(new uint8_t[size]);

        pixelBuffer->buffer = pixels.get();
        pixelBuffer->width = width;
        pixelBuffer->height = height;
        memset(pixels.get(), 0x00, size);
    }
}