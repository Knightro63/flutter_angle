import 'dart:js_interop';

@JS()
external JSObject glCanvas(JSObject id);

@JS()
external void glScissor(JSObject gl, int x, int y, int width, int height);
@JS()
external void glViewport(JSObject gl, int x, int y, int width, int height);
@JS()
external JSObject glGetShaderPrecisionFormat(JSObject gl);

// getExtension(String key);
// getParameter(key);
// getString(String key);

@JS()
external JSObject createTexture(JSObject gl);
@JS()
external void glBindTexture(JSObject gl, int type, JSObject texture);
@JS()
external void glDrawElementsInstanced(JSObject gl, int mode, int count, int type, int offset, int instanceCount);
@JS()
external void glActiveTexture(JSObject gl, int v0);
@JS()
external void glTexParameteri(JSObject gl, int target, int pname, int param);

@JS()
external void glTexImage2D(
  JSObject gl, 
  int target, 
  int level, 
  int internalformat, 
  int width, 
  int height, 
  int border, 
  int format, 
  int type, 
  JSArray pixels
);

@JS()
external void glTexImage2D_NOSIZE(
  JSObject gl,     
  int target, 
  int level, 
  int internalformat,
  int format, 
  int type, 
  JSObject? pixels
);

// @JS()
// external void glTexImage2D_NOSIZE_element(
//   JSObject gl,     
//   int target, 
//   int level, 
//   int internalformat, 
//   int format, 
//   int type, 
//   JSObject? pixels
// );

@JS()
external void glTexImage3D(JSObject gl, int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, JSArray? pixels);
@JS()
external void glDepthFunc(JSObject gl, int v0);
@JS()
external void glDepthMask(JSObject gl, bool v0);
@JS()
external void glEnable(JSObject gl, int v0);
@JS()
external void glDisable(JSObject gl, int v0);
@JS()
external void glBlendEquation(JSObject gl, int v0);
@JS()
external void glUseProgram(JSObject gl, JSObject program);

@JS()
external void glBlendFuncSeparate(JSObject gl, int srcRGB, int dstRGB, int srcAlpha, int dstAlpha);
@JS()
external void glBlendFunc(JSObject gl, int sfactor, int dfactor);
@JS()
external void glBlendEquationSeparate(JSObject gl, int modeRGB, int modeAlpha);
@JS()
external void glFrontFace(JSObject gl, int mode);

@JS()
external void glCullFace(JSObject gl, int mode);
@JS()
external void glLineWidth(JSObject gl, double width);
@JS()
external void glPolygonOffset(JSObject gl, double factor, double units);
@JS()
external void glStencilMask(JSObject gl, int mask);
@JS()
external void glStencilFunc(JSObject gl, int func, int ref, int mask);
@JS()
external void glStencilOp(JSObject gl, int fail, int zfail, int zpass);
@JS()
external void glClearStencil(JSObject gl, int s);
@JS()
external void glClearDepth(JSObject gl, double depth);
@JS()
external void glColorMask(JSObject gl, bool red, bool green, bool blue, bool alpha);
@JS()
external void glClearColor(JSObject gl, double red, double green, double blue, double alpha);
@JS()
external void glCompressedTexImage2D(JSObject gl, int target, int level, int internalformat, int width, int height, int border, JSArray? data);
@JS()
external void glGenerateMipmap(JSObject gl, int target);
@JS()
external void glDeleteTexture(JSObject gl, int v0);
@JS()
external void glDeleteFramebuffer(JSObject gl, int framebuffer);
@JS()
external void deleteRenderbuffer(JSObject gl, int renderbuffer);
@JS()
external void texParameterf(JSObject gl, int target, int pname, double param);
@JS()
external void glPixelStorei(JSObject gl, int pname, int param);
@JS()
external JSObject getContextAttributes(JSObject gl);
@JS()
external JSObject glGetProgramParameter(JSObject gl, JSObject program, int pname);
@JS()
external void getActiveUniform(JSObject gl, int v0, int v1);
@JS()
external void getActiveAttrib(JSObject gl, int v0, int v1);
@JS()
external JSObject glGetUniformLocation(JSObject gl, JSObject program, String name);
@JS()
external void glClear(JSObject gl, int mask);
@JS()
external JSObject glCreateBuffer(JSObject gl);
@JS()
external void glBindBuffer(JSObject gl, int target, JSObject buffer);
@JS()
external void glBufferData(JSObject gl, int target, JSObject data, int usage);
@JS()
external void glBufferDatai(JSObject gl, int target, int data, int usage);
@JS()
external void glVertexAttribPointer(JSObject gl, int index, int size, int type, bool normalized, int stride, int offset);
@JS()
external void glDrawArrays(JSObject gl, int mode, int first, int count);
@JS()
external void glDrawArraysInstanced(JSObject gl, int mode, int first, int count, int instanceCount);
@JS()
external void glBindFramebuffer(JSObject gl, int target, int framebuffer);
@JS()
external int glCheckFramebufferStatus(JSObject gl, int target);
@JS()
external void glFramebufferTexture2D(JSObject gl, int target, int attachment, int textarget, int texture, int level);
@JS()
external void glReadPixels(JSObject gl, int x, int y, int width, int height, int format, int type, JSArray? pixels);
@JS()
external bool glIsProgram(JSObject gl, int program);
@JS()
external void glCopyTexImage2D(JSObject gl, int target, int level, int internalformat, int x, int y, int width, int height, int border);
@JS()
external void glTexSubImage2D(JSObject gl, int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, JSArray? pixels) ;
@JS()
external void glTexSubImage2D_NOSIZE(JSObject gl, int target, int level, int xoffset, int yoffset, int format, int type, JSArray? pixels);

