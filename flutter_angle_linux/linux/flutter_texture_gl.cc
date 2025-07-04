#include "include/flutter_texture_gl.h"

// https://github.com/lattice0/external_texture_flutter_linux/tree/master/external_texture/linux

#include <iostream>
G_DEFINE_TYPE(
  FlutterTextureGL,
  flutter_texture_gl,
  fl_texture_gl_get_type()
)

static gboolean fl_my_texture_gl_populate(FlTextureGL *texture,
  uint32_t *target,
  uint32_t *name,
  uint32_t *width,
  uint32_t *height,
  GError **error
){
  // std::cout << "attention: populate called" << std::endl;
  FlutterTextureGL* f = (FlutterTextureGL*) texture;
  *target = f->target;
  *name = f->name;
  *width = f->width;
  *height = f->height;
  return true;
}

FlutterTextureGL *flutter_texture_gl_new(
  uint32_t target,
  uint32_t name,
  uint32_t width,
  uint32_t height
){
  auto r = FL_FLUTTER_TEXTURE_GL(g_object_new(flutter_texture_gl_get_type(), nullptr));
  r->target = target;
  r->name = name;
  r->width = width;
  r->height = height;
  return r;
}

static void flutter_texture_gl_class_init(FlutterTextureGLClass *klass){
  FL_TEXTURE_GL_CLASS(klass)->populate = fl_my_texture_gl_populate;
}

static void flutter_texture_gl_init(FlutterTextureGL *self){}