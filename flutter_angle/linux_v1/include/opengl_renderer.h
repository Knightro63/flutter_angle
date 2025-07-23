
#ifndef OPENGLRENDERER_H
#define OPENGLRENDERER_H

#include <flutter_linux/flutter_linux.h>
#include <flutter_linux/fl_texture_registrar.h>
#include <memory>
//#include "fl_angle_texture_gl.h"

class OpenglRenderer {
public:
    uint32_t width;
    uint32_t height;
    int64_t textureId;

    virtual ~OpenglRenderer();
    OpenglRenderer(OpenglRenderer&& other) noexcept; 
    OpenglRenderer& operator=(OpenglRenderer&& other) noexcept; 
    OpenglRenderer(FlTextureRegistrar*, GdkGLContext*,GdkGLContext*,int,int);

    FlValue *createTexture();
    void updateTexture();
    void changeSize(int, int);
    void dispose();

    template<class T, class U = T>
    T exchange(T& obj, U&& new_value){
      T old_value = std::move(obj);
      obj = std::forward<U>(new_value);
      return old_value;
    }

private:
    GdkGLContext* context;
    GdkGLContext* dartContext;

    uint32_t fboId = 0;
    uint32_t rboId = 0;

    FlTextureRegistrar *textureRegistrar;
    FlTexture *texture;

    // Private method to swap members, helpful for both move constructor and assignment
    void swap(OpenglRenderer& other) noexcept;
};

#endif