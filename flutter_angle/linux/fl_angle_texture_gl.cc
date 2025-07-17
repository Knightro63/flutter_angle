#include "include/flutter_texture_gl.h"

// https://github.com/lattice0/external_texture_flutter_linux/tree/master/external_texture/linux

#include <iostream>
G_DEFINE_TYPE(
  FlAngleTextureGL,
  fl_angle_texture_gl,
  FlAnTex,
  fl_an_tex,
  fl_pixel_buffer_texture_get_type()
)

static gboolean fl_angle_texture_gl_copy_pixels(
  FlPixelBufferTexture* texture,
  const uint8_t** out_buffer,
  uint32_t* width,
  uint32_t* height,
  GError **error
){
  // std::cout << "attention: populate called" << std::endl;
  FlAngleTextureGL* f = (FlAngleTextureGL*) texture;
  *out_buffer = f->buffer;
  *width = f->width;
  *height = f->height;
  return true;
}

FlAngleTextureGL *fl_angle_texture_gl_new(
  uint32_t width,
  uint32_t height
){
  auto r = FL_ANGLE_TEXTURE_GL(g_object_new(fl_angle_texture_gl_get_type(), nullptr));
  r->width = width;
  r->height = height;
  r->buffer = static_cast<uint8_t*>(malloc(r->width * r->height * 8));
  return r;
}

FlAnTex *fl_an_tex_new(
  FlAngleTextureGL texture,
  int64_t textureId,
  uint32_t rboId,
  uint32_t frboId
){
  auto r = FLANTEX(g_object_new(fl_an_tex_get_type(), nullptr));
  r->texture = texture;
  r->textureId = textureId;
  r->rboId = rboId;
  r->frboId = frboId;
  return r;
}

static void fl_angle_texture_gl_class_init(FlAngleTextureGLClass *klass){
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = fl_angle_texture_gl_copy_pixels;
}

static void fl_angle_texture_gl_init(FlAngleTextureGL *self){}