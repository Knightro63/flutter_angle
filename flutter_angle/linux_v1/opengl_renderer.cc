#include "include/opengl_renderer.h"
#include "include/fl_angle_texture_gl.h"
#include <flutter_linux/fl_pixel_buffer_texture.h>
#include <flutter_linux/fl_texture_registrar.h>

OpenglRenderer::OpenglRenderer(
  FlTextureRegistrar* textureRegistrar,
  GdkGLContext* context,
  GdkGLContext* dartContext,
  int width, 
  int height
){
  this->textureRegistrar = textureRegistrar;
  this->context = context;
  this->dartContext = dartContext;
  this->width = width;
  this->height = height;

  auto ft = fl_angle_texture_gl_new(width, height);
  std::cerr << "Create Texture" <<std::endl;
  texture = FL_TEXTURE(ft);
  fl_texture_registrar_register_texture(textureRegistrar, texture);
  textureId = fl_texture_get_id(texture);

  printf(".... OpenglRenderer create\n");
}

FlValue *OpenglRenderer::createTexture() {
  glGenFramebuffers(1, &fboId);
  glBindFramebuffer(GL_FRAMEBUFFER, fboId);

  glGenRenderbuffers(1, &rboId);
  glBindRenderbuffer(GL_RENDERBUFFER, rboId);  

  glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
  auto error = glGetError();
  if (error != GL_NO_ERROR){
    std::cerr << "GlError while allocating Renderbuffer" << error << std::endl;
    //auto response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL CreateError", "GlError while allocating Renderbuffer.", nullptr));
    //return fl_method_call_respond(method_call, response, nullptr);
  }

  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER,rboId);
  auto frameBufferCheck = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE){
    std::cerr << "Framebuffer error" << frameBufferCheck << std::endl;
    std::cerr << "GlError while allocating Renderbuffer" << error << std::endl;
    //auto response = FL_METHOD_RESPONSE(fl_method_error_response_new("EGL CreateError", "Framebuffer Error while creating Texture.",nullptr));
    //return fl_method_call_respond(method_call, response, nullptr);
  }

  error = glGetError() ;
  if( error != GL_NO_ERROR){
    std::cerr << "GlError" << error << std::endl;
  }

  g_autoptr(FlValue) value = fl_value_new_map ();
  fl_value_set_string_take(value, "textureId", fl_value_new_int(textureId));
  fl_value_set_string_take(value, "rbo", fl_value_new_int(rboId));

	
  return fl_value_ref(value);
}

void OpenglRenderer::changeSize(int width, int height) {
  this->width = width;
  this->height = height;
  angleTexture->width = width;
  angleTexture->height = height;
  angleTexture->buffer = static_cast<uint8_t*>(malloc(width * height * 8));
}

void OpenglRenderer::updateTexture() {
  gdk_gl_context_make_current(context);
  glBindFramebuffer(GLenum(GL_FRAMEBUFFER), fboId);

  glReadPixels(0, 0, (GLsizei)angleTexture->width, (GLsizei)angleTexture->height, GL_RGBA, GL_UNSIGNED_BYTE, angleTexture->buffer);
  fl_texture_registrar_mark_texture_frame_available(textureRegistrar,texture);
}

void OpenglRenderer::dispose() {
  gdk_gl_context_make_current(context);
  glDeleteRenderbuffers(1, &rboId);
  glDeleteFramebuffers(1, &fboId);
  
  rboId = 0;
  fboId = 0;

  g_object_unref(context);
  g_object_unref(dartContext);
}

OpenglRenderer::~OpenglRenderer() {
  dispose();
  std::cerr << "Disposed of and deleted everything." << std::endl;
  fl_texture_registrar_unregister_texture(textureRegistrar,texture);
  g_object_unref(angleTexture);
  textureId = 0;
}

// Move constructor definition
OpenglRenderer::OpenglRenderer(OpenglRenderer&& other) noexcept: 
  textureRegistrar(exchange(other.textureRegistrar, nullptr)), // Transfer ownership and nullify other's pointer
  context(exchange(other.context, nullptr)),
  dartContext(exchange(other.dartContext, nullptr)),
  width(exchange(other.width, 0)), // Simple members can be just exchanged or copied, depending on semantics
  height(exchange(other.height, 0)),
  textureId(exchange(other.textureId, 0)),
  fboId(exchange(other.fboId, 0)),
  rboId(exchange(other.rboId, 0)),
  texture(exchange(other.texture, nullptr)
){
    // Optionally, if there are more complex resources, perform shallow copy or move operations
    // For example, if you have std::vector<...> members, you would use std::move to transfer their contents
}


// Move assignment operator definition
OpenglRenderer& OpenglRenderer::operator=(OpenglRenderer&& other) noexcept {
  if (this != &other) { // Handle self-assignment
    // Release existing resources before stealing from other
    this->~OpenglRenderer(); // Call destructor to release resources

    // Transfer resources
    textureRegistrar = exchange(other.textureRegistrar, nullptr);
    context = exchange(other.context, nullptr);
    dartContext = exchange(other.dartContext, nullptr);
    width = exchange(other.width, 0);
    height = exchange(other.height, 0);
    textureId = exchange(other.textureId, 0);

    fboId = exchange(other.fboId, 0);
    rboId = exchange(other.rboId, 0);
    texture = exchange(other.texture, nullptr);
  }
  return *this;
}

// Helper swap function (useful for copy-and-swap idiom for copy assignment, though not strictly needed here)
void OpenglRenderer::swap(OpenglRenderer& other) noexcept {
  using std::swap;
  swap(textureRegistrar, other.textureRegistrar);
  swap(context, other.context);
  swap(dartContext, other.dartContext);
  swap(width, other.width);
  swap(height, other.height);
  swap(textureId, other.textureId);
  swap(fboId, other.fboId);
  swap(rboId, other.rboId);
  swap(texture, other.texture);
}