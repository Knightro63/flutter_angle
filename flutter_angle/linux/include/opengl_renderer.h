
#ifndef OPENGLRENDERER_H
#define OPENGLRENDERER_H

#include <flutter_linux/flutter_linux.h>
#include <flutter_linux/fl_texture_registrar.h>
#include <memory>
#include "fl_angle_texture.h"

class OpenGLRenderer {
public:
    uint32_t width;
    uint32_t height;
    int64_t textureId;

    virtual ~OpenGLRenderer();
    OpenGLRenderer(OpenGLRenderer&& other) noexcept; 
    OpenGLRenderer& operator=(OpenGLRenderer&& other) noexcept; 
    OpenGLRenderer(
      FlTextureRegistrar*,
      GdkGLContext*,
      GdkGLContext*
      int,
      int
    );

    FlValue *createTexture();
    void updateTexture();
    void changeSize(int, int);
    void dispose();

private:
    GdkGLContext* context;
    GdkGLContext* dartContext;

    uint32_t fboId = 0;
    uint32_t rboId = 0;

    FlTextureRegistrar *textureRegistrar;
    FlTexture *texture;
    FlAngleTextureGL *angleTexture;

    // Private method to swap members, helpful for both move constructor and assignment
    void swap(OpenGLRenderer& other) noexcept;
};

#endif