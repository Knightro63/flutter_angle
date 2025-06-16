#include "include/egl_info.h"

// https://github.com/lattice0/external_texture_flutter_linux/tree/master/external_texture/linux

#include <iostream>
G_DEFINE_TYPE(
  EGLInfo,
  egl_info,
  egl_info_get_type()
)

static gboolean egl_info_populate(
  uint64_t *eglDisplay,
  uint64_t *eglContext,
  uint64_t *eglSurface,
  GError **error
){
  // std::cout << "attention: populate called" << std::endl;
  *eglDisplay = f->eglDisplay;
  *eglContext = f->eglContext;
  *eglSurface = f->eglSurface;
  return true;
}

EGLInfo *egl_info_new(
  uint32_t eglDisplay,
  uint32_t eglContext,
  uint32_t eglSurface,
){
  auto r = EGL_INFO(g_object_new(egl_info_get_type(), nullptr));
  r->eglDisplay = eglDisplay;
  r->eglContext = eglContext;
  r->eglSurface = eglSurface;
  return r;
}

static void egl_info_class_init(EGLInfoClass *klass){
  EGL_INFO_CLASS(klass)->populate = egl_info_populate;
}

static void egl_info_init(EGLInfo *self){}