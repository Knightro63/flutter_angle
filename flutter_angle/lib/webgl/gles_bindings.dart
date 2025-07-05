import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import './gles_bindings_wasm.dart' as gles;
import '../shared/webgl.dart';
import '../shared/classes.dart';

class LibOpenGLES{
  late dynamic gl;
  LibOpenGLES(this.gl);

  void glScissor(int x, int y, int width, int height) {
    if(kIsWasm){
      gles.glScissor(gl, x, y, width, height);
      return;
    }
    gl.scissor(x, y, width, height);
  }

  void glViewport(int x, int y, int width, int height){
    if(kIsWasm){
      gles.glViewport(gl, x, y, width, height);
      return;
    }
    gl.viewport(x, y, width, height);
  }

  ShaderPrecisionFormat glGetShaderPrecisionFormat() {
    return ShaderPrecisionFormat();
  }

  dynamic getExtension(String key) {
    if(kIsWasm){
      return gles.glGetExtension(gl, key);
    }
    return gl.getExtension(key);
  }

  dynamic getParameter(key) {
    if(kIsWasm){
      return gles.glGetParameter(gl, key);
    }
    return gl.getParameter(key);
  }

  dynamic getString(String key) {
    if(kIsWasm){
      return gles.glGetString(gl, key);
    }
    return gl.getParameter(key);
  }

  dynamic createTexture() {
    if(kIsWasm){
      return gles.createTexture(gl);
    }
    return gl.createTexture();
  }

  void glBindTexture(int type, dynamic texture) {
    if(kIsWasm){
      gles.glBindTexture(gl, type, texture);
      return;
    }
    gl.bindTexture(type, texture);
  }

  void glDrawElementsInstanced(int mode, int count, int type, int offset, int instanceCount) {
    if(kIsWasm){
      gles.glDrawElementsInstanced(gl, mode, count, type, offset, instanceCount);
      return;
    }
    gl.drawElementsInstanced(mode, count, type, offset, instanceCount);
  }

  void glActiveTexture(int v0) {
    if(kIsWasm){
      gles.glActiveTexture(gl, v0);
      return;
    }
    gl.activeTexture(v0);
  }

  void glTexParameteri(int target, int pname, int param) {
    if(kIsWasm){
      gles.glTexParameteri(gl, target, pname, param);
      return;
    }
    gl.texParameteri(target, pname, param);
  }

  void glTexImage2D(
    int target, 
    int level, 
    int internalformat, 
    int width, 
    int height, 
    int border, 
    int format, 
    int type, 
    TypedData? pixels
  ) {
    if(kIsWasm){
      gles.glTexImage2D(gl, target, level, internalformat, width, height, border, format, type, pixels.jsify());
      return;
    }
    gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
  }

  void glTexImage2D_NOSIZE(    
    int target, 
    int level, 
    int internalformat, 
    int border, 
    int format, 
    int type, 
    TypedData? pixels
  ) { 
    if(kIsWasm){
      gles.glTexImage2D_NOSIZE(gl, target, level, internalformat, format, type, pixels.jsify());
      return;
    }
    gl.texImage2D(target, level, internalformat, format, type, pixels);
  }

