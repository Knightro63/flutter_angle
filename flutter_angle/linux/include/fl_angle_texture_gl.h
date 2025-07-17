#ifndef FL_ANGLE_TEXTURE_H
#define FL_ANGLE_TEXTURE_H

#include <gtk/gtk.h>
#include <glib-object.h>
#include "flutter_angle/flutter_angle_plugin.h"
#include <flutter_linux/flutter_linux.h>

#include <map>
#include <iostream>
#include <memory>

G_DECLARE_FINAL_TYPE(
  FlAngleTextureGL,
  fl_angle_texture_gl,
  FL,
  FL_ANGLE_TEXTURE_GL,
  FlAnTex,
  fl_an_tex,
  FlPixelBufferTexture
)

struct _FlAngleTextureGL{
  FlPixelBufferTexture parent_instance;
  uint8_t *buffer;
  uint32_t width;
  uint32_t height;
};

#define FLUTTER_ANGLE_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_angle_plugin_get_type(), \
                              FlutterAnglePlugin))

struct _FlutterAnglePlugin{
  GObject parent_instance;
  GdkGLContext *context = nullptr;
  FlTextureRegistrar *textureRegistrar = nullptr;
  
  FlView *fl_view = nullptr;
  GdkWindow *window = nullptr;

  //g_autoptr(FlTexture) texture; //FlTexture *texture = nullptr;

  EGLDisplay eglDisplay = nullptr;
  EGLSurface eglSurface = nullptr;
  EGLContext eglContext = nullptr;
  EGLConfig  eglConfig = nullptr;

  typedef std::map<int64_t, std::unique_ptr<FlAnTex>> *renders = nullptr;
};

struct FlAnTex{
  FlAngleTextureGL texture;
  int64_t textureId = 0;
  uint32_t rboId;
  uint32_t fboId;

  // EGLDisplay eglDisplay = nullptr;
  // EGLSurface eglSurface = nullptr;
  // EGLContext eglContext = nullptr;
  // EGLConfig  eglConfig = nullptr;
};

FlAnTex *fl_an_tex_new(
  FlAngleTextureGL texture,
  int64_t textureId,
  uint32_t rboId,
  uint32_t frboId
);

FlAngleTextureGL *fl_angle_texture_gl_new(
  uint32_t width,
  uint32_t height
);

#endif // FL_ANGLE_TEXTURE_H
