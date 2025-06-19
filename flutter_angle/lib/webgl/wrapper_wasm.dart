import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_angle/native-array/index.dart';
import 'package:flutter_angle/shared/console.dart';
import 'package:web/web.dart' as html;
import '../shared/webgl.dart';
import 'gles_bindings_wasm.dart';
import '../shared/classes.dart';
import 'dart:async';
import 'dart:ui';
import 'gles_bindings.dart';

class RenderingContext{
  final LibOpenGLES gl;
  dynamic _gl;
  final int width;
  final int height;

  RenderingContext.create(this.gl, this.width, this.height){
    _gl = gl.gl;
  }

  static dynamic createCanvas(JSObject _divId){
    return glCanvas(_divId);
  }

  void scissor(int x, int y, int width, int height){
    glScissor(_gl, x, y, width, height);
    checkError('scissor');
  }

  void viewport(int x, int y, int width, int height) {
    glViewport(_gl, x, y, width, height);
    checkError('viewport');
  }

  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) {
    return ShaderPrecisionFormat();
  }

  dynamic getExtension(String key) {
    return glGetExtension(_gl, key);
  }
  int getUniformBlockIndex(Program program, String uniformBlockName){
    return glGetUniformBlockIndex(_gl, program.id, uniformBlockName);
  }

  void uniformBlockBinding(Program program, int uniformBlockIndex,int uniformBlockBinding){
    glUniformBlockBinding(_gl, program.id,uniformBlockIndex,uniformBlockBinding);
  }
  // getParameter(key) {
  //   glGetParameter(_gl, key);
  // }

  // getString(String key) {
  //   glGetParameter(_gl, key);
  // }

  WebGLTexture createTexture() {
    return WebGLTexture(glCreateTexture(_gl));
  }

  void bindTexture(int target, WebGLTexture? texture) {
    if(texture == null) return;
    glBindTexture(_gl, target, texture.id);
    checkError('bindTexture');
  }

  void drawElementsInstanced(int mode, int count, int type, int offset, int instanceCount) {
    glDrawElementsInstanced(_gl, mode, count, type, offset, instanceCount);
    checkError('drawElementsInstanced');
  }

  void activeTexture(int v0) {
    glActiveTexture(_gl, v0);
    checkError('activeTexture');
  }

  void texParameteri(int target, int pname, int param) {
    glTexParameteri(_gl, target, pname, param);
    checkError('texParameteri');
  }
  
  void checkError([String message = '']) {
    final glError = glGetError(_gl, );
    if (glError != WebGL.NO_ERROR) {
      final openGLException = OpenGLException('RenderingContext.$message', glError);
      // assert(() {
        angleConsole.warning(openGLException.toString());
      //   return true;
      // }());
      // throw openGLException;
    }
  }

  int getParameter(int key) {
    List<int> _intValues = [
      WebGL.MAX_TEXTURE_IMAGE_UNITS,
      WebGL.MAX_VERTEX_TEXTURE_IMAGE_UNITS,
      WebGL.MAX_TEXTURE_SIZE,
      WebGL.MAX_CUBE_MAP_TEXTURE_SIZE,
      WebGL.MAX_VERTEX_ATTRIBS,
      WebGL.MAX_VERTEX_UNIFORM_VECTORS,
      WebGL.MAX_VARYING_VECTORS,
      WebGL.MAX_FRAGMENT_UNIFORM_VECTORS,
      WebGL.MAX_SAMPLES,
      WebGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS,
      WebGL.SCISSOR_BOX,
      WebGL.VIEWPORT
    ];

    if (_intValues.contains(key)) {
      dynamic val = glGetParameter(_gl, key);
      if(val is JSInt32Array){
        return ByteData.view(Uint8List.fromList(val.toDart).buffer).getUint32(0);
      }
      return val;
    } 
    else {
      return key;
      //throw (" OpenGL getParameter key: ${key} is not support ");
    }
  }

  Future<Image> loadImageFromAsset(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final loadingCompleter = Completer<Image>();
    decodeImageFromList(bytes.buffer.asUint8List(), (image) {
      loadingCompleter.complete(image);
    });
    return loadingCompleter.future;
  }

  Future<void> texImage2DfromImage(
    int target,
    Image image, {
    int level = 0,
    int internalformat = WebGL.RGBA,
    int format = WebGL.RGBA,
    int type = WebGL.UNSIGNED_BYTE,
  }) async {
    final completer = Completer<void>();
    final bytes = (await image.toByteData())!;
    final hblob = html.Blob([bytes].jsify() as JSArray<JSAny>);
    final imageDom = html.HTMLImageElement();
    imageDom.crossOrigin = "";
    imageDom.src = html.URL.createObjectURL(hblob);
    
    imageDom.onLoad.listen((e) {
      completer.complete();
      glTexImage2D_NOSIZE(_gl,target, level, internalformat, format, type, imageDom);
    });
    
    return completer.future;
  }

  Future<void> texImage2DfromAsset(
    int target,
    String asset, {
    int level = 0,
    int internalformat = WebGL.RGBA,
    int format = WebGL.RGBA,
    int type = WebGL.UNSIGNED_BYTE,
  }) async {
    final completer = Completer<void>();
    final imageDom = html.HTMLImageElement();
    imageDom.crossOrigin = "";
    imageDom.src = asset;
    imageDom.onLoad.listen((e) {
      texImage2D_NOSIZE(target, level, internalformat, format, type, imageDom);
      completer.complete();
    });

    return completer.future;
  }

  void texImage2D(
    int target, 
    int level, 
    int internalformat, 
    int width, 
    int height, 
    int border, 
    int format, 
    int type, 
    NativeArray? pixels
  ) {
    glTexImage2D(_gl, target, level, internalformat, width, height, border, format, type, pixels?.data);
    checkError('texImage2D');
  }

  void texImage2D_NOSIZE(    
    int target, 
    int level, 
    int internalformat, 
    int format, 
    int type, 
    html.HTMLElement? pixels
  ) { 
    glTexImage2D_NOSIZE(_gl, target, level, internalformat, format, type, pixels);
    checkError('texImage2D_NOSIZE');
  }

  void texImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, NativeArray? pixels) {
    glTexImage3D(_gl, target, level, internalformat, width, height, depth,border, format, type, pixels?.data);
    checkError('texImage3D');
  }

  void depthFunc(int v0) {
    glDepthFunc(_gl, v0);
    checkError('depthFunc');
  }

  void depthMask(bool v0) {
    glDepthMask(_gl, v0);
    checkError('depthMask');
  }

  void enable(int v0) {
    glEnable(_gl, v0);
    checkError('enable');
  }

  void disable(int v0) {
    glDisable(_gl, v0);
    checkError('disable');
  }

  void blendEquation(int v0) {
    glBlendEquation(_gl, v0);
    checkError('blendEquation');
  }

  void useProgram(Program? program) {
    glUseProgram(_gl, program?.id);
    checkError('useProgram');
  }

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    glBlendFuncSeparate(_gl, srcRGB, dstRGB, srcAlpha, dstAlpha);
    checkError('blendFuncSeparate');
  }

  void blendFunc(int sfactor, int dfactor){
    glBlendFunc(_gl, sfactor, dfactor);
    checkError('blendFunc');
  }

  void blendEquationSeparate(int modeRGB, int modeAlpha){
    glBlendEquationSeparate(_gl, modeRGB, modeAlpha);
    checkError('blendEquationSeparate');
  }

  void frontFace(int mode) {
    glFrontFace(_gl, mode);
    checkError('frontFace');
  }

  void cullFace(int mode) {
    glCullFace(_gl, mode);
    checkError('cullFace');
  }

  void lineWidth(double width) {
    glLineWidth(_gl, width);
    checkError('lineWidth');
  }

  void polygonOffset(double factor, double units) {
    glPolygonOffset(_gl, factor, units);
    checkError('polygonOffset');
  }

  void stencilMask(int mask) {
    glStencilMask(_gl, mask);
    checkError('stencilMask');
  }

  void stencilFunc(int func, int ref, int mask){
    glStencilFunc(_gl, func, ref, mask);
    checkError('stencilFunc');
  }

  void stencilOp(int fail, int zfail, int zpass){
    glStencilOp(_gl, fail, zfail, zpass);
    checkError('stencilOp');
  }

  void clearStencil(int s) {
    glClearStencil(_gl, s);
    checkError('clearStencil');
  }

  void clearDepth(double depth){
    glClearDepth(_gl, depth);
    checkError('clearDepth');
  }

  void colorMask(bool red, bool green, bool blue, bool alpha){
    glColorMask(_gl, red, green, blue, alpha);
    checkError('colorMask');
  }

  void clearColor(double red, double green, double blue, double alpha){
    glClearColor(_gl, red, green, blue, alpha);
    checkError('clearColor');
  }

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, NativeArray? data){
    glCompressedTexImage2D(_gl, target, level, internalformat, width, height, border, data?.data);
    checkError('compressedTexImage2D');
  }

  void generateMipmap(int target) {
    glGenerateMipmap(_gl, target);
    checkError('generateMipmap');
  }

  void deleteTexture(WebGLTexture? texture) {
    glDeleteTexture(_gl, texture?.id);
    checkError('deleteTexture');
  }

  void deleteFramebuffer(Framebuffer? framebuffer) {
    glDeleteFramebuffer(_gl, framebuffer?.id);
    checkError('deleteFramebuffer');
  }

  void deleteRenderbuffer(Renderbuffer? renderbuffer) {
    glDeleteRenderbuffer(_gl, renderbuffer?.id);
    checkError('deleteRenderbuffer');
  }

  void texParameterf(int target, int pname, double param) {
    glTexParameterf(_gl, target, pname, param);
    checkError('texParameterf');
  }

  void pixelStorei(int pname, int param) {
    glPixelStorei(_gl, pname, param);
    checkError('pixelStorei');
  }

  dynamic getContextAttributes() {
    return glGetContextAttributes(_gl);
  }

  WebGLParameter getProgramParameter(Program program, int pname) {
    return WebGLParameter(glGetProgramParameter(_gl, program.id, pname));
  }

  ActiveInfo getActiveUniform(Program v0, v1) {
    final dynamic val = glGetActiveUniform(_gl, v0.id, v1);
    return ActiveInfo(
      val.type,
      val.name,
      val.size
    );
  }
  
  ActiveInfo getActiveAttrib(Program v0, v1) {
    final dynamic val = glGetActiveAttrib(_gl, v0.id, v1);
    return ActiveInfo(
      val.type,
      val.name,
      val.size
    );
  }

  UniformLocation getUniformLocation(Program program, String name) {
    return UniformLocation(glGetUniformLocation(_gl, program.id, name));
  }

  void clear(int mask) {
    glClear(_gl, mask);
    checkError('clear');
  }

  Buffer createBuffer() {
    return Buffer(glCreateBuffer(_gl, ));
  }

  void clearBufferuiv(int buffer,int drawbuffer, int value){
    glClearBufferuiv(_gl, buffer,drawbuffer,value);
    checkError('clearBufferuiv');
  }

  void clearBufferiv(int buffer,int drawbuffer, int value){
    glClearBufferiv(_gl, buffer,drawbuffer,value);
    checkError('clearBufferiv');
  }

  void bindBuffer(int target, Buffer? buffer) {
    glBindBuffer(_gl, target, buffer?.id);
    checkError('bindBuffer');
  }
  void bindBufferBase(int target,int index, Buffer? buffer){
    glBindBufferBase(_gl, target, index, buffer?.id);
    checkError('bindBufferBase');
  }
  // void bufferData(int target, offset, int? usage) {
  //   glBufferData(_gl, target, offset, usage);
  //   checkError('bufferData');
  // }
  /// Be careful which type of integer you really pass here. Unfortunately an UInt16List
  /// is viewed by the Dart type system just as List<int>, so we jave to specify the native type
  /// here in [nativeType]
  void bufferData(int target, dynamic data, int? usage) {
    if(data is int){
      glBufferDatai(_gl, target, data, usage ?? 0);
    }
    else{
      glBufferData(_gl, target, (data.data as TypedData).jsify(), usage ?? 0);
    }
    
    checkError('bufferData');
  }
  void vertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset) {
    glVertexAttribPointer(_gl, index, size, type, normalized, stride, offset);
    checkError('vertexAttribPointer');
  }

  void drawArrays(int mode, int first, int count) {
    glDrawArrays(_gl, mode, first, count);
    checkError('drawArrays');
  }

  void drawArraysInstanced(int mode, int first, int count, int instanceCount){
    glDrawArraysInstanced(_gl, mode, first, count, instanceCount);
    checkError('drawArraysInstanced');
  }

  void bindFramebuffer(int target, Framebuffer? framebuffer){
    glBindFramebuffer(_gl, target, framebuffer?.id);
    checkError('bindFramebuffer');
  }
  
  int checkFramebufferStatus(int target) {
    return glCheckFramebufferStatus(_gl, target);
  }
  void framebufferTextureLayer(int target,int attachment,int texture,int level,int layer){
    glFramebufferTextureLayer(_gl, target, attachment, texture, level, layer);
    checkError('framebufferTextureLayer');
  }
  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture? texture, int level){
    glFramebufferTexture2D(_gl, target, attachment, textarget, texture?.id, level);
    checkError('framebufferTexture2D');
  }

  void readPixels(int x, int y, int width, int height, int format, int type,pixels) {
    glReadPixels(_gl, x, y, width, height, format, type, pixels);
    checkError('readPixels');
  }

  bool isProgram(Program program){
    return glIsProgram(_gl, program.id) != 0;
  }

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border){
    glCopyTexImage2D(_gl, target, level, internalformat, x, y, width, height, border);
    checkError('copyTexImage2D');
  }

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height){
    glCopyTexSubImage2D(_gl, target, level, xoffset, yoffset, x, y, width, height);
    checkError('copyTexSubImage2D');
  }

  void copyTexSubImage3D(int target, int level, int xoffset, int yoffset, int zoffset, int x, int y, int width, int height){
    glCopyTexSubImage3D(_gl, target, level, xoffset, yoffset, zoffset, x, y, width, height);
    checkError('copyTexSubImage3D');
  }

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, pixels) {
    glTexSubImage2D(_gl, target, level, xoffset, yoffset, width, height, format, type, pixels?.data);
    checkError('texSubImage2D');
  }

  void texSubImage2D_NOSIZE(int target, int level, int xoffset, int yoffset, int format, int type, pixels){
    glTexSubImage2D_NOSIZE(_gl, target, level, xoffset, yoffset, format, type, pixels);
    checkError('texSubImage2D_NOSIZE');
  }

  void texSubImage3D(
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
    NativeArray? pixels
  ) {
    glTexSubImage3D(_gl, target, level, xoffset, yoffset, zoffset, width,height, depth, format, type, pixels?.data);
    checkError('texSubImage3D');
  }

  void compressedTexSubImage3D(
    int target,
    int level,
    int xoffset,
    int yoffset,
    int zoffset,
    int width,
    int height,
    int depth,
    int format,
    NativeArray? pixels,
  ){
    glCompressedTexSubImage3D(_gl, target,level,xoffset,yoffset,zoffset,width,height,depth,format,pixels?.data);
    checkError('compressedTexSubImage3D');
  }

  void compressedTexImage3D(
    int target,
    int level,
    int internalformat,
    int width,
    int height,
    int depth,
    int border,
    NativeArray? pixels,
  ){
    glCompressedTexImage3D(_gl, target,level,internalformat,width,height,depth,border,pixels?.data);
    checkError('compressedTexImage3D');
  }

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, NativeArray? pixels) {
    glCompressedTexSubImage2D(_gl, target, level, xoffset, yoffset, width, height, format, pixels?.data);
    checkError('compressedTexSubImage2D');
  }

  void bindRenderbuffer(int target, Renderbuffer? framebuffer){
    glBindRenderbuffer(_gl, target, framebuffer?.id);
    checkError('bindRenderbuffer');
  }

  void renderbufferStorageMultisample(int target, int samples, int internalformat, int width, int height){
    glRenderbufferStorageMultisample(_gl, target, samples, internalformat, width, height);
    checkError('renderbufferStorageMultisample');
  }

  void renderbufferStorage(int target, int internalformat, int width, int height){
    glRenderbufferStorage(_gl, target, internalformat, width, height);
    checkError('renderbufferStorage');
  }

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer? renderbuffer){
    glFramebufferRenderbuffer(_gl, target, attachment, renderbuffertarget, renderbuffer?.id);
    checkError('framebufferRenderbuffer');
  }

  Renderbuffer createRenderbuffer() {
    return Renderbuffer(glCreateRenderbuffer(_gl, ));
  }

  Framebuffer createFramebuffer() {
    return Framebuffer(glCreateFramebuffer(_gl, ));
  }

  void blitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter){
    glBlitFramebuffer(_gl, srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
    checkError('blitFramebuffer');
  }

  void bufferSubData(int target, int dstByteOffset, NativeArray srcData){
    glBufferSubData(_gl, target, dstByteOffset, srcData.data);
    checkError('bufferSubData');
  }

  VertexArrayObject createVertexArray() {
    return VertexArrayObject(glCreateVertexArray(_gl));
  }

  Program createProgram() {
    return Program(glCreateProgram(_gl));
  }

  void attachShader(Program program, WebGLShader shader) {
    glAttachShader(_gl, program.id, shader.id);
    checkError('attachShader');
  }

  void bindAttribLocation(Program program, int index, String name){
    glBindAttribLocation(_gl, program.id, index, name);
    checkError('bindAttribLocation');
  }

  void linkProgram(Program program, [bool checkForErrors = true]) {
    glLinkProgram(_gl, program.id);
    checkError('linkProgram');
  }

  String? getProgramInfoLog(Program program){
    return glGetProgramInfoLog(_gl, program.id);
  }

  String? getShaderInfoLog(WebGLShader shader) {
    return glGetShaderInfoLog(_gl, shader.id);
  }

  int getError() {
    return glGetError(_gl, );
  }

  void deleteShader(WebGLShader shader) {
    glDeleteShader(_gl, shader.id);
    checkError('deleteShader');
  }

  void deleteProgram(Program program) {
    glDeleteProgram(_gl, program.id);
    checkError('deleteProgram');
  }

  void deleteBuffer(Buffer buffer) {
    glDeleteBuffer(_gl, buffer.id);
    checkError('deleteBuffer');
  }

  void bindVertexArray(VertexArrayObject array) {
    glBindVertexArray(_gl, array.id);
    checkError('bindVertexArray');
  }

  void deleteVertexArray(VertexArrayObject array) {
    glDeleteVertexArray(_gl, array.id);
    checkError('deleteVertexArray');
  }

  void enableVertexAttribArray(int index) {
    glEnableVertexAttribArray(_gl, index);
    checkError('enableVertexAttribArray');
  }

  void disableVertexAttribArray(int index) {
    glDisableVertexAttribArray(_gl, index);
    checkError('disableVertexAttribArray');
  }

  void vertexAttribIPointer(int index, int size, int type, int stride, int pointer){
    glVertexAttribIPointer(_gl, index, size, type, stride, pointer);
    checkError('vertexAttribIPointer');
  }

  void vertexAttrib2fv(int index, NativeArray<double> values) {
    glVertexAttrib2fv(_gl, index, values.data);
    checkError('vertexAttrib2fv');
  }

  void vertexAttrib3fv(int index, NativeArray<double> values) {
    glVertexAttrib3fv(_gl, index, values.data);
    checkError('vertexAttrib3fv');
  }

  void vertexAttrib4fv(int index, NativeArray<double> values) {
    glVertexAttrib4fv(_gl, index, values.data);
    checkError('vertexAttrib4fv');
  }

  void vertexAttrib1fv(int index, NativeArray<double> values) {
    glVertexAttrib1fv(_gl, index, values.data);
    checkError('vertexAttrib1fv');
  }

  void drawElements(int mode, int count, int type, int offset) {
    glDrawElements(_gl, mode, count, type, offset);
    checkError('drawElements');
  }

  void drawBuffers(NativeArray buffers) {
    glDrawBuffers(_gl, buffers.data);
    checkError('drawBuffers');
  }

  WebGLShader createShader(int type) {
    return WebGLShader(glCreateShader(_gl, type));
  }

  void shaderSource(WebGLShader shader, String shaderSource) {
    glShaderSource(_gl, shader.id, shaderSource);
    checkError('shaderSource');
  }

  void compileShader(WebGLShader shader) {
    glCompileShader(_gl, shader.id);
    checkError('compileShader');
  }

  bool getShaderParameter(WebGLShader shader, int pname){
    return glGetShaderParameter(_gl, shader.id, pname);
  }

  String? getShaderSource(WebGLShader shader) {
    return glGetShaderSource(_gl, shader.id);
  }

  void uniform1i(UniformLocation location, int x) {
    glUniform1i(_gl, location.id, x);
    checkError('uniform1i');
  }

  void uniform3f(UniformLocation location, double x, double y, double z) {
    glUniform3f(_gl, location.id, x, y, z);
    checkError('uniform3f');
  }

  void uniform4f(UniformLocation location, double x, double y, double z, double w){
    glUniform4f(_gl, location.id, x, y, z,w);
    checkError('uniform4f');
  }

  void uniform1fv(UniformLocation location, List<double> v){
    glUniform1fv(_gl, location.id, v.jsify());
    checkError('uniform1fv');
  }

  void uniform2fv(UniformLocation location, List<double> v){
    glUniform2fv(_gl, location.id, v.jsify());
    checkError('uniform2fv');
  }

  void uniform3fv(UniformLocation location, List<double> v){
    glUniform3fv(_gl, location.id, v.jsify());
    checkError('uniform3fv');
  }

  void uniform1f(UniformLocation location, double x){
    glUniform1f(_gl, location.id, x);
    checkError('uniform1f');
  }
  void uniformMatrix2fv(UniformLocation location, bool transpose, List<double> values) {
    glUniformMatrix2fv(_gl, location.id, transpose, values.jsify());
    checkError('uniformMatrix2fv');
  }

  void uniformMatrix3fv(UniformLocation location, bool transpose, List<double> values) {
    glUniformMatrix3fv(_gl, location.id, transpose, values.jsify());
    checkError('uniformMatrix3fv');
  }

  void uniformMatrix4fv(UniformLocation location, bool transpose, List<double> values) {
    glUniformMatrix4fv(_gl, location.id, transpose, values.jsify());
    checkError('uniformMatrix4fv');
  }

  UniformLocation getAttribLocation(Program program, String name) {
    return UniformLocation(glGetAttribLocation(_gl, program.id, name));
  }

  void uniform2f(UniformLocation location, double x, double y){
    glUniform2f(_gl, location.id, x, y);
    checkError('uniform2f');
  }

  void uniform1iv(UniformLocation location, List<int> v){
    glUniform1iv(_gl, location.id, v.jsify());
    checkError('uniform1iv');
  }

  void uniform2iv(UniformLocation location, List<int> v){
    glUniform2iv(_gl, location.id, v.jsify());
    checkError('uniform2iv');
  }

  void uniform3iv(UniformLocation location, List<int> v){
    glUniform3iv(_gl, location.id, v.jsify());
    checkError('uniform3iv');
  }

  void uniform4iv(UniformLocation location, List<int> v){
    glUniform4iv(_gl, location.id, v.jsify());
    checkError('uniform4iv');
  }

  void uniform1uiv(UniformLocation? location, List<int> v){
    glUniform1uiv(_gl, location?.id, v.jsify());
    checkError('uniform1uiv');
  }
  
  void uniform2uiv(UniformLocation? location, List<int> v){
    glUniform2uiv(_gl, location?.id, v.jsify());
    checkError('uniform2uiv');
  }

  void uniform3uiv(UniformLocation? location, List<int> v){
    glUniform3uiv(_gl, location?.id, v.jsify());
    checkError('uniform3uiv');
  }

  void uniform4uiv(UniformLocation? location, List<int> v){
    glUniform4uiv(_gl, location?.id, v.jsify());
    checkError('uniform4uiv');
  }

  void uniform1ui(UniformLocation? location, int v0){
    glUniform1ui(_gl, location?.id, v0);
    checkError('uniform1ui');
  }

  void uniform2ui(UniformLocation? location, int v0, int v1){
    glUniform2ui(_gl, location?.id, v0, v1);
    checkError('uniform2ui');
  }

  void uniform3ui(UniformLocation? location, int v0, int v1, int v2){
    glUniform3ui(_gl, location?.id, v0, v1, v2);
    checkError('uniform2ui');
  }

  void uniform4ui(UniformLocation? location, int v0, int v1, int v2, int v3){
    glUniform4ui(_gl, location?.id, v0, v1, v2, v3);
    checkError('uniform2ui');
  }

  void uniform4fv(UniformLocation location, List<double> vectors) {
    glUniform4fv(_gl, location.id, vectors.jsify());
    checkError('uniform4fv');
  }

  void vertexAttribDivisor(int index, int divisor){
    glVertexAttribDivisor(_gl, index, divisor);
    checkError('vertexAttribDivisor');
  }

  void flush() {
    glFlush(_gl, );
  }

  void finish() {
    glFinish(_gl, );
  }

  void texStorage2D(int target, int levels, int internalformat, int width, int height){
    glTexStorage2D(_gl, target, levels, internalformat, width, height);
    checkError('texStorage2D');
  }

  void texStorage3D(int target, int levels, int internalformat, int width, int height, int depth){
    glTexStorage3D(_gl, target, levels, internalformat, width, height, depth);
    checkError('texStorage3D');
  }

  TransformFeedback createTransformFeedback() {
    return TransformFeedback(glCreateTransformFeedback(_gl, ));
  }
  
  void bindTransformFeedback(int target, TransformFeedback feedbeck){
    glBindTransformFeedback(_gl, target, feedbeck.id);
    checkError('bindTransformFeedback');
  }

  void transformFeedbackVaryings(Program program, int count, List<String> varyings, int bufferMode) {
    glTransformFeedbackVaryings(_gl, program.id, varyings.jsify(), bufferMode);
    checkError('transformFeedbackVaryings');
  }

  void deleteTransformFeedback(TransformFeedback transformFeedback) {
    glDeleteTransformFeedback(_gl, transformFeedback.id);
    checkError('deleteTransformFeedback');
  }

  bool isTransformFeedback(TransformFeedback transformFeedback) {
    return glIsTransformFeedback(_gl, transformFeedback.id);
  }

  void beginTransformFeedback(int primitiveMode) {
    glBeginTransformFeedback(_gl, primitiveMode);
    checkError('beginTransformFeedback');
  }

  void endTransformFeedback() {
    glEndTransformFeedback(_gl, );
    checkError('endTransformFeedback');
  }

  void pauseTransformFeedback() {
    glPauseTransformFeedback(_gl, );
    checkError('pauseTransformFeedback');
  }

  void resumeTransformFeedback() {
    glResumeTransformFeedback(_gl, );
    checkError('resumeTransformFeedback');
  }

  ActiveInfo getTransformFeedbackVarying( program, int index) {
    dynamic temp = glGetTransformFeedbackVarying(_gl, program, index);
    return ActiveInfo(temp['type'], temp['name'], temp['size']);
  }

  void invalidateFramebuffer(int target, List<int> attachments){
    glInvalidateFramebuffer(_gl, target, attachments.jsify());
    checkError('invalidateFramebuffer');
  }
}