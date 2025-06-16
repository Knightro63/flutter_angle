#ifndef FLUTTER_EGL_INFO_H
#define FLUTTER_EGL_INFO_H

#include <gtk/gtk.h>
#include <glib-object.h>
#include "flutter_angle/flutter_angle_plugin.h"
#include <flutter_linux/flutter_linux.h>

G_DECLARE_FINAL_TYPE(
    EGLInfo,
    flutter_texture_gl,
    FL,
    EGL_INFO,
    FlTextureGL
)

struct _EGLInfo {
    uint64_t eglDisplay;
    uint64_t eglContext;
    uint64_t eglSurface;
};

EGLInfo *egl_info_new(
    uint64_t eglDisplay,
    uint64_t eglContext,
    uint64_t eglSurface
);



#endif // FLUTTER_EGL_INFO_H
