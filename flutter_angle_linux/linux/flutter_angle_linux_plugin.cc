#include "include/flutter_angle_linux/flutter_angle_linux_plugin.h"
#include "include/gl32.h"
#include "include/egl.h"

#include <flutter_linux/flutter_linux.h>
#include <flutter_linux/fl_view.h>
#include <sys/utsname.h>
#include <glib.h>

#include <gtk/gtk.h>
#include <gdk/gdkwayland.h> // For Wayland
#include <gdk/gdkx.h>      // For X11
#include <wayland-egl-interface.h> // For Wayland EGL window creation

#include <map>
#include <memory>
#include <sstream>
#include <thread>
#include <iostream>
#include <cstring>

#include "include/flutter_texture_gl.h"
#include "flutter_angle_linux_plugin_private.h"

G_DEFINE_TYPE(FlutterAngleLinuxPlugin, flutter_angle_linux_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void flutter_angle_linux_plugin_handle_method_call(FlutterAngleLinuxPlugin *self, FlMethodCall *method_call){
  g_autoptr(FlMethodResponse) response = nullptr;

	const gchar *method = fl_method_call_get_name(method_call);
	FlValue *args = fl_method_call_get_args(method_call);

	if (strcmp(method, "getPlatformVersion") == 0) {
		response = get_platform_version();
	} 
	else if (strcmp(method, "initOpenGL") == 0){
    auto display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    EGLint major;
    EGLint minor;
    auto initializeResult = eglInitialize(display,&major,&minor);
    if (initializeResult != 1){
      response = FL_METHOD_RESPONSE(
        fl_method_error_response_new(
          "EGL InitError",
          "glInit failed",
          nullptr
        )
      );
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }
    std::cerr << "EGL version in native plugin " << major << "." << minor << std::endl;
    
    const EGLint attribute_list[] = {
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT_KHR,
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
      response = FL_METHOD_RESPONSE(
        fl_method_error_response_new(
          "EGL InitError", 
          "eglChooseConfig failed",
          nullptr
        )
      );
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    EGLint configId;
    eglGetConfigAttrib(display, config, EGL_CONFIG_ID, &configId);

    const EGLint contextAttributes[] ={
      EGL_CONTEXT_CLIENT_VERSION, 3,
      EGL_NONE
    };
    const EGLContext context = eglCreateContext(display,config,EGL_NO_CONTEXT,contextAttributes);
    if(context == EGL_NO_CONTEXT){
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL InitError", "Failed to create EGL context", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    const EGLint surfaceAttributes[] = {
      EGL_WIDTH, 16,
      EGL_HEIGHT, 16,
      EGL_NONE
    };
    // This is just a dummy surface that it needed to make an OpenGL context current (bind it to this thread)
    auto dummySurface = eglCreatePbufferSurface(display, config, surfaceAttributes);
    if(dummySurface == EGL_NO_SURFACE){
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL InitError", "Failed to create EGL pbuffer surface", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    if(eglMakeCurrent(display, dummySurface, dummySurface, context) == 0){
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL InitError", "eglMakeCurrent failed", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    EGLNativeWindowType native_window = EGL_NO_NATIVE_WINDOW; // Initialize to null/invalid
    GdkWindow *gdk_window = nullptr;
    gdk_window = gtk_widget_get_parent_window(GTK_WIDGET(self->fl_view));

    bool isWylan = false;
    
    if (GDK_IS_WAYLAND_DISPLAY(gdk_window_get_display(gdk_window))) { // Check if Wayland
      struct wl_surface* wayland_surface = gdk_wayland_window_get_wl_surface(gdk_window); // Get Wayland surface from GdkWindow
      native_window = (EGLNativeWindowType)wl_egl_window_create(wayland_surface, gdk_window_get_width(gdk_window), gdk_window_get_height(gdk_window)); // Create wl_egl_window
      isWylan = true;
    } 
    else if (GDK_IS_X11_DISPLAY(gdk_window_get_display(gdk_window))) { // Check if X11
      native_window = (EGLNativeWindowType)gdk_x11_window_get_xid(gdk_window); // Get XID
    } 
    else {
      response = FL_METHOD_RESPONSE(
      fl_method_error_response_new("EGL InitError","glInit failed: EGL_NO_NATIVE_WINDOW",nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    const EGLint attribs[] = {EGL_NONE};
    auto eglSurface = eglCreateWindowSurface(display, config, native_window, attribs);
    if(eglSurface == EGL_NO_SURFACE){
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL InitError", "Failed to create EGL pbuffer surface", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    if(isWylan){
      wl_egl_window_destroy();
    }

    g_autoptr(FlValue) value = fl_value_new_map ();
    fl_value_set_string_take(value, "context",     fl_value_new_int ((int64_t)context));
    fl_value_set_string_take(value, "dummySurface",fl_value_new_int ((int64_t)eglSurface));
		
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  }
	else if (strcmp(method, "createTexture") == 0){
    std::cerr << "EGL createTexture" << std::endl;
    int width = 0;
    int height = 0;
    if(args){
      width = fl_value_get_int(fl_value_lookup_string(args, "width"));
      height = fl_value_get_int(fl_value_lookup_string(args, "height"));
      if(!width || !height){
        response = FL_METHOD_RESPONSE(
          fl_method_error_response_new(
            "EGL DeleteError", 
            "Missing with or height.",
            nullptr
          )
        );
        fl_method_call_respond(method_call, response, nullptr);
        return;
      }
    }
    std::cerr << "Window Size:" << width << "," << height << std::endl;

    EGLNativeWindowType native_window = EGL_NO_NATIVE_WINDOW; // Initialize to null/invalid
    GdkWindow *gdk_window = nullptr;
    gdk_window = gtk_widget_get_parent_window(GTK_WIDGET(self->fl_view));

    bool isWylan = false;
    
    if (GDK_IS_WAYLAND_DISPLAY(gdk_window_get_display(gdk_window))) { // Check if Wayland
      struct wl_surface* wayland_surface = gdk_wayland_window_get_wl_surface(gdk_window); // Get Wayland surface from GdkWindow
      native_window = (EGLNativeWindowType)wl_egl_window_create(wayland_surface, gdk_window_get_width(gdk_window), gdk_window_get_height(gdk_window)); // Create wl_egl_window
      isWylan = true;
    } 
    else if (GDK_IS_X11_DISPLAY(gdk_window_get_display(gdk_window))) { // Check if X11
      native_window = (EGLNativeWindowType)gdk_x11_window_get_xid(gdk_window); // Get XID
    } 
    else {
      response = FL_METHOD_RESPONSE(
      fl_method_error_response_new("EGL InitError","glInit failed: EGL_NO_NATIVE_WINDOW",nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    auto ft = flutter_texture_gl_new(width, height);

    std::cerr << "Create Texture" <<std::endl;
    self->texture = FL_TEXTURE(ft);
    fl_texture_registrar_register_texture(self->textureRegistrar, self->texture);
    self->textureId = fl_texture_get_id(self->texture);

    const EGLint attribs[] = {EGL_NONE};
    auto eglSurface = eglCreateWindowSurface(display, config, native_window, attribs);
    if(eglSurface == EGL_NO_SURFACE){
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL InitError", "Failed to create EGL pbuffer surface", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    if(isWylan){
      wl_egl_window_destroy();
    }

    g_autoptr(FlValue) value = fl_value_new_map ();
    fl_value_set_string_take(value, "textureId", fl_value_new_int(self->textureId));
    fl_value_set_string_take(value, "surfacePointer", fl_value_new_int((int64_t)eglSurface));

    self->flutterGLTextures.insert(TextureMap::value_type(self->textureId, std::move(ft)));
		
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
    std::cerr << "Created a new texture " << width << "x" << height << "openGL ID" << ft->rbo << std::endl;
	}
	else if (strcmp(method, "createTexture2") == 0){
    std::cerr << "EGL createTexture" << std::endl;
    int width = 0;
    int height = 0;
    if(args){
      width = fl_value_get_int(fl_value_lookup_string(args, "width"));
      height = fl_value_get_int(fl_value_lookup_string(args, "height"));
      if(!width || !height){
        response = FL_METHOD_RESPONSE(
          fl_method_error_response_new(
            "EGL DeleteError", 
            "Missing with or height.",
            nullptr
          )
        );
        fl_method_call_respond(method_call, response, nullptr);
        return;
      }
    }
    std::cerr << "Window Size:" << width << "," << height << std::endl;


    auto ft = flutter_texture_gl_new(width, height);

    glGenFramebuffers(1, &ft->fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, ft->fbo);

    glGenRenderbuffers(1, &ft->rbo);
    glBindRenderbuffer(GL_RENDERBUFFER, ft->rbo);  

    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
    auto error = glGetError();
    if (error != GL_NO_ERROR){
      std::cerr << "GlError while allocating Renderbuffer" << error << std::endl;
      response = FL_METHOD_RESPONSE(
        fl_method_error_response_new(
          "EGL CreateError", 
          "GlError while allocating Renderbuffer.",
          nullptr
        )
      );
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER,ft->rbo);
    auto frameBufferCheck = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE){
      std::cerr << "Framebuffer error" << frameBufferCheck << std::endl;
      std::cerr << "GlError while allocating Renderbuffer" << error << std::endl;
      response = FL_METHOD_RESPONSE(
        fl_method_error_response_new(
          "EGL CreateError", 
          "Framebuffer Error while creating Texture.",
          nullptr
        )
      );
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    error = glGetError() ;
    if( error != GL_NO_ERROR){
      std::cerr << "GlError" << error << std::endl;
    }
    std::cerr << "Create Texture" <<std::endl;
    self->texture = FL_TEXTURE(ft);
    fl_texture_registrar_register_texture(self->textureRegistrar, self->texture);
    ft->textureId = fl_texture_get_id(self->texture);

    g_autoptr(FlValue) value = fl_value_new_map ();
    fl_value_set_string_take(value, "textureId", fl_value_new_int(ft->textureId));
    fl_value_set_string_take(value, "rbo", fl_value_new_int(ft->rbo));

    self->flutterGLTextures.insert(TextureMap::value_type(ft->textureId, std::move(ft)));
		
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
    std::cerr << "Created a new texture " << width << "x" << height << "openGL ID" << ft->rbo << std::endl;
	}
	else if (strcmp(method, "updateTexture") == 0){
    std::cerr << "EGL updateTexture" << std::endl;
    int64_t textureId = 0;
    if(args){
      textureId = fl_value_get_int(fl_value_lookup_string(args, "textureId"));
      if(!textureId){
        response = FL_METHOD_RESPONSE(
          fl_method_error_response_new(
            "EGL DeleteError", 
            "Missing textureId.",
            nullptr
          )
        );
        fl_method_call_respond(method_call, response, nullptr);
        return;
      }
    }

    auto currentTexture = self->flutterGLTextures[textureId].get();
    glBindFramebuffer(GL_FRAMEBUFFER, currentTexture->fbo);
    glReadPixels(0, 0, (GLsizei)currentTexture->width, (GLsizei)currentTexture->height, GL_RGBA, GL_UNSIGNED_BYTE, (void*)currentTexture->buffer);
        
    fl_texture_registrar_mark_texture_frame_available(self->textureRegistrar, self->texture);
    
    g_autoptr(FlValue) result = fl_value_new_null();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
	}
	else if (strcmp(method, "textureFrameAvailable") == 0){
    std::cerr << "EGL updateTexture" << std::endl;
    int64_t textureId = 0;
    if(args){
      textureId = fl_value_get_int(fl_value_lookup_string(args, "textureId"));
      if(!textureId){
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL DeleteError", "Missing textureId.",nullptr));
        fl_method_call_respond(method_call, response, nullptr);
        return;
      }
    }

    gdk_gl_context_make_current(self->context);
    fl_texture_registrar_mark_texture_frame_available(self->textureRegistrar, self->texture);
    gdk_gl_context_clear_current();

    g_autoptr(FlValue) result = fl_value_new_null();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
	}
	else if (strcmp(method, "resizeTexture") == 0){
    std::cerr << "EGL resizeTexture" << std::endl;
    int width = 0;
    int height = 0;
    int64_t textureId = 0;
    if(args){
      width = fl_value_get_int(fl_value_lookup_string(args, "width"));
      height = fl_value_get_int(fl_value_lookup_string(args, "height"));
      textureId = fl_value_get_int(fl_value_lookup_string(args, "textureId"));
      if(!width || !height){
        response = FL_METHOD_RESPONSE(
        fl_method_error_response_new("EGL DeleteError", "Missing with, height, or textureID.",));
        fl_method_call_respond(method_call, response, nullptr);
        return;
      }
    }
    std::cerr << "Window Size:" << width << "," << height << std::endl;

    g_autoptr(FlValue) result = fl_value_new_null();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
	}
	else if (strcmp(method, "deleteTexture") == 0){
    std::cerr << "EGL deleteTexture" << std::endl;
    int64_t textureId = 0;
    if(args){
      textureId = fl_value_get_int(fl_value_lookup_string(args, "textureId"));
      if(!textureId){
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL DeleteError", "Missing textureId.", nullptr));
        fl_method_call_respond(method_call, response, nullptr);
        return;
      }
    }

    auto findResult = self->flutterGLTextures.find(textureId);
    // Check if the received ID is registered
    if ( findResult == self->flutterGLTextures.end()){
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL DeleteError", "Invalid texture ID.",));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    self->flutterGLTextures[textureId].release();
    self->flutterGLTextures.erase(textureId);

    g_autoptr(FlValue) result = fl_value_new_null();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
	}
	else{
		response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
	}

	fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void flutter_angle_linux_plugin_dispose(GObject *object){
	G_OBJECT_CLASS(flutter_angle_linux_plugin_parent_class)->dispose(object);
}

static void flutter_angle_linux_plugin_class_init(FlutterAngleLinuxPluginClass *klass){
	G_OBJECT_CLASS(klass)->dispose = flutter_angle_linux_plugin_dispose;
}

static void flutter_angle_linux_plugin_init(FlutterAngleLinuxPlugin *self) {}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call, gpointer user_data){
	FlutterAngleLinuxPlugin *plugin = FLUTTER_ANGLE_LINUX_PLUGIN(user_data);
	flutter_angle_linux_plugin_handle_method_call(plugin, method_call);
}

void flutter_angle_linux_plugin_register_with_registrar(FlPluginRegistrar *registrar){
	FlutterAngleLinuxPlugin *plugin = FLUTTER_ANGLE_LINUX_PLUGIN(g_object_new(flutter_angle_linux_plugin_get_type(), nullptr));

	FlView *fl_view = fl_plugin_registrar_get_view(registrar);
	plugin->fl_view = fl_view;
	plugin->textureRegistrar = fl_plugin_registrar_get_texture_registrar(registrar);

	g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
	g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
    fl_plugin_registrar_get_messenger(registrar),
    "flutter_angle",
    FL_METHOD_CODEC(codec)
  );

	fl_method_channel_set_method_call_handler(
		channel,
		method_call_cb,
		g_object_ref(plugin),
		g_object_unref
  );

	g_object_unref(plugin);
}