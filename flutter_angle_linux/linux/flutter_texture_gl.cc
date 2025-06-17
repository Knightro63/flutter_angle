#include "include/flutter_texture_gl.h"

// https://github.com/lattice0/external_texture_flutter_linux/tree/master/external_texture/linux

#include <iostream>
G_DEFINE_TYPE(
  FlutterTextureGL,
  flutter_texture_gl,
  fl_texture_gl_get_type()
)

static gboolean flutter_texture_gl_copy_pixels(
  FlPixelBufferTexture *texture,
  const uint8_t **buffer,
  uint32_t *width,
  uint32_t *height,
  GError **error
){
  // std::cout << "attention: populate called" << std::endl;
  FlutterTextureGL* f = (FlutterTextureGL*) texture;
  *buffer = f->buffer;
  *width = f->width;
  *height = f->height;
  return true;
}

FlutterTextureGL *flutter_texture_gl_new(
  uint32_t width,
  uint32_t height
){
  auto r = FL_FLUTTER_TEXTURE_GL(g_object_new(flutter_texture_gl_get_type(), nullptr));
  r->width = width;
  r->height = height;
  r->buffer = static_cast<uint8_t*>(malloc(r->width * r->height * 4));
  return r;
}

static void flutter_texture_gl_class_init(FlutterTextureGLClass *klass){
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = flutter_texture_gl_copy_pixels;
}

static void flutter_texture_gl_init(FlutterTextureGL *self){}