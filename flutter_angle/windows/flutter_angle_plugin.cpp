#define EGL_EGLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES
#define EGL_ANGLE_image_d3d11_texture

#include "include/flutter_angle/flutter_angle_plugin.h"
#include "include/gl32.h"
#include "include/gl2ext.h"
#include "include/egl.h"
#include "include/eglext.h"
#include "include/eglext_angle.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <d3d.h>
#include <d3d11.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>
#include <thread>
#include <iostream>

namespace {
using flutter::EncodableMap;
using flutter::EncodableValue;

  class OpenGLException
  {
  public:
      OpenGLException(char* message, int error);
      GLint error = 0;
      char* message ="";
  };

  OpenGLException::OpenGLException(char* message, int error)
  {
      this->error = error;
      message = message;
  }

  class FlutterGLTexture;

  typedef  std::map<int64_t, std::unique_ptr<FlutterGLTexture>> TextureMap;

  class FlutterAnglePlugin : public flutter::Plugin {
  public:
      static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

      FlutterAnglePlugin(flutter::TextureRegistrar* textures);

      virtual ~FlutterAnglePlugin();

      static flutter::TextureRegistrar* textureRegistrar;


  private:
      // Called when a method is called on this plugin's channel from Dart.
      void HandleMethodCall(
          const flutter::MethodCall<flutter::EncodableValue>& method_call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

      TextureMap flutterGLTextures; // stores all created Textures
      EGLDisplay eglDisplay;
  };

  flutter::TextureRegistrar* FlutterAnglePlugin::textureRegistrar;


  class FlutterGLTexture
  {
  public:
    FlutterGLTexture(GLsizei width, GLsizei height, EGLDisplay display);
    virtual ~FlutterGLTexture();
    const FlutterDesktopPixelBuffer *CopyPixelBuffer(size_t width, size_t height);

   std::unique_ptr<FlutterDesktopPixelBuffer> buffer;
    GLuint fbo;
    GLuint rbo;
    int64_t flutterTextureId;
    GLuint wTextureId = 1;
    HANDLE sharedHandle;
    std::unique_ptr<flutter::TextureVariant> flutterTexture;
  private:
    std::unique_ptr<uint8_t> pixels;
    size_t request_count_ = 0;
  }; 
  
