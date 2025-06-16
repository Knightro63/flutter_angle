#ifndef FLUTTER_ANGLE_TEXTURE_H
#define FLUTTER_ANGLE_TEXTURE_H

#include <gtk/gtk.h>
#include <glib-object.h>
#include "flutter_angle/flutter_angle_plugin.h"
#include <flutter_linux/flutter_linux.h>

G_DECLARE_FINAL_TYPE(
    FlutterTextureGL,
    flutter_texture_gl,
    FL,
    ANGLE_TEXTURE_GL,
    FlPixelBufferTexture
)

typedef std::map<int64_t, std::unique_ptr<FlPixelBufferTexture>> TextureMap;

struct _FlutterTextureGL{
    FlPixelBufferTexture parent_instance;
    uint8_t *buffer;
    uint32_t width;
    uint32_t height;
    uint64_t textureId;
    uint32_t rboId;
    uint32_t fboId;
};

FlutterTextureGL *flutter_texture_gl_new(
    uint32_t width,
    uint32_t height,
    uint64_t textureId,
    uint32_t rboId,
    uint32_t fboId
);
#endif // FLUTTER_ANGLE_TEXTURE_H
