
#ifndef OPENGLRENDERER_H
#define OPENGLRENDERER_H

#include <flutter_linux/flutter_linux.h>
#include <flutter_linux/fl_texture_registrar.h>
#include <memory>
#include <map>
#include <EGL/egl.h>
#include <EGL/eglext.h>

class OpenglRenderer {
  public:
    uint32_t width = 0;
    uint32_t height = 0;

    OpenglRenderer(FlTextureRegistrar* registrar, EGLDisplay display, EGLContext context, int width, int height);
    ~OpenglRenderer();

    FlValue* createTexture();
    void setupOpenGLResources();
    void updateTexture();
    void changeSize(int width, int height);
    void dispose(bool release_context);

    int64_t textureId = 0;

  private:
    FlTextureRegistrar *textureRegistrar;
    FlTexture *texture;

    EGLDisplay eglDisplay = nullptr;
    EGLContext eglContext = nullptr;

    uint32_t texId = 0;

    // Private method to swap members, helpful for both move constructor and assignment
    void swap(OpenglRenderer& other) noexcept;
};

typedef std::map<int64_t, std::unique_ptr<OpenglRenderer>> RendererMap;

class Map{
  public:
    RendererMap renderers;
};

#endif