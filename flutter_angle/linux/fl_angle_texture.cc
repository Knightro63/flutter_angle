#include "include/fl_angle_texture.h"

#include <iostream>
G_DEFINE_TYPE(
  FlAngleTexture,
  fl_angle_texture,
  fl_pixel_buffer_texture_get_type()
)

static gboolean fl_angle_texture_copy_pixels(
  FlPixelBufferTexture* texture,
  const uint8_t** out_buffer,
  uint32_t* width,
  uint32_t* height,
  GError **error
){
  // std::cout << "attention: populate called" << std::endl;
  FlAngleTexture* f = (FlAngleTexture*) texture;
  *out_buffer = f->buffer;
  *width = f->width;
  *height = f->height;
  return true;
}

FlAngleTexture *fl_angle_texture_new(
  uint32_t width,
  uint32_t height
){
  auto r = FL_ANGLE_TEXTURE_GL(g_object_new(fl_angle_texture_get_type(), nullptr));
  r->width = width;
  r->height = height;
  r->buffer = static_cast<uint8_t*>(malloc(r->width * r->height * 8));
  return r;
}

static void fl_angle_texture_class_init(FlAngleTextureClass *klass){
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = fl_angle_texture_copy_pixels;
}

static void fl_angle_texture_init(FlAngleTexture *self){}