  void glTexImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, TypedData? pixels) {
    if(kIsWasm){
      gles.glTexImage3D(gl, target, level, internalformat, width, height, depth,border, format, type, pixels.jsify());
      return;
    }
    gl.texImage3D(target, level, internalformat, width, height, depth,border, format, type, pixels);
  }

  void glDepthFunc(int v0) {
    if(kIsWasm){
      gles.glDepthFunc(gl, v0);
      return;
    }
    gl.depthFunc(v0);
  }

  void glDepthMask(bool v0) {
    if(kIsWasm){
      gles.glDepthMask(gl, v0);
      return;
    }
    gl.depthMask(v0);
  }

  void glEnable(int v0) {
    if(kIsWasm){
      gles.glEnable(gl, v0);
      return;
    }
    gl.enable(v0);
  }

  void glDisable(int v0) {
    if(kIsWasm){
      gles.glDisable(gl, v0);
      return;
    }
    gl.disable(v0);
  }

  void glBlendEquation(int v0) {
    if(kIsWasm){
      gles.glBlendEquation(gl, v0);
      return;
    }
    gl.blendEquation(v0);
  }

  void glUseProgram(dynamic program) {
    if(kIsWasm){
      gles.glUseProgram(gl, program);
      return;
    }
    gl.useProgram(program);
  }

  void glBlendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    if(kIsWasm){
      gles.glBlendFuncSeparate(gl, srcRGB, dstRGB, srcAlpha, dstAlpha);
      return;
    }
    gl.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
  }

  void glBlendFunc(int sfactor, int dfactor){
    if(kIsWasm){
      gles.glBlendFunc(gl, sfactor, dfactor);
      return;
    }
    gl.blendFunc(sfactor, dfactor);
  }

  void glBlendEquationSeparate(int modeRGB, int modeAlpha){
    if(kIsWasm){
      gles.glBlendEquationSeparate(gl, modeRGB, modeAlpha);
      return;
    }
    gl.blendEquationSeparate(modeRGB, modeAlpha);
  }

  void glFrontFace(int mode) {
    if(kIsWasm){
      gles.glFrontFace(gl, mode);
      return;
    }
    gl.frontFace(mode);
  }

  void glCullFace(int mode) {
    if(kIsWasm){
      gles.glCullFace(gl, mode);
      return;
    }
    gl.cullFace(mode);
  }

  void glLineWidth(double width) {
    if(kIsWasm){
      gles.glLineWidth(gl, width);
      return;
    }
    gl.lineWidth(width);
  }

  void glPolygonOffset(double factor, double units) {
    if(kIsWasm){
      gles.glPolygonOffset(gl, factor, units);
      return;
    }
    gl.polygonOffset(factor, units);
  }

  void glStencilMask(int mask) {
    if(kIsWasm){
      gles.glStencilMask(gl, mask);
      return;
    }
    gl.stencilMask(mask);
  }

  void glStencilFunc(int func, int ref, int mask){
    if(kIsWasm){
      gles.glStencilFunc(gl, func, ref, mask);
      return;
    }
    gl.stencilFunc(func, ref, mask);
  }

  void glStencilOp(int fail, int zfail, int zpass){
    if(kIsWasm){
      gles.glStencilOp(gl, fail, zfail, zpass);
      return;
    }
    gl.stencilOp(fail, zfail, zpass);
  }

  void glClearStencil(int s) {
    if(kIsWasm){
      gles.glClearStencil(gl, s);
      return;
    }
    gl.clearStencil(s);
  }

  void glClearDepth(double depth) {
    if(kIsWasm){
      gles.glClearDepth(gl, depth);
      return;
    }
    gl.clearDepth(depth);
  }

  void glColorMask(bool red, bool green, bool blue, bool alpha) {
    if(kIsWasm){
      gles.glColorMask(gl, red, green, blue, alpha);
      return;
    }
    gl.colorMask(red, green, blue, alpha);
  }

  void glClearColor(double red, double green, double blue, double alpha){
    if(kIsWasm){
      gles.glClearColor(gl, red, green, blue, alpha);
      return;
    }
    gl.clearColor(red, green, blue, alpha);
  }

  void glCompressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, TypedData? data){
    if(kIsWasm){
      gles.glCompressedTexImage2D(gl, target, level, internalformat, width, height, border, data.jsify());
      return;
    }
    gl.glCompressedTexImage2D(target, level, internalformat, width, height, border, data);
  }

  void glGenerateMipmap(int target) {
    if(kIsWasm){
      gles.glGenerateMipmap(gl, target);
      return;
    }
    gl.generateMipmap(target);
  }

  void glDeleteTexture(int v0) {
    if(kIsWasm){
      gles.glGenerateMipmap(gl, v0);
      return;
    }
    gl.deleteTexture(v0);
  }

  void glDeleteFramebuffer(int framebuffer) {
    if(kIsWasm){
      gles.glDeleteFramebuffer(gl, framebuffer);
      return;
    }
    gl.deleteFramebuffer(framebuffer);
  }

  void deleteRenderbuffer(int renderbuffer) {
    if(kIsWasm){
      gles.glDeleteRenderbuffer(gl, renderbuffer);
      return;
    }
    gl.deleteRenderbuffer(renderbuffer);
  }

  void texParameterf(int target, int pname, double param) {
    if(kIsWasm){
      gles.glTexParameterf(gl, target, pname, param);
      return;
    }
    gl.texParameterf(target, pname, param);
  }

  void glPixelStorei(int pname, int param) {
    if(kIsWasm){
      gles.glPixelStorei(gl, pname, param);
      return;
    }
    gl.pixelStorei(pname, param);
  }

  dynamic getContextAttributes() {
    if(kIsWasm){
      return gles.glGetContextAttributes(gl);
    }
    return gl.getContextAttributes();
  }

  dynamic getProgramParameter(dynamic program, int pname) {
    if(kIsWasm){
      return gles.glGetProgramParameter(gl, program ,pname);
    }
    return gl.getProgramParameter(program, pname);
  }

  dynamic getActiveUniform(v0, v1) {
    if(kIsWasm){
      return gles.glGetActiveUniform(gl, v0,v1);
    }
    return gl.getActiveUniform(v0, v1);
  }

  dynamic getActiveAttrib(dynamic v0, int v1) {
    if(kIsWasm){
      return gles.glGetActiveAttrib(gl, v0,v1);
    }
    return gl.getActiveAttrib(v0, v1);
  }

  dynamic glGetUniformLocation(dynamic program, String name) {
    if(kIsWasm){
      return gles.glGetUniformLocation(gl, program, name);
    }
    return gl.getUniformLocation(program, name);
  }

  void glClear(mask) {
    if(kIsWasm){
      gles.glClear(gl, mask);
      return;
    }
    gl.clear(mask);
  }

  dynamic glCreateBuffer() {
    if(kIsWasm){
      return gles.glCreateBuffer(gl);
    }
    return gl.createBuffer();
  }

  void glBindBuffer(int target, dynamic buffer) {
    if(kIsWasm){
      gles.glBindBuffer(gl, target, buffer);
      return;
    }
    gl.bindBuffer(target, buffer);
  }

  void glBufferData(int target, TypedData data, int usage) {
    if(kIsWasm){
      gles.glBufferData(gl, target, data.jsify(), usage);
      return;
    }
    gl.bufferData(target, data, usage);
  }

  void glVertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset) {
    if(kIsWasm){
      gles.glVertexAttribPointer(gl, index, size, type, normalized, stride, offset);
      return;
    }
    gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
  }

  void glDrawArrays(int mode, int first, int count) {
    if(kIsWasm){
      gles.glDrawArrays(gl, mode, first, count);
      return;
    }
    gl.drawArrays(mode, first, count);
  }

  void glDrawArraysInstanced(int mode, int first, int count, int instanceCount){
    if(kIsWasm){
      gles.glDrawArraysInstanced(gl, mode, first, count, instanceCount);
      return;
    }
    gl.drawArraysInstanced(mode, first, count, instanceCount);
  }

  void glBindFramebuffer(int target, dynamic framebuffer){
    if(kIsWasm){
      gles.glBindFramebuffer(gl, target, framebuffer);
      return;
    }
    gl.bindFramebuffer(target, framebuffer);
  }

  int glCheckFramebufferStatus(int target) {
    if(kIsWasm){
      return gles.glCheckFramebufferStatus(gl, target);
    }
    return gl.checkFramebufferStatus(target);
  }

  void glFramebufferTexture2D(int target, int attachment, int textarget, dynamic texture, int level){
    if(kIsWasm){
      gles.glFramebufferTexture2D(gl, target, attachment, textarget, texture, level);
      return;
    }
    gl.framebufferTexture2D(target, attachment, textarget, texture, level);
  }

  void glReadPixels(int x, int y, int width, int height, int format, int type, TypedData? pixels) {
    if(kIsWasm){
      gles.glReadPixels(gl, x, y, width, height, format, type, pixels.jsify());
      return;
    }
    gl.readPixels(x, y, width, height, format, type, pixels);
  }

  bool glIsProgram(dynamic program){
    if(kIsWasm){
      return gles.glIsProgram(gl, program);
    }
    return gl.isProgram(program) != 0;
  }

  void glCopyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border){
    if(kIsWasm){
      gles.glCopyTexImage2D(gl, target, level, internalformat, x, y, width, height, border);
      return;
    }
    gl.copyTexImage2D(target, level, internalformat, x, y, width, height, border);
  }

  void glTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, TypedData? pixels) {
    if(kIsWasm){
      gles.glTexSubImage2D(gl, target, level, xoffset, yoffset, width, height, format, type, pixels.jsify());
      return;
    }
    gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
  }

  void glTexSubImage2D_NOSIZE(int target, int level, int xoffset, int yoffset, int format, int type, TypedData? pixels){
    if(kIsWasm){
      gles.glTexSubImage2D_NOSIZE(gl, target, level, xoffset, yoffset, format, type, pixels.jsify());
      return;
    }
    gl.texSubImage2D(target, level, xoffset, yoffset, format, type, pixels);
  }

  void glTexSubImage3D(
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
    TypedData? pixels
  ) {
    if(kIsWasm){
      gles.glTexSubImage3D(gl, target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels.jsify());
      return;
    }
    gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
  }

  void glCompressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, TypedData? pixels) {
    if(kIsWasm){
      gles.glCompressedTexSubImage2D(gl, target, level, xoffset, yoffset, width, height, format, pixels.jsify());
      return;
    }
    gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, pixels);
  }

  void glBindRenderbuffer(int target, dynamic framebuffer){
    if(kIsWasm){
      gles.glBindRenderbuffer(gl, target, framebuffer);
      return;
    }
    gl.bindRenderbuffer(target, framebuffer);
  }

  void glRenderbufferStorageMultisample(int target, int samples, int internalformat, int width, int height){
    if(kIsWasm){
      gles.glRenderbufferStorageMultisample(gl, target, samples, internalformat, width, height);
      return;
    }
    gl.renderbufferStorageMultisample(target, samples, internalformat, width, height);
  }

  void glRenderbufferStorage(int target, int internalformat, int width, int height){
    if(kIsWasm){
      gles.glRenderbufferStorage(gl, target, internalformat, width, height);
      return;
    }
    gl.renderbufferStorage(target, internalformat, width, height);
  }

  void glFramebufferRenderbuffer(int target, int attachment, int renderbuffertarget, dynamic renderbuffer){
    if(kIsWasm){
      gles.glFramebufferRenderbuffer(gl, target, attachment, renderbuffertarget, renderbuffer);
      return;
    }
    gl.framebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer);
  }

  dynamic glCreateRenderbuffer() {
    if(kIsWasm){
      return gles.glCreateRenderbuffer(gl);
    }
    return gl.createRenderbuffer();
  }
  void glGenRenderbuffers(int count, List buffers) {
    for(int i = 0; i < count; i++){
      if(kIsWasm){
         buffers.add(gles.glCreateRenderbuffer(gl));
        return;
      }
      else{
        buffers.add(gl.createRenderbuffer());
      }
    }
  }
  dynamic glCreateFramebuffer() {
    if(kIsWasm){
      return gles.glCreateFramebuffer(gl);
    }
    return gl.createFramebuffer();
  }
  void glGenFramebuffers(int count, List buffers) {
    for(int i = 0; i < count; i++){
      if(kIsWasm){
        buffers.add(gles.glCreateFramebuffer(gl));
        return;
      }
      else{
        buffers.add(gl.createFramebuffer());
      }
    }
  }
  void glBlitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter){
    if(kIsWasm){
      gles.glBlitFramebuffer(gl, srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
      return;
    }
    gl.blitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
  }

  void glBufferSubData(int target, int dstByteOffset, TypedData srcData, int srcOffset, int length){
    if(kIsWasm){
      gles.glBufferSubData(gl, target, dstByteOffset, srcData.jsify()!);
      return;
    }
    gl.bufferSubData(target, dstByteOffset, srcData);
  }

  dynamic glCreateVertexArray() {
    if(kIsWasm){
      return gles.glCreateVertexArray(gl);
    }
    return gl.createVertexArray();
  }

  dynamic glCreateProgram() {
    if(kIsWasm){
      return gles.glCreateProgram(gl);
    }
    return gl.createProgram();
  }

  void glAttachShader(dynamic program, dynamic shader) {
    if(kIsWasm){
      gles.glAttachShader(gl, program, shader);
      return;
    }
    gl.attachShader(program, shader);
  }

  void glBindAttribLocation(dynamic program, int index, String name){
    if(kIsWasm){
      gles.glBindAttribLocation(gl, program, index, name);
      return;
    }
    gl.bindAttribLocation(program, index, name);
  }

  void glLinkProgram(dynamic program, [bool checkForErrors = true]) {
    if(kIsWasm){
      gles.glLinkProgram(gl, program);
      return;
    }
    gl.linkProgram(program);
  }

  String? getProgramInfoLog(dynamic program) {
    if(kIsWasm){
      return gles.getProgramInfoLog(gl, program);
    }
    return gl.getProgramInfoLog(program);
  }

  String? getShaderInfoLog(dynamic shader){
    if(kIsWasm){
      return gles.getShaderInfoLog(gl, shader);
    }
    return gl.getShaderInfoLog(shader);
  }

  int glGetError() {
    if(kIsWasm){
      return gles.glGetError(gl);
    }
    return gl.getError();
  }

  void glDeleteShader(dynamic shader) {
    if(kIsWasm){
      gles.glDeleteShader(gl, shader);
      return;
    }
    gl.deleteShader(shader);
  }

  void glDeleteProgram(dynamic program) {
    if(kIsWasm){
      gles.glDeleteProgram(gl, program);
      return;
    }
    gl.deleteProgram(program);
  }

  void glDeleteBuffer(dynamic buffer) {
    if(kIsWasm){
      gles.glDeleteBuffer(gl, buffer);
      return;
    }
    gl.deleteBuffer(buffer);
  }

  void glBindVertexArray(dynamic array) {
    if(kIsWasm){
      gles.glBindVertexArray(gl, array);
      return;
    }
    gl.bindVertexArray(array);
  }

  void glDeleteVertexArray(dynamic array) {
    if(kIsWasm){
      gles.glDeleteVertexArray(gl, array);
      return;
    }
    gl.deleteVertexArray(array);
  }

  void glEnableVertexAttribArray(int index) {
    if(kIsWasm){
      gles.glEnableVertexAttribArray(gl, index);
      return;
    }
    gl.enableVertexAttribArray(index);
  }

  void glDisableVertexAttribArray(int index) {
    if(kIsWasm){
      gles.glDisableVertexAttribArray(gl, index);
      return;
    }
    gl.disableVertexAttribArray(index);
  }

  void glVertexAttribIPointer(int index, int size, int type, int stride, int pointer){
    if(kIsWasm){
      gles.glVertexAttribIPointer(gl, index, size, type, stride, pointer);
      return;
    }
    gl.vertexAttribIPointer(index, size, type, stride, pointer);
  }

  void glVertexAttrib2fv(int index, List<double> values) {
    if(kIsWasm){
      gles.glVertexAttrib2fv(gl, index, values.jsify());
      return;
    }
    gl.vertexAttrib2fv(index, values);
  }

  void glVertexAttrib3fv(int index, List<double> values) {
    if(kIsWasm){
      gles.glVertexAttrib3fv(gl, index, values.jsify());
      return;
    }
    gl.vertexAttrib3fv(index, values);
  }

  void glVertexAttrib4fv(int index, List<double> values) {
    if(kIsWasm){
      gles.glVertexAttrib4fv(gl, index, values.jsify());
      return;
    }
    gl.vertexAttrib4fv(index, values);
  }

  void glVertexAttrib1fv(int index, List<double> values) {
    if(kIsWasm){
      gles.glVertexAttrib1fv(gl, index, values.jsify());
      return;
    }
    gl.vertexAttrib1fv(index, values);
  }

  void glDrawElements(int mode, int count, int type, int offset) {
    if(kIsWasm){
      gles.glDrawElements(gl, mode, count, type, offset);
      return;
    }
    gl.drawElements(mode, count, type, offset);
  }

  void glDrawBuffers(List<int> buffers) {
    if(kIsWasm){
      gles.glDrawBuffers(gl, buffers.jsify()!);
      return;
    }
    gl.drawBuffers(buffers);
  }

  dynamic glCreateShader(int type) {
    if(kIsWasm){
      return gles.glCreateShader(gl, type);
    }
    return gl.createShader(type);
  }

  void glShaderSource(dynamic shader, String shaderSource) {
    if(kIsWasm){
      gles.glShaderSource(gl, shader, shaderSource);
      return;
    }
    gl.shaderSource(shader, shaderSource);
  }

  void glCompileShader(dynamic shader) {
    if(kIsWasm){
      gles.glCompileShader(gl, shader);
      return;
    }
    gl.compileShader(shader);
  }

  bool glGetShaderParameter(dynamic shader, int pname){
    if(kIsWasm){
      return gles.glGetShaderParameter(gl, shader, pname);
    }
    return gl.getShaderParameter(shader, pname);
  }

  String? glGetShaderSource(dynamic shader) {
    if(kIsWasm){
      return gles.glGetShaderSource(gl, shader);
    }
    return gl.getShaderSource(shader);
  }

  void glUniformMatrix4fv(dynamic location, bool transpose, List<double> values) {
    if(kIsWasm){
      gles.glUniformMatrix4fv(gl, location, transpose, values.jsify());
      return;
    }
    gl.uniformMatrix4fv(location, transpose, values);
  }

  void glUniform1i(dynamic location, int x) {
    if(kIsWasm){
      gles.glUniform1i(gl, location, x);
      return;
    }
    gl.uniform1i(location, x);
  }

  void glUniform3f(dynamic location, double x, double y, double z) {
    if(kIsWasm){
      gles.glUniform3f(gl, location, x, y, z);
      return;
    }
    gl.uniform3f(location, x, y, z);
  }

  void glUniform4f(dynamic location, double x, double y, double z, double w){
    if(kIsWasm){
      gles.glUniform4f(gl, location, x, y, z, w);
      return;
    }
    gl.uniform4f(location, x, y, z, w);
  }

  void glUniform1fv(dynamic location, List<double> v){
    if(kIsWasm){
      gles.glUniform1fv(gl, location, v.jsify());
      return;
    }
    gl.uniform1fv(location, v);
  }

  void glUniform2fv(dynamic location, List<double> v){
    if(kIsWasm){
      gles.glUniform2fv(gl, location, v.jsify());
      return;
    }
    gl.uniform2fv(location, v);
  }

  void glUniform3fv(dynamic location, List<double> v){
    if(kIsWasm){
      gles.glUniform3fv(gl, location, v.jsify());
      return;
    }
    gl.uniform3fv(location, v);
  }

  void glUniform1f(dynamic location, double x){
    if(kIsWasm){
      gles.glUniform1f(gl, location, x);
      return;
    }
    gl.uniform1f(location, x);
  }

  void glUniformMatrix3fv(dynamic location, bool transpose, List<double> values) {
    if(kIsWasm){
      gles.glUniformMatrix3fv(gl, location, transpose, values.jsify());
      return;
    }
    gl.uniformMatrix3fv(location, transpose, values);
  }

  dynamic glGetAttribLocation(dynamic program, String name) {
    if(kIsWasm){
      return gles.glGetAttribLocation(gl, program, name);
    }
    return gl.getAttribLocation(program, name);
  }

  void glUniform2f(dynamic location, double x, double y){
    if(kIsWasm){
      gles.glUniform2f(gl, location, x, y);
      return;
    }
    gl.uniform2f(location, x, y);
  }

  void glUniform1iv(dynamic location, List<int> v){
    if(kIsWasm){
      gles.glUniform1iv(gl, location, v.jsify());
      return;
    }
    gl.uniform1iv(location, v);
  }

  void glUniform2iv(dynamic location, List<int> v){
    if(kIsWasm){
      gles.glUniform2iv(gl, location, v.jsify());
      return;
    }
    gl.uniform2iv(location, v);
  }

  void glUniform3iv(dynamic location, List<int> v){
    if(kIsWasm){
      gles.glUniform3iv(gl, location, v.jsify());
      return;
    }
    gl.uniform3iv(location, v);
  }

  void glUniform4iv(dynamic location, List<int> v){
    if(kIsWasm){
      gles.glUniform4iv(gl, location, v.jsify());
      return;
    }
    gl.uniform4iv(location, v);
  }

  void glUniform4fv(dynamic location, List<double> vectors) {
    if(kIsWasm){
      gles.glUniform4fv(gl, location, vectors.jsify());
      return;
    }
    gl.uniform4fv(location, vectors);
  }

  void glVertexAttribDivisor(int index, int divisor){
    if(kIsWasm){
      gles.glVertexAttribDivisor(gl, index, divisor);
      return;
    }
    gl.vertexAttribDivisor(index, divisor);
  }

  void glFlush() {
    if(kIsWasm){
      gles.glFlush(gl);
      return;
    }
    gl.flush();
  }

  void glFinish() {
    if(kIsWasm){
      gles.glFinish(gl);
      return;
    }
    gl.finish();
  }

  void glTexStorage2D(int target, int levels, int internalformat, int width, int height){
    if(kIsWasm){
      gles.glTexStorage2D(gl, target, levels, internalformat, width, height);
      return;
    }
    gl.texStorage2D(target, levels, internalformat, width, height);
  }

  void glTexStorage3D(int target, int levels, int internalformat, int width, int height, int depth){
    if(kIsWasm){
      gles.glTexStorage3D(gl, target, levels, internalformat, width, height, depth);
      return;
    }
    gl.texStorage3D(target, levels, internalformat, width, height, depth);
  }

  int glCreateTransformFeedback() {
    if(kIsWasm){
      return gles.glCreateTransformFeedback(gl);
    }
    return gl.createTransformFeedback();
  }
  void glBindTransformFeedback(int target, int id){
    if(kIsWasm){
      gles.glBindTransformFeedback(gl, target, id);
      return;
    }
    gl.bindTransformFeedback(target, id);
  }

  void glTransformFeedbackVaryings(dynamic program, int count, List<String> varyings, int bufferMode) {
    if(kIsWasm){
      gles.glTransformFeedbackVaryings(gl, program, varyings.jsify(), bufferMode);
      return;
    }
    gl.transformFeedbackVaryings(program, varyings, bufferMode);
  }

  void glDeleteTransformFeedback(int transformFeedback) {
    if(kIsWasm){
      gles.glDeleteTransformFeedback(gl, transformFeedback);
      return;
    }
    gl.deleteTransformFeedback(transformFeedback);
  }

  bool isTransformFeedback(int transformFeedback) {
    if(kIsWasm){
      return gles.isTransformFeedback(gl, transformFeedback);
    }
    return gl.isTransformFeedback(transformFeedback);
  }

  void glBeginTransformFeedback(int primitiveMode) {
    if(kIsWasm){
      gles.glBeginTransformFeedback(gl, primitiveMode);
      return;
    }
    gl.beginTransformFeedback(primitiveMode);
  }

  void glEndTransformFeedback() {
    if(kIsWasm){
      gles.glEndTransformFeedback(gl);
      return;
    }
    gl.endTransformFeedback();
  }

  void glPauseTransformFeedback() {
    if(kIsWasm){
      gles.glPauseTransformFeedback(gl);
      return;
    }
    gl.pauseTransformFeedback();
  }

  void glResumeTransformFeedback() {
    if(kIsWasm){
      gles.glResumeTransformFeedback(gl);
      return;
    }
    gl.resumeTransformFeedback();
  }

  Map glGetTransformFeedbackVarying(dynamic program, int index) {
    // if(kIsWasm){
    //   return gles.glGetTransformFeedbackVarying(gl, program, index);
    // }
    return gl.getTransformFeedbackVarying(program, index);
  }

  void glInvalidateFramebuffer(int target, List<int> attachments){
    if(kIsWasm){
      gles.glInvalidateFramebuffer(gl, target, attachments.jsify());
      return;
    }
    gl.invalidateFramebuffer(target, attachments);
  }

  Uint8List readCurrentPixels(int x, int y, int width, int height) {
    int _len = width * height * 4;
    var buffer = Uint8List(_len);
    gl.readPixels(x, y, width, height, WebGL.RGBA, WebGL.UNSIGNED_BYTE, buffer);
    return buffer;
  }

  void glCopyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height){
    if(kIsWasm){
      gles.glCopyTexSubImage2D(gl, target, level, xoffset, yoffset, x, y, width, height);
      return;
    }
    gl.copyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
  }
}
