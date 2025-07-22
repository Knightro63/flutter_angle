#ifndef FL_ANGLE_TEXTURE_H
#define FL_ANGLE_TEXTURE_H

#include <gtk/gtk.h>
#include <glib-object.h>
#include "flutter_angle/flutter_angle_plugin.h"
#include <flutter_linux/flutter_linux.h>

#include <GL/glew.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>

#include <map>
#include <iostream>
#include <memory>

G_DECLARE_FINAL_TYPE(
  FlAngleTexture,
  fl_angle_texture,
  FL,
  ANGLE_TEXTURE,
  FlPixelBufferTexture
)

struct _FlAngleTexture{
  FlPixelBufferTexture parent_instance;
  uint8_t *buffer;
  uint32_t width;
  uint32_t height;
};

FlAngleTexture *fl_angle_texture_new(
  uint32_t width,
  uint32_t height
);

#endif // FL_ANGLE_TEXTURE_H
