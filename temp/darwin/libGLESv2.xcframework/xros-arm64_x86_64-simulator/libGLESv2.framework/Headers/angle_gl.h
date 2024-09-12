//
// Copyright 2014 The ANGLE Project Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// angle_gl.h:
//   Includes all necessary GL headers and definitions for ANGLE.
//

#ifndef ANGLEGL_H_
#define ANGLEGL_H_

#if __has_include(<libGLESv2/GLES/gl.h>)
#include <libGLESv2/GLES/gl.h>
#include <libGLESv2/GLES/glext.h>
#include <libGLESv2/GLES2/gl2.h>
#include <libGLESv2/GLES2/gl2ext.h>
#include <libGLESv2/GLES3/gl3.h>
#include <libGLESv2/GLES3/gl31.h>
#include <libGLESv2/GLES3/gl32.h>
#else
#include "GLES/gl.h"
#include "GLES/glext.h"
#include "GLES2/gl2.h"
#include "GLES2/gl2ext.h"
#include "GLES3/gl3.h"
#include "GLES3/gl31.h"
#include "GLES3/gl32.h"
#endif

// TODO(http://anglebug.com/3730): Autogenerate these enums from gl.xml
// HACK: Defines for queries that are not in GLES
#define GL_CONTEXT_PROFILE_MASK 0x9126
#define GL_CONTEXT_COMPATIBILITY_PROFILE_BIT 0x00000002
#define GL_CONTEXT_CORE_PROFILE_BIT 0x00000001

#endif  // ANGLEGL_H_
