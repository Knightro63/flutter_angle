#include "include/flutter_angle_windows/flutter_angle_windows_plugin.h"
#include "include/gl32.h"
#include "include/egl.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "include/headers/opengl_exception.h"
#include "include/headers/flutter_gl_texture.h"

#include <map>
#include <memory>
#include <sstream>
#include <thread>
#include <iostream>

namespace {
  using flutter::EncodableMap;
  using flutter::EncodableValue;

  typedef  std::map<int64_t, std::unique_ptr<FlutterGLTexture>> RendererMap;

  class FlutterAngleWindowsPlugin : public flutter::Plugin {
    public:
      static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
      FlutterAngleWindowsPlugin(flutter::TextureRegistrar* textures);
      virtual ~FlutterAngleWindowsPlugin();
      static flutter::TextureRegistrar* textureRegistrar;

    private:
      // Called when a method is called on this plugin's channel from Dart.
      void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      EGLInfo eglInfo;
      RendererMap renderers; // stores all created Textures
  };

  flutter::TextureRegistrar* FlutterAngleWindowsPlugin::textureRegistrar;


  // static
  void FlutterAngleWindowsPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "flutter_angle",
      &flutter::StandardMethodCodec::GetInstance()
    );

    auto plugin = std::make_unique<FlutterAngleWindowsPlugin>(registrar->texture_registrar());

    channel->SetMethodCallHandler([plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
    });
    registrar->AddPlugin(std::move(plugin));
  }

  FlutterAngleWindowsPlugin::FlutterAngleWindowsPlugin(flutter::TextureRegistrar *textures)  {
    textureRegistrar = textures;
  }

  FlutterAngleWindowsPlugin::~FlutterAngleWindowsPlugin() {}

  void FlutterAngleWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
  ) {
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
    else if (method_call.method_name().compare("initOpenGL") == 0) {
      EGLInfo info = FlutterGLTexture::initOpenGL(result);
      eglInfo.eglDisplay = info.eglDisplay;
      eglInfo.eglContext = info.eglContext;
      eglInfo.eglSurface = info.eglSurface;
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
        else{
          result->Error("no texture width","no texture width");
          return;
        }
        auto texture_height = arguments->find(EncodableValue("height"));
        if (texture_height != arguments->end()) {
          height = std::get<std::int32_t>(texture_height->second);
        }
        else{
          result->Error("no texture height","no texture height");
          return;
        }
      }
      else{
        result->Error("no texture texture height and width","no texture width and height");
        return;
      }

      std::unique_ptr<FlutterGLTexture> flutterGLTexture;

      try{
        int64_t textureId;
        
        flutterGLTexture = std::make_unique<FlutterGLTexture>(textureRegistrar);
        textureId = flutterGLTexture->textureId;

        renderers.insert(RendererMap::value_type(textureId, std::move(flutterGLTexture)));

        flutterGLTexture->setInfo(eglInfo);
        flutterGLTexture->createTexture(width, height, result);
      }
      catch (OpenGLException ex){
        result->Error(ex.message + ':' + std::to_string(ex.error));
      }
    }
    else if (method_call.method_name().compare("updateTexture") == 0) {
      int64_t textureId =0;
      if (arguments) {
        auto findResult = arguments->find(EncodableValue("textureId"));
        if (findResult != arguments->end()) {
          textureId = std::get<std::int64_t>(findResult->second);
        }
      }
      else{
        result->Error("no texture id","no texture id");
        return;
      }

      // Check if the received ID is registered
      if (renderers.find(textureId) == renderers.end()){
        result->Error("Invalid texture ID", "Invalid Texture ID: " + std::to_string(textureId));
        return;
      }

      renderers[textureId]->textureFrameAvailable(result);
    }
    else if (method_call.method_name().compare("resizeTexture") == 0) {
      int64_t textureId = 0;
      int width = 0;
      int height = 0;
      if (arguments) {
        auto findResult = arguments->find(EncodableValue("textureId"));
        if (findResult != arguments->end()) {
          textureId = std::get<std::int64_t>(findResult->second);
        }
        auto texture_width = arguments->find(EncodableValue("width"));
        if (texture_width != arguments->end()) {
          width = std::get<std::int32_t>(texture_width->second);
        }
        else{
          result->Error("no texture width","no texture width");
          return;
        }
        auto texture_height = arguments->find(EncodableValue("height"));
        if (texture_height != arguments->end()) {
          height = std::get<std::int32_t>(texture_height->second);
        }
        else{
          result->Error("no texture height","no texture height");
          return;
        }
      }
      else{
        result->Error("no texture id","no texture id");
        return;
      }

      // Check if the received ID is registered
      if (renderers.find(textureId) == renderers.end()){
        result->Error("Invalid texture ID", "Invalid Texture ID: " + std::to_string(textureId));
        return;
      }

      auto currentTexture = renderers[textureId].get();
      currentTexture->changeSize(width,height);

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
      else{
        result->Error("no texture id", "no texture id");
        return;
      }

      auto findResult = renderers.find(textureId);
      // Check if the received ID is registered
      if ( findResult == renderers.end()){
        result->Error("Invalid texture ID", "Invalid Texture ID: " + std::to_string(textureId));
        return;
      }

      renderers[textureId].release();
      renderers.erase(textureId);

      result->Success();
    }
    else {
      result->NotImplemented();
    }
  }
}

void FlutterAngleWindowsPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  FlutterAngleWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar)
  );
}

