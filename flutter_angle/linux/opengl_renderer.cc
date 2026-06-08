#include "include/opengl_renderer.h"
#include "include/fl_angle_texture_gl.h"
#include <flutter_linux/fl_texture_registrar.h>

OpenglRenderer::OpenglRenderer(
  FlTextureRegistrar* textureRegistrar, 
  EGLDisplay display, 
  EGLContext context,
  int width, 
  int height
){
  std::cout << "[OpenglRenderer] Creating Headless GPU Renderer..." << std::endl;
  this->textureRegistrar = textureRegistrar;
  this->eglDisplay = display;
  this->eglContext = context;
  this->texId = 0;
  this->textureId = 0;
  this->texture = nullptr;

  changeSize(width, height);
}

FlValue *OpenglRenderer::createTexture() {
  g_autoptr(FlValue) value = fl_value_new_map ();
  fl_value_set_string_take(value, "textureId", fl_value_new_int(textureId));
  fl_value_set_string_take(value, "openglTexture", fl_value_new_int((int64_t)texId));
  return fl_value_ref(value);
}

void OpenglRenderer::changeSize(int width, int height) {
  const int MAX_TEXTURE_SIZE = 8192;
  if (width <= 0 || height <= 0 || width > MAX_TEXTURE_SIZE || height > MAX_TEXTURE_SIZE) {
    return;
  }

  this->width = width;
  this->height = height;

  // 1. Unregister and dispose previous frame assets cleanly
  if (texture != nullptr) {
    fl_texture_registrar_unregister_texture(textureRegistrar, texture);
    texture = nullptr;
    textureId = 0;
  }
  if (texId != 0) {
    glDeleteTextures(1, &texId);
    texId = 0;
  }

  // 💡 THREAD SAFETY FIX: Back up whatever context is currently active on this thread right now
  EGLDisplay prevDisplay = eglGetCurrentDisplay();
  EGLContext prevContext = eglGetCurrentContext();
  EGLSurface prevDraw = eglGetCurrentSurface(EGL_DRAW);
  EGLSurface prevRead = eglGetCurrentSurface(EGL_READ);

  // Make your background context current to generate assets safely
  eglMakeCurrent(eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, eglContext);
  glGenTextures(1, &texId);
  glBindTexture(GL_TEXTURE_2D, texId);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  // 💡 THREAD SAFETY FIX: Put the previous context state right back when done 
  if (prevContext != EGL_NO_CONTEXT && prevDisplay != EGL_NO_DISPLAY) {
    eglMakeCurrent(prevDisplay, prevDraw, prevRead, prevContext);
  } 
  else {
    eglMakeCurrent(eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
  }

  auto ft = fl_angle_texture_gl_new(GL_TEXTURE_2D, texId, width, height);
  std::cerr << "Create Texture" <<std::endl;
  texture = FL_TEXTURE(ft);
  fl_texture_registrar_register_texture(textureRegistrar, texture);
  textureId = fl_texture_get_id(texture);

  std::cerr << "[OpenglRenderer] Pure Shared GL Texture bound successfully. ID: " << texId << std::endl;
}

void OpenglRenderer::updateTexture() {
  if (texture) {
    fl_texture_registrar_mark_texture_frame_available(textureRegistrar, texture);
  }
}

void OpenglRenderer::dispose(bool release_context) {
  std::cout << "[OpenglRenderer] Releasing GPU resources..." << std::endl;

  if (texId != 0) {
    glDeleteTextures(1, &texId);
    texId = 0;
  }

  if (release_context && texture) {
    fl_texture_registrar_unregister_texture(textureRegistrar, texture);
    textureId = 0;
    texture = nullptr;
  }
}

OpenglRenderer::~OpenglRenderer() {
  dispose(true);
}