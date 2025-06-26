#ifndef FLUTTER_ANGLE_TEXTURE_H
#define FLUTTER_ANGLE_TEXTURE_H

#include <gtk/gtk.h>
#include <glib-object.h>
#include "flutter_angle_linux/flutter_angle_linux_plugin.h"
#include <flutter_linux/flutter_linux.h>

#include <map>
#include <iostream>
#include <memory>

G_DECLARE_FINAL_TYPE(
    FlutterTextureGL,
    flutter_texture_gl,
    FL,
    FLUTTER_TEXTURE_GL,
    FlTextureGL
)

typedef std::map<int64_t, std::unique_ptr<FlutterTextureGL>> TextureMap;

struct _FlutterTextureGL{
    FlTextureGL parent_instance;
    uint32_t target;
    uint32_t name;
    uint32_t width;
    uint32_t height;
};

#define FLUTTER_ANGLE_LINUX_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_angle_linux_plugin_get_type(), \
                              FlutterAngleLinuxPlugin))

struct _FlutterAngleLinuxPlugin{
  GObject parent_instance;
  GdkGLContext *context = nullptr;
  FlTextureRegistrar *textureRegistrar = nullptr;
  TextureMap flutterGLTextures;
  int64_t textureId = 0;
  g_autoptr(FlTexture) texture;
  FlView *fl_view = nullptr;
};

FlMyTextureGL *flutter_texture_gl_new(uint32_t target,
                                    uint32_t name,
                                    uint32_t width,
                                    uint32_t height);

#endif // FLUTTER_ANGLE_TEXTURE_H
