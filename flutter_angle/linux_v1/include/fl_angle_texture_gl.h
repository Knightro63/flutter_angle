#ifndef FL_ANGLE_TEXTURE_H
#define FL_ANGLE_TEXTURE_H

#include <gtk/gtk.h>
#include <glib-object.h>
#include "flutter_angle/flutter_angle_plugin.h"
#include <flutter_linux/flutter_linux.h>

#include  "opengl_renderer.h"

#include <GL/glew.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>

#include <map>
#include <iostream>
#include <memory>
#include <mutex>

G_DECLARE_FINAL_TYPE(
  FlAngleTextureGL,
  fl_angle_texture_gl,
  FL,
  ANGLE_TEXTURE_GL,
  FlPixelBufferTexture
)

struct _FlAngleTextureGL{
  FlPixelBufferTexture parent_instance;
  uint8_t *buffer;
  uint32_t width;
  uint32_t height;
};

typedef std::map<int64_t, std::unique_ptr<OpenglRenderer>> RendererMap;

#define FLUTTER_ANGLE_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_angle_plugin_get_type(), \
                              FlutterAnglePlugin))

struct _FlutterAnglePlugin{
  GObject parent_instance;

  FlTextureRegistrar *textureRegistrar = nullptr;
  FlView *fl_view = nullptr;
  GdkWindow *window = nullptr;
  GdkGLContext* context;
  GdkGLContext* dartContext;
  FlTexture *texture = nullptr;

  OpenglRenderer *render = nullptr;

  RendererMap renderers;
  std::mutex r_mutex;
};

FlAngleTextureGL *fl_angle_texture_gl_new(
  uint32_t width,
  uint32_t height
);

#endif // FL_ANGLE_TEXTURE_H
