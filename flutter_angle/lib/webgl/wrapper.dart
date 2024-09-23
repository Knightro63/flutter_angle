import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_angle/native-array/index.dart';
import 'package:flutter_angle/shared/console.dart';
import 'package:web/web.dart' as html;
import '../shared/webgl.dart';
import '../shared/classes.dart';
import 'dart:async';
import 'dart:ui';
import 'gles_bindings.dart';
import './webgl2_extensions.dart';

class RenderingContext{
  final LibOpenGLES gl;
  late final html.WebGL2RenderingContext _gl;
  final int width;
  final int height;

  RenderingContext.create(this.gl, this.width, this.height){
    print(gl.gl);
    _gl = gl.gl;
  }

  void scissor(int x, int y, int width, int height){
    startCheck('scissor');
    _gl.scissor(x, y, width, height);
    checkError('scissor');
  }

  void viewport(int x, int y, int width, int height) {
    startCheck('viewport');
    _gl.viewport(x, y, width, height);
    checkError('viewport');
  }

  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) {
    startCheck('getShaderPrecisionFormat');
    return ShaderPrecisionFormat();
  }

  Object? getExtension(String key) {
    startCheck('getExtension');
    return _gl.getExtension(key);
  }
  int getUniformBlockIndex(Program program, String uniformBlockName){
    startCheck('getUniformBlockIndex');
    return _gl.glGetUniformBlockIndex(program.id, uniformBlockName);
  }

  void uniformBlockBinding(Program program, int uniformBlockIndex,int uniformBlockBinding){
    startCheck('uniformBlockBinding');
    _gl.glUniformBlockBinding(program.id,uniformBlockIndex,uniformBlockBinding);
  }
  // getParameter(key) {
  //   _gl.getParameter(key);
  // }

  // getString(String key) {
  //   _gl.getParameter(key);
  // }

  WebGLTexture createTexture() {
    startCheck('createTexture');
    return WebGLTexture(_gl.createTexture());
  }

  void bindTexture(int target, WebGLTexture? texture) {
    if(texture == null) return;
    startCheck('bindTexture');
    _gl.bindTexture(target, texture.id);
    checkError('bindTexture');
  }

  void drawElementsInstanced(int mode, int count, int type, int offset, int instanceCount) {
    startCheck('drawElementsInstanced');
    _gl.drawElementsInstanced(mode, count, type, offset, instanceCount);
    checkError('drawElementsInstanced');
  }

  void activeTexture(int v0) {
    startCheck('activeTexture');
    _gl.activeTexture(v0);
    checkError('activeTexture');
  }

  void texParameteri(int target, int pname, int param) {
    startCheck('texParameteri');
    _gl.texParameteri(target, pname, param);
    checkError('texParameteri');
  }
  
  void startCheck(String type){
    angleConsole.info('Start: $type');
  }

  void checkError([String message = '']) {
    final glError = _gl.getError();
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
      dynamic val = _gl.getParameter(key);
      if(val is List<int>){
        return ByteData.view(Uint8List.fromList(val).buffer).getUint32(0);
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
      texImage2D_NOSIZE(target, level, internalformat, format, type, imageDom);
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
    startCheck('texImage2D');
    _gl.texImage2D(target, level, internalformat, width.jsify()!, height.jsify()!, border.jsify()!, format, type, pixels?.data);
    checkError('texImage2D');
  }

  void texImage2D_NOSIZE(    
    int target, 
    int level, 
    int internalformat, 
    int format, 
    int type, 
    html.Element? pixels
  ) { 
    startCheck('texImage2D_NOSIZE');
    _gl.texImage2D(target, level, internalformat, format.jsify()!, type.jsify()!, pixels.jsify()!);
    checkError('texImage2D_NOSIZE');
  }

  void texImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, NativeArray? pixels) {
    startCheck('texImage3D');
    _gl.texImage3D(target, level, internalformat, width, height, depth,border, format, type, pixels?.data);
    checkError('texImage3D');
  }

  void depthFunc(int v0) {
    startCheck('depthFunc');
    _gl.depthFunc(v0);
    checkError('depthFunc');
  }

  void depthMask(bool v0) {
    startCheck('depthMask');
    _gl.depthMask(v0);
    checkError('depthMask');
  }

  void enable(int v0) {
    startCheck('enable');
    _gl.enable(v0);
    checkError('enable');
  }

  void disable(int v0) {
    startCheck('disable');
    _gl.disable(v0);
    checkError('disable');
  }

  void blendEquation(int v0) {
    startCheck('blendEquation');
    _gl.blendEquation(v0);
    checkError('blendEquation');
  }

  void useProgram(Program? program) {
    startCheck('useProgram');
    _gl.useProgram(program?.id);
    checkError('useProgram');
  }

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    startCheck('blendFuncSeparate');
    _gl.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
    checkError('blendFuncSeparate');
  }

  void blendFunc(int sfactor, int dfactor){
    startCheck('blendFunc');
    _gl.blendFunc(sfactor, dfactor);
    checkError('blendFunc');
  }

  void blendEquationSeparate(int modeRGB, int modeAlpha){
    startCheck('blendEquationSeparate');
    _gl.blendEquationSeparate(modeRGB, modeAlpha);
    checkError('blendEquationSeparate');
  }

  void frontFace(int mode) {
    startCheck('frontFace');
    _gl.frontFace(mode);
    checkError('frontFace');
  }

  void cullFace(int mode) {
    startCheck('cullFace');
    _gl.cullFace(mode);
    checkError('cullFace');
  }

  void lineWidth(double width) {
    startCheck('lineWidth');
    _gl.lineWidth(width);
    checkError('lineWidth');
  }

  void polygonOffset(double factor, double units) {
    startCheck('polygonOffset');
    _gl.polygonOffset(factor, units);
    checkError('polygonOffset');
  }

  void stencilMask(int mask) {
    startCheck('stencilMask');
    _gl.stencilMask(mask);
    checkError('stencilMask');
  }

  void stencilFunc(int func, int ref, int mask){
    startCheck('stencilFunc');
    _gl.stencilFunc(func, ref, mask);
    checkError('stencilFunc');
  }

  void stencilOp(int fail, int zfail, int zpass){
    startCheck('stencilOp');
    _gl.stencilOp(fail, zfail, zpass);
    checkError('stencilOp');
  }

  void clearStencil(int s) {
    startCheck('clearStencil');
    _gl.clearStencil(s);
    checkError('clearStencil');
  }

  void clearDepth(double depth){
    startCheck('clearDepth');
    _gl.clearDepth(depth);
    checkError('clearDepth');
  }

  void colorMask(bool red, bool green, bool blue, bool alpha){
    startCheck('colorMask');
    _gl.colorMask(red, green, blue, alpha);
    checkError('colorMask');
  }

  void clearColor(double red, double green, double blue, double alpha){
    startCheck('clearColor');
    _gl.clearColor(red, green, blue, alpha);
    checkError('clearColor');
  }

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, NativeArray? data){
    startCheck('compressedTexImage2D');
    _gl.compressedTexImage2D(target, level, internalformat, width, height, border, data?.data);
    checkError('compressedTexImage2D');
  }

  void generateMipmap(int target) {
    startCheck('generateMipmap');
    _gl.generateMipmap(target);
    checkError('generateMipmap');
  }

  void deleteTexture(WebGLTexture? texture) {
    startCheck('deleteTexture');
    _gl.deleteTexture(texture?.id);
    checkError('deleteTexture');
  }

  void deleteFramebuffer(Framebuffer? framebuffer) {
    startCheck('deleteFramebuffer');
    _gl.deleteFramebuffer(framebuffer?.id);
    checkError('deleteFramebuffer');
  }

  void deleteRenderbuffer(Renderbuffer? renderbuffer) {
    startCheck('deleteRenderbuffer');
    _gl.deleteRenderbuffer(renderbuffer?.id);
    checkError('deleteRenderbuffer');
  }

  void texParameterf(int target, int pname, double param) {
    startCheck('texParameterf');
    _gl.texParameterf(target, pname, param);
    checkError('texParameterf');
  }

  void pixelStorei(int pname, int param) {
    startCheck('pixelStorei');
    _gl.pixelStorei(pname, param);
    checkError('pixelStorei');
  }

  dynamic getContextAttributes() {
    startCheck('getContextAttributes');
    return _gl.getContextAttributes();
  }

  WebGLParameter getProgramParameter(Program program, int pname) {
    startCheck('getProgramParameter');
    return WebGLParameter(_gl.getProgramParameter(program.id, pname));
  }

  ActiveInfo getActiveUniform(Program v0, v1) {
    startCheck('getActiveUniform');
    final val = _gl.getActiveUniform(v0.id, v1)!;
    return ActiveInfo(
      val.type,
      val.name,
      val.size
    );
  }
  
  ActiveInfo getActiveAttrib(Program v0, v1) {
    startCheck('getActiveAttrib');
    final val = _gl.getActiveAttrib(v0.id, v1)!;
    return ActiveInfo(
      val.type,
      val.name,
      val.size
    );
  }

  UniformLocation getUniformLocation(Program program, String name) {
    startCheck('getUniformLocation');
    return UniformLocation(_gl.getUniformLocation(program.id, name));
  }

  void clear(int mask) {
    startCheck('clear');
    _gl.clear(mask);
    checkError('clear');
  }

  Buffer createBuffer() {
    startCheck('createBuffer');
    return Buffer(_gl.createBuffer());
  }

  void clearBufferuiv(int buffer,int drawbuffer, int value){
    startCheck('clearBufferuiv');
    _gl.clearBufferuiv(buffer,drawbuffer,value.jsify() as JSObject);
    checkError('clearBufferuiv');
  }

  void clearBufferiv(int buffer,int drawbuffer, int value){
    startCheck('clearBufferiv');
    _gl.clearBufferiv(buffer,drawbuffer,value.jsify() as JSObject);
    checkError('clearBufferiv');
  }

  void bindBuffer(int target, Buffer? buffer) {
    startCheck('bindBuffer');
    _gl.bindBuffer(target, buffer?.id);
    checkError('bindBuffer');
  }
  void bindBufferBase(int target,int index, Buffer? buffer){
    startCheck('bindBufferBase');
    _gl.bindBufferBase(target, index, buffer?.id);
    checkError('bindBufferBase');
  }
  void bufferData(int target, NativeArray data, int usage) {
    startCheck('bufferData');
    _gl.bufferData(target, data.data, usage);
    checkError('bufferData');
  }

  void vertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset) {
    startCheck('vertexAttribPointer');
    _gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
    checkError('vertexAttribPointer');
  }

  void drawArrays(int mode, int first, int count) {
    startCheck('drawArrays');
    _gl.drawArrays(mode, first, count);
    checkError('drawArrays');
  }

  void drawArraysInstanced(int mode, int first, int count, int instanceCount){
    startCheck('drawArraysInstanced');
    _gl.drawArraysInstanced(mode, first, count, instanceCount);
    checkError('drawArraysInstanced');
  }

  void bindFramebuffer(int target, Framebuffer? framebuffer){
    startCheck('bindFramebuffer');
    _gl.bindFramebuffer(target, framebuffer?.id);
    checkError('bindFramebuffer');
  }
  
  int checkFramebufferStatus(int target) {
    startCheck('checkFramebufferStatus');
    return _gl.checkFramebufferStatus(target);
  }
  void framebufferTextureLayer(int target,int attachment,WebGLTexture? texture,int level,int layer){
    startCheck('framebufferTextureLayer');
    _gl.framebufferTextureLayer(target, attachment, texture?.id, level, layer);
    checkError('framebufferTextureLayer');
  }
  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture? texture, int level){
    startCheck('framebufferTexture2D');
    _gl.framebufferTexture2D(target, attachment, textarget, texture?.id, level);
    checkError('framebufferTexture2D');
  }

  void readPixels(int x, int y, int width, int height, int format, int type,pixels) {
    startCheck('readPixels');
    _gl.readPixels(x, y, width, height, format, type, pixels);
    checkError('readPixels');
  }

  bool isProgram(Program program){
    startCheck('isProgram');
    return _gl.isProgram(program.id) != 0;
  }

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border){
    startCheck('copyTexImage2D');
    _gl.copyTexImage2D(target, level, internalformat, x, y, width, height, border);
    checkError('copyTexImage2D');
  }

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height){
    startCheck('copyTexSubImage2D');
    _gl.copyTexSubImage2D(target, level, xoffset, yoffset, x,y,width, height);
    checkError('copyTexSubImage2D');
  }

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, pixels) {
    startCheck('texSubImage2D');
    _gl.texSubImage2D(target, level, xoffset, yoffset, width.jsify()!, height.jsify()!, format.jsify()!,type, pixels?.data);
    checkError('texSubImage2D');
  }

  void texSubImage2D_NOSIZE(int target, int level, int xoffset, int yoffset, int format, int type, pixels){
    startCheck('texSubImage2D_NOSIZE');
    _gl.texSubImage2D(target, level, xoffset, yoffset, format.jsify()!, type.jsify()!, pixels);
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
    startCheck('texSubImage3D');
    _gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width,height, depth, format, type, pixels?.data);
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
    startCheck('compressedTexSubImage3D');
    _gl.compressedTexSubImage3D(target,level,xoffset,yoffset,zoffset,width,height,depth,format,pixels?.data);
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
    startCheck('compressedTexImage3D');
    _gl.compressedTexImage3D(target,level,internalformat,width,height,depth,border,pixels?.data);
    checkError('compressedTexImage3D');
  }

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, NativeArray? pixels) {
    startCheck('compressedTexSubImage2D');
    _gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, pixels?.data);
    checkError('compressedTexSubImage2D');
  }

  void bindRenderbuffer(int target, Renderbuffer? framebuffer){
    startCheck('bindRenderbuffer');
    _gl.bindRenderbuffer(target, framebuffer?.id);
    checkError('bindRenderbuffer');
  }

  void renderbufferStorageMultisample(int target, int samples, int internalformat, int width, int height){
    startCheck('renderbufferStorageMultisample');
    _gl.renderbufferStorageMultisample(target, samples, internalformat, width, height);
    checkError('renderbufferStorageMultisample');
  }

  void renderbufferStorage(int target, int internalformat, int width, int height){
    startCheck('renderbufferStorage');
    _gl.renderbufferStorage(target, internalformat, width, height);
    checkError('renderbufferStorage');
  }

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer? renderbuffer){
    startCheck('framebufferRenderbuffer');
    _gl.framebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer?.id);
    checkError('framebufferRenderbuffer');
  }

  Renderbuffer createRenderbuffer() {
    startCheck('createRenderbuffer');
    return Renderbuffer(_gl.createRenderbuffer());
  }

  Framebuffer createFramebuffer() {
    startCheck('createFramebuffer');
    return Framebuffer(_gl.createFramebuffer());
  }

  void blitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter){
    startCheck('blitFramebuffer');
    _gl.blitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
    checkError('blitFramebuffer');
  }

  void bufferSubData(int target, int dstByteOffset, NativeArray srcData){
    startCheck('bufferSubData');
    _gl.bufferSubData(target, dstByteOffset, srcData.data);
    checkError('bufferSubData');
  }

  VertexArrayObject createVertexArray() {
    startCheck('createVertexArray');
    return VertexArrayObject(_gl.createVertexArray());
  }

  Program createProgram() {
    startCheck('createProgram');
    return Program(_gl.createProgram());
  }

  void attachShader(Program program, WebGLShader shader) {
    startCheck('attachShader');
    _gl.attachShader(program.id, shader.id);
    checkError('attachShader');
  }

  void bindAttribLocation(Program program, int index, String name){
    startCheck('bindAttribLocation');
    _gl.bindAttribLocation(program.id, index, name);
    checkError('bindAttribLocation');
  }

  void linkProgram(Program program, [bool checkForErrors = true]) {
    startCheck('linkProgram');
    _gl.linkProgram(program.id);
    checkError('linkProgram');
  }

  String? getProgramInfoLog(Program program){
    startCheck('getProgramInfoLog');
    return _gl.getProgramInfoLog(program.id);
  }

  String? getShaderInfoLog(WebGLShader shader) {
    startCheck('getShaderInfoLog');
    return _gl.getShaderInfoLog(shader.id);
  }

  int getError() {
    return _gl.getError();
  }

  void deleteShader(WebGLShader shader) {
    startCheck('deleteShader');
    _gl.deleteShader(shader.id);
    checkError('deleteShader');
  }

  void deleteProgram(Program program) {
    startCheck('deleteProgram');
    _gl.deleteProgram(program.id);
    checkError('deleteProgram');
  }

  void deleteBuffer(Buffer buffer) {
    startCheck('deleteBuffer');
    _gl.deleteBuffer(buffer.id);
    checkError('deleteBuffer');
  }

  void bindVertexArray(VertexArrayObject array) {
    startCheck('bindVertexArray');
    _gl.bindVertexArray(array.id);
    checkError('bindVertexArray');
  }

  void deleteVertexArray(VertexArrayObject array) {
    startCheck('deleteVertexArray');
    _gl.deleteVertexArray(array.id);
    checkError('deleteVertexArray');
  }

  void enableVertexAttribArray(int index) {
    startCheck('enableVertexAttribArray');
    _gl.enableVertexAttribArray(index);
    checkError('enableVertexAttribArray');
  }

  void disableVertexAttribArray(int index) {
    startCheck('disableVertexAttribArray');
    _gl.disableVertexAttribArray(index);
    checkError('disableVertexAttribArray');
  }

  void vertexAttribIPointer(int index, int size, int type, int stride, int pointer){
    startCheck('vertexAttribIPointer');
    _gl.vertexAttribIPointer(index, size, type, stride, pointer);
    checkError('vertexAttribIPointer');
  }

  void vertexAttrib2fv(int index, NativeArray<double> values) {
    startCheck('vertexAttrib2fv');
    _gl.vertexAttrib2fv(index, values.data);
    checkError('vertexAttrib2fv');
  }

  void vertexAttrib3fv(int index, NativeArray<double> values) {
    startCheck('vertexAttrib3fv');
    _gl.vertexAttrib3fv(index, values.data);
    checkError('vertexAttrib3fv');
  }

  void vertexAttrib4fv(int index, NativeArray<double> values) {
    startCheck('vertexAttrib4fv');
    _gl.vertexAttrib4fv(index, values.data);
    checkError('vertexAttrib4fv');
  }

  void vertexAttrib1fv(int index, NativeArray<double> values) {
    startCheck('vertexAttrib1fv');
    _gl.vertexAttrib1fv(index, values.data);
    checkError('vertexAttrib1fv');
  }

  void drawElements(int mode, int count, int type, int offset) {
    startCheck('drawElements');
    _gl.drawElements(mode, count, type, offset);
    checkError('drawElements');
  }

  void drawBuffers(Uint32Array buffers) {
    startCheck('drawBuffers');
    _gl.drawBuffers(buffers.data.jsify() as JSArray<JSNumber>);
    checkError('drawBuffers');
  }

  WebGLShader createShader(int type) {
    startCheck('createShader');
    return WebGLShader(_gl.createShader(type));
  }

  void shaderSource(WebGLShader shader, String shaderSource) {
    startCheck('shaderSource');
    _gl.shaderSource(shader.id, shaderSource);
    checkError('shaderSource');
  }

  void compileShader(WebGLShader shader) {
    startCheck('compileShader');
    _gl.compileShader(shader.id);
    checkError('compileShader');
  }

  bool getShaderParameter(WebGLShader shader, int pname){
    startCheck('getShaderParameter');
    return _gl.getShaderParameter(shader.id, pname) == 0?false:true;
  }

  String? getShaderSource(WebGLShader shader) {
    startCheck('getShaderSource');
    return _gl.getShaderSource(shader.id);
  }

  void uniform1i(UniformLocation location, int x) {
    startCheck('uniform1i');
    _gl.uniform1i(location.id, x);
    checkError('uniform1i');
  }

  void uniform3f(UniformLocation location, double x, double y, double z) {
    startCheck('uniform3f');
    _gl.uniform3f(location.id, x, y, z);
    checkError('uniform3f');
  }

  void uniform4f(UniformLocation location, double x, double y, double z, double w){
    startCheck('uniform4f');
    _gl.uniform4f(location.id, x, y, z,w);
    checkError('uniform4f');
  }

  void uniform1fv(UniformLocation location, List<double> v){
    startCheck('uniform1fv');
    _gl.uniform1fv(location.id, v.jsify() as JSObject);
    checkError('uniform1fv');
  }

  void uniform2fv(UniformLocation location, List<double> v){
    startCheck('uniform2fv');
    _gl.uniform2fv(location.id, v.jsify() as JSObject);
    checkError('uniform2fv');
  }

  void uniform3fv(UniformLocation location, List<double> v){
    startCheck('uniform3fv');
    _gl.uniform3fv(location.id, v.jsify() as JSObject);
    checkError('uniform3fv');
  }

  void uniform1f(UniformLocation location, double x){
    _gl.uniform1f(location.id, x);
    checkError('uniform1f');
  }
  void uniformMatrix2fv(UniformLocation location, bool transpose, List<double> values) {
    startCheck('uniformMatrix2fv');
    _gl.uniformMatrix2fv(location.id, transpose, values.jsify() as JSObject);
    checkError('uniformMatrix2fv');
  }

  void uniformMatrix3fv(UniformLocation location, bool transpose, List<double> values) {
    startCheck('uniformMatrix3fv');
    _gl.uniformMatrix3fv(location.id, transpose, values.jsify() as JSObject);
    checkError('uniformMatrix3fv');
  }

  void uniformMatrix4fv(UniformLocation location, bool transpose, List<double> values) {
    startCheck('uniformMatrix4fv');
    _gl.uniformMatrix4fv(location.id, transpose, values.jsify() as JSObject);
    checkError('uniformMatrix4fv');
  }

  UniformLocation getAttribLocation(Program program, String name) {
    startCheck('getAttribLocation');
    return UniformLocation(_gl.getAttribLocation(program.id, name));
  }

  void uniform2f(UniformLocation location, double x, double y){
    startCheck('uniform2f');
    _gl.uniform2f(location.id, x, y);
    checkError('uniform2f');
  }

  void uniform1iv(UniformLocation location, List<int> v){
    startCheck('uniform1iv');
    _gl.uniform1iv(location.id, v.jsify() as JSObject);
    checkError('uniform1iv');
  }

  void uniform2iv(UniformLocation location, List<int> v){
    startCheck('uniform2iv');
    _gl.uniform2iv(location.id, v.jsify() as JSObject);
    checkError('uniform2iv');
  }

  void uniform3iv(UniformLocation location, List<int> v){
    startCheck('uniform3iv');
    _gl.uniform3iv(location.id, v.jsify() as JSObject);
    checkError('uniform3iv');
  }

  void uniform4iv(UniformLocation location, List<int> v){
    startCheck('uniform4iv');
    _gl.uniform4iv(location.id, v.jsify() as JSObject);
    checkError('uniform4iv');
  }

  void uniform1uiv(UniformLocation? location, List<int> v){
    startCheck('uniform1uiv');
    _gl.uniform1uiv(location?.id, v.jsify() as JSObject);
    checkError('uniform1uiv');
  }
  
  void uniform2uiv(UniformLocation? location, List<int> v){
    startCheck('uniform2uiv');
    _gl.uniform2uiv(location?.id, v.jsify() as JSObject);
    checkError('uniform2uiv');
  }

  void uniform3uiv(UniformLocation? location, List<int> v){
    startCheck('uniform3uiv');
    _gl.uniform3uiv(location?.id, v.jsify() as JSObject);
    checkError('uniform3uiv');
  }

  void uniform4uiv(UniformLocation? location, List<int> v){
    startCheck('uniform4uiv');
    _gl.uniform4uiv(location?.id, v.jsify() as JSObject);
    checkError('uniform4uiv');
  }

  void uniform1ui(UniformLocation? location, int v0){
    startCheck('uniform1ui');
    _gl.uniform1ui(location?.id, v0);
    checkError('uniform1ui');
  }

  void uniform2ui(UniformLocation? location, int v0, int v1){
    startCheck('uniform2ui');
    _gl.uniform2ui(location?.id, v0, v1);
    checkError('uniform2ui');
  }

  void uniform3ui(UniformLocation? location, int v0, int v1, int v2){
    startCheck('uniform3ui');
    _gl.uniform3ui(location?.id, v0, v1, v2);
    checkError('uniform2ui');
  }

  void uniform4ui(UniformLocation? location, int v0, int v1, int v2, int v3){
    startCheck('uniform4ui');
    _gl.uniform4ui(location?.id, v0, v1, v2, v3);
    checkError('uniform2ui');
  }

  void uniform4fv(UniformLocation location, List<double> vectors) {
    startCheck('uniform4fv');
    _gl.uniform4fv(location.id, vectors.jsify() as JSObject);
    checkError('uniform4fv');
  }

  void vertexAttribDivisor(int index, int divisor){
    startCheck('vertexAttribDivisor');
    _gl.vertexAttribDivisor(index, divisor);
    checkError('vertexAttribDivisor');
  }

  void flush() {
    _gl.flush();
  }

  void finish() {
    _gl.finish();
  }

  void texStorage2D(int target, int levels, int internalformat, int width, int height){
    startCheck('texStorage2D');
    _gl.texStorage2D(target, levels, internalformat, width, height);
    checkError('texStorage2D');
  }

  void texStorage3D(int target, int levels, int internalformat, int width, int height, int depth){
    startCheck('texStorage3D');
    _gl.texStorage3D(target, levels, internalformat, width, height, depth);
    checkError('texStorage3D');
  }

  TransformFeedback createTransformFeedback() {
    return TransformFeedback(_gl.createTransformFeedback());
  }
  
  void bindTransformFeedback(int target, TransformFeedback feedbeck){
    _gl.bindTransformFeedback(target, feedbeck.id);
    checkError('bindTransformFeedback');
  }

  void transformFeedbackVaryings(Program program, int count, List<String> varyings, int bufferMode) {
    startCheck('transformFeedbackVaryings');
    _gl.transformFeedbackVaryings(program.id, varyings.jsify() as JSArray<JSString>, bufferMode);
    checkError('transformFeedbackVaryings');
  }

  void deleteTransformFeedback(TransformFeedback transformFeedback) {
    startCheck('deleteTransformFeedback');
    _gl.deleteTransformFeedback(transformFeedback.id);
    checkError('deleteTransformFeedback');
  }

  bool isTransformFeedback(TransformFeedback transformFeedback) {
    startCheck('isTransformFeedback');
    return _gl.isTransformFeedback(transformFeedback.id);
  }

  void beginTransformFeedback(int primitiveMode) {
    startCheck('beginTransformFeedback');
    _gl.beginTransformFeedback(primitiveMode);
    checkError('beginTransformFeedback');
  }

  void endTransformFeedback() {
    startCheck('endTransformFeedback');
    _gl.endTransformFeedback();
    checkError('endTransformFeedback');
  }

  void pauseTransformFeedback() {
    startCheck('pauseTransformFeedback');
    _gl.pauseTransformFeedback();
    checkError('pauseTransformFeedback');
  }

  void resumeTransformFeedback() {
    startCheck('resumeTransformFeedback');
    _gl.resumeTransformFeedback();
    checkError('resumeTransformFeedback');
  }

  ActiveInfo getTransformFeedbackVarying(Program program, int index) {
    startCheck('getTransformFeedbackVarying');
    html.WebGLActiveInfo temp = _gl.getTransformFeedbackVarying(program.id, index)!;
    return ActiveInfo(temp.type, temp.name, temp.size);
  }

  void invalidateFramebuffer(int target, List<int> attachments){
    startCheck('invalidateFramebuffer');
    _gl.invalidateFramebuffer(target, attachments.jsify() as JSArray<JSNumber>);
    checkError('invalidateFramebuffer');
  }
}