  FlutterGLTexture::FlutterGLTexture(GLsizei width, GLsizei height, EGLDisplay display)
  {
    int64_t size = width * height * 4;

    pixels.reset(new uint8_t[size]);

    buffer = std::make_unique<FlutterDesktopPixelBuffer>();
    buffer->buffer = pixels.get();
    buffer->width = width;
    buffer->height = height;
    memset(pixels.get(), 0x00, size);

    EGLAttrib angleDevice = 0;
    EGLAttrib d3d_device_ptr = 0;
    
    if (eglQueryDisplayAttribEXT(display, EGL_DEVICE_EXT, &angleDevice) != EGL_TRUE){
      std::cerr << "GeglQueryDisplayAttribEXT did not work" << std::endl;
    }
    
    if (eglQueryDeviceAttribEXT((EGLDeviceEXT)angleDevice, EGL_D3D11_DEVICE_ANGLE , &d3d_device_ptr) != EGL_TRUE){
      std::cerr << "eglQueryDeviceAttribEXT did not work" << std::endl;
    }

    std::cerr << "Device IDs:"<< d3d_device_ptr << "," << angleDevice << std::endl;

    ID3D11Device* d3d_device = reinterpret_cast<ID3D11Device*>(d3d_device_ptr);

    D3D11_TEXTURE2D_DESC texDesc = {};
    texDesc.Width = width;
    texDesc.Height = height;
    texDesc.MipLevels = 1;
    texDesc.ArraySize = 1;
    texDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;//DXGI_FORMAT_B8G8R8A8_UNORM
    texDesc.SampleDesc.Count = 1;
    texDesc.SampleDesc.Quality = 0;
    texDesc.Usage = D3D11_USAGE_DEFAULT;
    texDesc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;// 
    texDesc.CPUAccessFlags = 0;///D3D11_CPU_ACCESS_WRITE;
    texDesc.MiscFlags = 0;//D3D11_RESOURCE_MISC_SHARED

    int calculated_stride = width * 4;
    
    D3D11_SUBRESOURCE_DATA initialData = {};
    initialData.pSysMem = buffer->buffer;
    initialData.SysMemPitch = calculated_stride;
    initialData.SysMemSlicePitch = height * calculated_stride; // For 2D texture arrays

    ID3D11Texture2D* d3dTexture;
    d3d_device->CreateTexture2D(&texDesc, nullptr, &d3dTexture);//&initialData
    ComPtr<IDXGIResource> dxgiResource;
    d3dTexture.As(&dxgiResource);
    dxgiResource->GetSharedHandle(&sharedHandle);
    // if (d3dTexture != nullptr) {
    //   // Call the function//EGL_NO_CONTEXT
    //   //auto eglImage = eglCreateImageKHR(display, EGL_NO_CONTEXT, EGL_ANGLE_device_d3d, (EGLClientBuffer)d3dTexture, nullptr);
    //   EGLint attrib_list[] = {
    //       // Add any required attributes (e.g., mipmap level, array slice)
    //       EGL_IMAGE_PRESERVED_KHR, EGL_TRUE, // Optional: ensure image contents are preserved
    //       EGL_NONE // Terminate the attribute list
    //   };

    //   EGLImageKHR eglImage = eglCreateImageKHR(
    //       display,
    //       EGL_NO_CONTEXT,
    //       0x3484, // <-- Use the correct ANGLE target//EGL_D3D11_TEXTURE_ANGLE
    //       (EGLClientBuffer)d3dTexture,
    //       attrib_list
    //   );
    //   glGenTextures(1, &wTextureId);
    //   glBindTexture(GL_TEXTURE_2D, wTextureId);
      
    //   //PFNGLEGLIMAGETARGETTEXTURE2DOESPROC glEGLImageTargetTexture2DOES = (PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)eglGetProcAddress("glEGLImageTargetTexture2DOES");
    //   glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, eglImage);
    // }

    // std::cerr << "eglImage:"<< wTextureId << std::endl;

    // glGenFramebuffers(1, &fbo);
    // glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    // if(wTextureId == 0){
    //   glGenRenderbuffers(1, &rbo);
    //   glBindRenderbuffer(GL_RENDERBUFFER, rbo);  

    //   glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
    //   auto error = glGetError();
    //   if (error != GL_NO_ERROR)
    //   {
    //       std::cerr << "GlError while allocating Renderbuffer" << error << std::endl;
    //       throw new OpenGLException("GlError while allocating Renderbuffer", error);
    //   }
    //   glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER,rbo);
    // }

    // auto frameBufferCheck = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    // if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE)
    // {
    //     std::cerr << "Framebuffer error" << frameBufferCheck << std::endl;
    //     throw new OpenGLException("Framebuffer Error while creating Texture", frameBufferCheck);
    // }

    // auto error = glGetError() ;
    // if( error != GL_NO_ERROR)
    // {
    //   std::cerr << "GlError" << error << std::endl;
    // }

    if(wTextureId == 0){
      flutterTexture = std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
          [this](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
          return CopyPixelBuffer(width, height);
      }));
    }
    else{
      flutterTexture = std::make_unique<flutter::TextureVariant>(
        flutter::GpuSurfaceTexture(
          kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
          [&](auto, auto) { return texture_.get(); }
        )
      );
    }