@JS()
external void glTexSubImage3D(JSObject gl, 
  int target,
  int level,
  int xoffset,
  int yoffset,
  int zoffset,
  int width,
  int height,
  int depth,
  int format,
  int type,
  JSArray? pixels
);

@JS()
external void glCompressedTexSubImage2D(JSObject gl, int target, int level, int xoffset, int yoffset, int width, int height, int format, JSArray? pixels);
@JS()
external void glBindRenderbuffer(JSObject gl, int target, int framebuffer);
@JS()
external void glRenderbufferStorageMultisample(JSObject gl, int target, int samples, int internalformat, int width, int height);
@JS()
external void glRenderbufferStorage(JSObject gl, int target, int internalformat, int width, int height);
@JS()
external void glFramebufferRenderbuffer(JSObject gl, int target, int attachment, int renderbuffertarget, int renderbuffer);
@JS()
external JSObject glCreateRenderbuffer(JSObject gl);
@JS()
external void glGenRenderbuffers(JSObject gl, int count, JSArray buffers);
@JS()
external JSObject glCreateFramebuffer(JSObject gl);
@JS()
external void glGenFramebuffers(JSObject gl, int count, JSArray buffers);
@JS()
external void glBlitFramebuffer(JSObject gl, int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter);
@JS()
external void glBufferSubData(JSObject gl, int target, int dstByteOffset, JSArray srcData);
@JS()
external JSObject glCreateVertexArray(JSObject gl);
@JS()
external JSObject glCreateProgram(JSObject gl);
@JS()
external void glAttachShader(JSObject gl, JSObject program, JSObject shader);
@JS()
external void glBindAttribLocation(JSObject gl, int program, int index, String name);
@JS()
external void glLinkProgram(JSObject gl, JSObject program);
@JS()
external String? getProgramInfoLog(JSObject gl, JSObject program);
@JS()
external String? getShaderInfoLog(JSObject gl, JSObject shader);
@JS()
external int glGetError(JSObject gl);
@JS()
external void glDeleteShader(JSObject gl, JSObject shader);
@JS()
external void glDeleteProgram(JSObject gl, JSObject program);
@JS()
external void glDeleteBuffer(JSObject gl, JSObject buffer);
@JS()
external void glBindVertexArray(JSObject gl, JSObject array);
@JS()
external void glDeleteVertexArray(JSObject gl, JSObject array);
@JS()
external void glEnableVertexAttribArray(JSObject gl, int index);
@JS()
external void glDisableVertexAttribArray(JSObject gl, int index);
@JS()
external void glVertexAttribIPointer(JSObject gl, int index, int size, int type, int stride, int pointer);
@JS()
external void glVertexAttrib2fv(JSObject gl, int index, JSArray values);
@JS()
external void glVertexAttrib3fv(JSObject gl, int index, JSArray values);
@JS()
external void glVertexAttrib4fv(JSObject gl, int index, JSArray values);
@JS()
external void glVertexAttrib1fv(JSObject gl, int index, JSArray values);
@JS()
external void glDrawElements(JSObject gl, int mode, int count, int type, int offset);
@JS()
external void glDrawBuffers(JSObject gl, JSArray buffers);
@JS()
external JSObject glCreateShader(JSObject gl, int type);
@JS()
external void glShaderSource(JSObject gl, JSObject shader, String shaderSource);
@JS()
external void glCompileShader(JSObject gl, JSObject shader);
@JS()
external int glGetShaderParameter(JSObject gl, JSObject shader, int pname);
@JS()
external String? glGetShaderSource(JSObject gl, JSObject shader);
@JS()
external void glUniformMatrix4fv(JSObject gl, JSObject location, bool transpose, JSObject values);
@JS()
external void glUniform1i(JSObject gl, JSObject location, int x);
@JS()
external void glUniform3f(JSObject gl, JSObject location, double x, double y, double z);
@JS()
external void glUniform4f(JSObject gl, JSObject location, double x, double y, double z, double w);
@JS()
external void glUniform1fv(JSObject gl, JSObject location, JSArray v);
@JS()
external void glUniform2fv(JSObject gl, JSObject location, JSArray v);
@JS()
external void glUniform3fv(JSObject gl, JSObject location, JSArray v);

