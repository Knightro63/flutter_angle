#ifndef FL_ANGLE_GL_H
#define FL_ANGLE_GL_H

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

G_DECLARE_FINAL_TYPE(
  FlAngleGL,
  fl_angle_gl,
  FL,
  ANGLE_GL,
)

#define FLUTTER_ANGLE_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_angle_plugin_get_type(), \
                              FlutterAnglePlugin))

struct _FlutterAnglePlugin{
  GObject parent_instance;
  FlTextureRegistrar *textureRegistrar = nullptr;
  
  GdkGLContext* context;
  GdkGLContext* dartContext;

  //OpenGLRenderer *render = nullptr;
  std::map<int64_t, std::unique_ptr<OpenGLRenderer>> renderers;
};

#endif // FL_ANGLE_GL_H