    flutterTextureId = FlutterAnglePlugin::textureRegistrar->RegisterTexture(flutterTexture.get());
  }

  const FlutterDesktopPixelBuffer *FlutterGLTexture::CopyPixelBuffer(size_t width, size_t height)
  {
    return buffer.get();
  }

  FlutterGLTexture::~FlutterGLTexture() {
      FlutterAnglePlugin::textureRegistrar->UnregisterTexture(flutterTextureId);
      glDeleteRenderbuffers(1, &rbo);
      glDeleteFramebuffers(1, &fbo);
      pixels.reset();
      buffer.reset();
  }

  // static
  void FlutterAnglePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_angle",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterAnglePlugin>(registrar->texture_registrar());

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
    });
    registrar->AddPlugin(std::move(plugin));
  }

  FlutterAnglePlugin::FlutterAnglePlugin(flutter::TextureRegistrar *textures)  {
      textureRegistrar = textures;
  }

  FlutterAnglePlugin::~FlutterAnglePlugin() {}


  void FlutterAnglePlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());
    
    if (method_call.method_name().compare("getPlatformVersion") == 0) {
      std::ostringstream version_stream;
      version_stream << "Windows ";
      if (IsWindows10OrGreater()) {
        version_stream << "10+";
      } else if (IsWindows8OrGreater()) {
        version_stream << "8";
      } else if (IsWindows7OrGreater()) {
        version_stream << "7";
      }
      result->Success(flutter::EncodableValue(version_stream.str()));
    }
    else if (method_call.method_name().compare("initOpenGL") == 0) 
    {
        result->Success();
        return;

        auto display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        EGLint major;
        EGLint minor;
        auto initializeResult = eglInitialize(display,&major,&minor);
        if (initializeResult != 1)
        {
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
        if (chooseConfigResult != 1)
        {
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
        if (error != GL_NO_ERROR)
        {
            std::cerr << "GlError" << error << std::endl;
        }     auto r = glGetString(GL_RENDERER);
        auto v2 = glGetString(GL_VERSION);

        std::cerr << v << std::endl << r << std::endl << v2 << std::endl;
        eglDisplay = display;
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
        return;
    }
    else if (method_call.method_name().compare("createTexture") == 0) {
        int width = 0;
        int height = 0;
        if (arguments) {
            auto texture_width = arguments->find(EncodableValue("width"));
            if (texture_width != arguments->end()) {
                width = std::get<std::int32_t>(texture_width->second);
            }
            else
            {
              result->Error("no texture width","no texture width");
              return;
            }
            auto texture_height = arguments->find(EncodableValue("height"));
            if (texture_height != arguments->end()) {
                height = std::get<std::int32_t>(texture_height->second);
            }
            else
            {
              result->Error("no texture height","no texture height");
              return;
            }
        }
        else
        {
          result->Error("no texture texture height and width","no texture width and height");
          return;
        }

        std::unique_ptr<FlutterGLTexture> flutterGLTexture;

        try
        {
            flutterGLTexture = std::make_unique<FlutterGLTexture>(width, height, eglDisplay);
        }
        catch (OpenGLException ex)
        {
            result->Error(ex.message + ':' + std::to_string(ex.error));
        }
        auto rbo = (int64_t)flutterGLTexture->rbo;
        auto d3id = (int64_t)flutterGLTexture->wTextureId;

        auto response = flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("textureId"),
            flutter::EncodableValue(flutterGLTexture->flutterTextureId)},
            // {flutter::EncodableValue("rbo"),
            // flutter::EncodableValue( rbo)},
            {flutter::EncodableValue("surfacePointer"),
            flutter::EncodableValue(sharedHandle)}
            }
        );

        flutterGLTextures.insert(TextureMap::value_type(flutterGLTexture->flutterTextureId, std::move(flutterGLTexture)));
            
        result->Success(response);
        std::cerr << "Created a new texture " << width << "x" << height << "openGL ID" << rbo << std::endl;
    }
    else if (method_call.method_name().compare("updateTexture") == 0) {
      int64_t textureId =0;
      if (arguments) {
          auto findResult = arguments->find(EncodableValue("textureId"));
          if (findResult != arguments->end()) {
              textureId = std::get<std::int64_t>(findResult->second);
          }
      }
      else
      {
        result->Error("no texture id","no texture id");
        return;
      }

      // Check if the received ID is registered
      if (flutterGLTextures.find(textureId) == flutterGLTextures.end())
      {
        result->Error("Invalid texture ID", "Invalid Texture ID: " + std::to_string(textureId));
        return;
      }

      auto currentTexture = flutterGLTextures[textureId].get();
      
      if(currentTexture->wTextureId == 0){
        glBindFramebuffer(GL_FRAMEBUFFER, currentTexture->fbo);
        glReadPixels(0, 0, (GLsizei)currentTexture->buffer->width, (GLsizei)currentTexture->buffer->height, GL_RGBA, GL_UNSIGNED_BYTE, (void*)currentTexture->buffer->buffer);
      }
      
      textureRegistrar->MarkTextureFrameAvailable(textureId);

      result->Success();
    }
    else if (method_call.method_name().compare("textureFrameAvailable") == 0) {
        int64_t textureId =0;
        if (arguments) {
            auto findResult = arguments->find(EncodableValue("textureId"));
            if (findResult != arguments->end()) {
                textureId = std::get<std::int64_t>(findResult->second);
            }
        }
        else
        {
          result->Error("no texture id","no texture id");
          return;
        }
        
        textureRegistrar->MarkTextureFrameAvailable(textureId);

        result->Success();
    }
    else if (method_call.method_name().compare("deleteTexture") == 0) {
    int64_t textureId = 0;
    if (arguments) {
        auto id_iterator = arguments->find(EncodableValue("textureId"));
        if (id_iterator != arguments->end()) {
            textureId = std::get<std::int64_t>(id_iterator->second);
        }
    }
    else
    {
        result->Error("no texture id", "no texture id");
        return;
    }

    auto findResult = flutterGLTextures.find(textureId);
    // Check if the received ID is registered
    if ( findResult == flutterGLTextures.end())
    {
        result->Error("Invalid texture ID", "Invalid Texture ID: " + std::to_string(textureId));
        return;
    }

    flutterGLTextures[textureId].release();
    flutterGLTextures.erase(textureId);

    result->Success();
    }
    else {
      result->NotImplemented();
    }
  }
}

void FlutterAnglePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FlutterAnglePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