@JS()
external void glUniform1f(JSObject gl, JSObject location, double x);
@JS()
external void glUniformMatrix3fv(JSObject gl, JSObject location, bool transpose, JSArray values);
@JS()
external int glGetAttribLocation(JSObject gl, JSObject program, String name);
@JS()
external void glUniform2f(JSObject gl, JSObject location, double x, double y);
@JS()
external void glUniform1iv(JSObject gl, JSObject location, JSArray v);
@JS()
external void glUniform2iv(JSObject gl, JSObject location, JSArray v);
@JS()
external void glUniform3iv(JSObject gl, JSObject location, JSArray v);

@JS()
external void glUniform4iv(JSObject gl, JSObject location, JSArray v);
@JS()
external void glUniform4fv(JSObject gl, JSObject location, JSArray vectors);
@JS()
external void glVertexAttribDivisor(JSObject gl, int index, int divisor);
@JS()
external void glFlush(JSObject gl);
@JS()
external void glFinish(JSObject gl);
@JS()
external void glTexStorage2D(JSObject gl, int target, int levels, int internalformat, int width, int height);
@JS()
external void glTexStorage3D(JSObject gl, int target, int levels, int internalformat, int width, int height, int depth);
@JS()
external int glCreateTransformFeedback(JSObject gl);
@JS()
external void glBindTransformFeedback(JSObject gl, int target, int id);
@JS()
external void glTransformFeedbackVaryings(JSObject gl, JSObject program, JSArray varyings, int bufferMode);
@JS()
external void glDeleteTransformFeedback(JSObject gl, int transformFeedback);
@JS()
external bool isTransformFeedback(JSObject gl, int transformFeedback);
@JS()
external void glBeginTransformFeedback(JSObject gl, int primitiveMode);
@JS()
external void glEndTransformFeedback(JSObject gl);
@JS()
external void glPauseTransformFeedback(JSObject gl);
@JS()
external void glResumeTransformFeedback(JSObject gl);
@JS()
external JSObject glGetTransformFeedbackVarying(JSObject gl, int program, int index);
@JS()
external void glInvalidateFramebuffer(JSObject gl, int target, JSArray attachments);
@JS()
external JSArray readCurrentPixels(JSObject gl, int x, int y, int width, int height);
@JS()
external JSObject glCreateTexture(JSObject gl);
@JS()
external JSObject glGetParameter(JSObject gl, int key);
@JS()
external int glGetExtension(JSObject gl, String key);
@JS()
external int glGlGetUniformBlockIndex(JSObject gl, int program, String uniformBlockName);
@JS()
external void glGlUniformBlockBinding(JSObject gl, int program, int uniformBlockIndex,int uniformBlockBinding);
@JS()
external void glDeleteRenderbuffer(JSObject gl, int renderbuffer);
@JS()
external void glTexParameterf(JSObject gl, int target, int pname, double param);
@JS()
external void glGetContextAttributes(JSObject gl);
@JS()
external JSObject glGetActiveUniform(JSObject gl, JSObject v0, int v1);
@JS()
external JSObject glGetActiveAttrib(JSObject gl, JSObject v0, int v1);
@JS()
external void glFramebufferTextureLayer(JSObject gl, int target,int attachment,int texture,int level,int layer);
@JS()
external void glClearBufferuiv(JSObject gl, int buffer,int drawbuffer, int value);
@JS()
external void glClearBufferiv(JSObject gl, int buffer,int drawbuffer, int value);
@JS()
external void glBindBufferBase(JSObject gl, int target, int index, int buffer);
@JS()
external void glCopyTexSubImage2D(JSObject gl,int target, int level, int xoffset, int yoffset, int x, int y, int width, int height);
@JS()
external void glGlCopyTexSubImage3D(JSObject gl, int target, int level, int xoffset, int yoffset, int zoffset, int x, int y, int width, int height);
@JS()
external void glCompressedTexSubImage3D(JSObject gl, int target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, int ormat, JSArray pixels);
@JS()
external void glCompressedTexImage3D(JSObject gl, int target,int level,int internalformat,int width, int height, int depth, int border, JSArray pixels);
@JS()
external String? glGetProgramInfoLog(JSObject gl, int id);
@JS()
external String? glGetShaderInfoLog(JSObject gl, int id);
@JS()
external void glUniformMatrix2fv(JSObject gl, int id, bool transpose, JSArray values);
@JS()
external bool glIsTransformFeedback(JSObject gl, int transformFeedback);

@JS()
external void glUniform1uiv(JSObject gl, int location, JSArray v);
@JS()
external void glUniform2uiv(JSObject gl, int location, JSArray v);
@JS()
external void glUniform3uiv(JSObject gl, int location, JSArray v);
@JS()
external void glUniform4uiv(JSObject gl, int location, JSArray v);

@JS()
external void glUniform1ui(JSObject gl, int location, int v0);
@JS()
external void glUniform2ui(JSObject gl, int location, int v0, int v1);
@JS()
external void glUniform3ui(JSObject gl, int location, int v0, int v1, int v2);
@JS()
external void glUniform4ui(JSObject gl, int location, int v0, int v1, int v2, int v3);