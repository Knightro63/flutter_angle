import 'dart:io';

import 'bindings/gles_bindings.dart';
import 'dart:ffi';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'bindings/index.dart';
import '../shared/webgl.dart';
import '../shared/classes.dart';

// JS "WebGL2RenderingContext")
class RenderingContext {
  final LibOpenGLES gl;
  RenderingContext.create(this.gl);

  /// As allocating and freeing native memory is expensive and we need regularly
  /// buffers to receive values from FFI function we create a small set here that will
  /// be reused constantly
  /// 
  void checkError([String message = '']) {
    final glError = gl.glGetError();
    if (glError != WebGL.NO_ERROR) {
      final openGLException = OpenGLException('RenderingContext.$message', glError);
      // assert(() {
        print(openGLException.toString());
      //   return true;
      // }());
      // throw openGLException;
    }
  }

  void beginTransformFeedback(int primitiveMode){
    gl.glBeginTransformFeedback(primitiveMode);
    // checkError('beginTransformFeedback');
  }

  void bindTransformFeedback(int target, TransformFeedback feedback){
    gl.glBindTransformFeedback(target, feedback.id);
    // checkError('bindTransformFeedback');
  }

  void bindVertexArray(VertexArrayObject array){
    gl.glBindVertexArray(array.id);
    // checkError('bindVertexArray');
  }

  void blitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter){
    gl.glBlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
    // checkError('blitFramebuffer');
  }

  // //JS ('bufferSubData')
  void bufferSubData(int target, int dstByteOffset, TypedData srcData){
    Pointer<Float>? nativeBuffer;
    late int size;
    if (srcData is List<double> || srcData is Float32List) {
      nativeBuffer = floatListToArrayPointer(srcData as List<double>).cast();
      size = srcData.lengthInBytes * sizeOf<Float>();
    } 
    else if (srcData is Int32List) {
      nativeBuffer = int32ListToArrayPointer(srcData).cast();
      size = srcData.length * sizeOf<Int32>();
    } 
    else if (srcData is Uint16List) {
      nativeBuffer = uInt16ListToArrayPointer(srcData).cast();
      size = srcData.length * sizeOf<Uint16>();
    } 
    else if (srcData is Uint8List) {
      nativeBuffer = uInt8ListToArrayPointer(srcData).cast();
      size = srcData.length * sizeOf<Uint16>();
    } 

    gl.glBufferSubData(target, dstByteOffset, size, nativeBuffer != null ? nativeBuffer.cast() : nullptr);
    
    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texSubImage2D');
  }

  TransformFeedback createTransformFeedback() {
    final vPointer = calloc<Uint32>();
    gl.glGenTransformFeedbacks(1, vPointer);
    int _v = vPointer.value;
    calloc.free(vPointer);
    return TransformFeedback(_v);
  }
  VertexArrayObject createVertexArray(){
    final v = calloc<Uint32>();
    gl.glGenVertexArrays(1, v);
    int _v = v.value;
    calloc.free(v);
    return VertexArrayObject(_v);
  }

  void deleteTransformFeedback(TransformFeedback feedback){
    final List<int> _texturesList = [feedback.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteTransformFeedbacks(1, ptr);
    calloc.free(ptr);
    // checkError('deleteTransformFeedback');
  }

  void deleteVertexArray(VertexArrayObject array){
    final List<int> _texturesList = [array.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteVertexArrays(1, ptr);
    calloc.free(ptr);
    // checkError('deleteFramebuffer');
  }

  void drawArraysInstanced(int mode, int first, int count, int instanceCount){
    gl.glDrawArraysInstanced(mode, first, count, instanceCount);
    // checkError('drawArraysInstanced');
  }

  void drawBuffers(List<int> buffers){
    final ptr = calloc<Uint32>(buffers.length);
    ptr.asTypedList(buffers.length).setAll(0, List<int>.from(buffers));
    gl.glDrawBuffers(buffers.length, ptr);
    calloc.free(ptr);
  }

  void drawElementsInstanced(int mode, int count, int type, int offset, int instanceCount){
    var indices = Pointer<Void>.fromAddress(offset);
    gl.glDrawElementsInstanced(mode, count, type, indices, instanceCount);
    // checkError('drawElementsInstanced');
    calloc.free(indices);
  }

  void endTransformFeedback(){
    gl.glEndTransformFeedback();
    // checkError('endTransformFeedback');
  }

  ActiveInfo getTransformFeedbackVarying(int program, int index) {
    int maxLen = 100;
    var length = calloc<Int32>();
    var size = calloc<Int32>();
    var type = calloc<Uint32>();
    var name = calloc<Int8>(maxLen);

    gl.glGetTransformFeedbackVarying(program, index, maxLen - 1, length, size, type, name);

    int _type = type.value;
    String _name = name.cast<Utf8>().toDartString();
    int _size = size.value;

    calloc.free(type);
    calloc.free(name);
    calloc.free(size);
    calloc.free(length);

    return ActiveInfo(_type, _name, _size);
  }

  void invalidateFramebuffer(int target, List<int> attachments){
    int count = attachments.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, attachments);
    gl.glInvalidateFramebuffer(target, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('invalidateFramebuffer'); 
  }

  bool isTransformFeedback(TransformFeedback feedback){
    return gl.glIsTransformFeedback(feedback.id) == 0?false:true;
  }

  void pauseTransformFeedback(){
    gl.glPauseTransformFeedback();
    // checkError('pauseTransformFeedback'); 
  }

  void renderbufferStorageMultisample(int target, int samples, int internalformat, int width, int height){
    gl.glRenderbufferStorageMultisample(target, samples, internalformat, width, height);
    // checkError('renderbufferStorageMultisample');
  }

  void resumeTransformFeedback(){
    gl.glResumeTransformFeedback();
    // checkError('resumeTransformFeedback');
  }

  void texImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, TypedData? pixels) {
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glTexImage3D(target, level, internalformat, width, height, depth, border, format, type,
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texImage3D');
  }

  void texStorage2D(int target, int levels, int internalformat, int width, int height){
    gl.glTexStorage2D(target, levels, internalformat, width, height);
  }

  void texStorage3D(int target, int levels, int internalformat, int width, int height, int depth){
    gl.glTexStorage3D(target, levels, internalformat, width, height, depth);
  }

  // //JS ('texSubImage3D')
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
    TypedData? pixels
  ){
    /// TODO this can probably optimized depending on if the length can be devided by 4 or 2
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
      nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texSubImage2D');
  }

  void transformFeedbackVaryings(Program program, int count, List<String> varyings, int bufferMode) {
    final varyingsPtr = calloc<Pointer<Int8>>(varyings.length);
    int i = 0;
    for(final varying in varyings) {
      varyingsPtr[i] = varying.toNativeUtf8().cast<Int8>();
      i = i + 1;
    }
    gl.glTransformFeedbackVaryings(program.id, count, varyingsPtr, bufferMode);
    calloc.free(varyingsPtr);
  }

  void uniform1ui(UniformLocation? location, int v0){
    gl.glUniform1ui(location?.id  ?? nullptr.address, v0);
    // checkError('uniform1ui');
  }

  void uniform1uiv(UniformLocation? location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform1uiv(location?.id  ?? nullptr.address, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1uiv'); 
  }

  void uniform2ui(UniformLocation? location, int v0, int v1){
    gl.glUniform2ui(location?.id  ?? nullptr.address, v0, v1);
    // checkError('uniform2ui');
  }

  void uniform2uiv(UniformLocation? location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform2uiv(location?.id  ?? nullptr.address, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1uiv'); 
  }

  void uniform3ui(UniformLocation? location, int v0, int v1, int v2){
    gl.glUniform3ui(location?.id  ?? nullptr.address, v0, v1, v2);
    // checkError('uniform3ui');
  }

  void uniform3uiv(UniformLocation? location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform3uiv(location?.id  ?? nullptr.address, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1uiv'); 
  }

  void uniform4ui(UniformLocation? location, int v0, int v1, int v2, int v3){
    gl.glUniform4ui(location?.id  ?? nullptr.address, v0, v1, v2, v3);
    // checkError('uniform4ui');
  }

  void uniform4uiv(UniformLocation? location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform4uiv(location?.id  ?? nullptr.address, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1uiv'); 
  }

  void vertexAttribDivisor(int index, int divisor){
    gl.glVertexAttribDivisor(index, divisor);
  }

  void vertexAttribIPointer(int index, int size, int type, int stride, int pointer){
    var _pointer = calloc<Int32>();
    _pointer.value = pointer;
    gl.glVertexAttribIPointer(index, size, type, stride, _pointer.cast<Void>());
    calloc.free(_pointer);
    // checkError('vertexAttribIPointer');
  }

  void activeTexture(int texture) {
    gl.glActiveTexture(texture);
    // checkError('activeTexture');
  }

  void attachShader(Program program, WebGLShader shader) {
    gl.glAttachShader(program.id, shader.id);
    // checkError('attachShader');
  }

  void bindAttribLocation(Program program, int index, String name){
    final locationName = name.toNativeUtf8();
    gl.glBindAttribLocation(program.id, index,locationName.cast());
    // checkError('bindAttribLocation');
    calloc.free(locationName);
  }

  void bindBuffer(int target, Buffer buffer) {
    gl.glBindBuffer(target, buffer.id);
    // checkError('bindBuffer');
  }

  void bindFramebuffer(int target, Framebuffer? framebuffer){
    if(framebuffer != null){
      gl.glBindFramebuffer(target, framebuffer.id);
    }
    // checkError('bindFramebuffer');
  }

  void bindRenderbuffer(int target, Renderbuffer? renderbuffer){
    gl.glBindRenderbuffer(target, renderbuffer?.id ?? nullptr.address);
    // checkError('bindRenderbuffer');
  }

  void bindTexture(int target, WebGLTexture? texture) {
    if(texture != null){
      gl.glBindTexture(target, texture.id);
    }
    // checkError('bindTexture');
  }

  // void blendColor(num red, num green, num blue, num alpha);

  void blendEquation(int mode){
    gl.glBlendEquation(mode);
    // checkError('blendEquation');
  }

  void blendEquationSeparate(int modeRGB, int modeAlpha){
    gl.glBlendEquationSeparate(modeRGB, modeAlpha);
  }

  void blendFunc(int sfactor, int dfactor){
    gl.glBlendFunc(sfactor, dfactor);
  }

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha){
    gl.glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
    // checkError('blendFuncSeparate');
  }

  /// Be careful which type of integer you really pass here. Unfortunately an UInt16List
  /// is viewed by the Dart type system just as List<int>, so we jave to specify the native type
  /// here in [nativeType]
  void bufferData(int target, TypedData data, int usage) {
    late Pointer<Void> nativeData;

    late int size;
    if (data is List<double> || data is Float32List) {
      nativeData = floatListToArrayPointer(data as List<double>).cast();
      size = data.lengthInBytes * sizeOf<Float>();
    } 
    else if (data is Int32List) {
      nativeData = int32ListToArrayPointer(data).cast();
      size = data.length * sizeOf<Int32>();
    } 
    else if (data is Uint32List) {
      nativeData = uInt32ListToArrayPointer(data).cast();
      size = data.length * sizeOf<Uint32>();
    } 
    else if (data is Uint16List) {
      nativeData = uInt16ListToArrayPointer(data).cast();
      size = data.length * sizeOf<Uint16>();
    } 
    else if (data is Uint8List) {
      nativeData = uInt8ListToArrayPointer(data).cast();
      size = data.length * sizeOf<Uint8>();
    } 
    else if (data is Int8List) {
      nativeData = int8ListToArrayPointer(data).cast();
      size = data.length * sizeOf<Int8>();
    } 
    else {
      throw (OpenGLException('bufferData: unsupported native type ${data.runtimeType}', -1));
    }
    gl.glBufferData(target, size, nativeData, usage);
    calloc.free(nativeData);
    // checkError('bufferData');
  }

  Pointer<Float> floatListToArrayPointer(List<double> list) {
    final ptr = calloc<Float>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }

  Pointer<Int32> int32ListToArrayPointer(List<int> list) {
    final ptr = calloc<Int32>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }

  Pointer<Uint32> uInt32ListToArrayPointer(List<int> list) {
    final ptr = calloc<Uint32>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }

  Pointer<Uint16> uInt16ListToArrayPointer(List<int> list) {
    final ptr = calloc<Uint16>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }

  Pointer<Uint8> uInt8ListToArrayPointer(List<int> list) {
    final ptr = calloc<Uint8>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }

  Pointer<Int8> int8ListToArrayPointer(List<int> list) {
    final ptr = calloc<Int8>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }
  // void bufferSubData(int target, int offset, data);

  int checkFramebufferStatus(int target){
    return gl.glCheckFramebufferStatus(target);
  }

  void clear(int mask) => gl.glClear(mask);

  void clearColor(double red, double green, double blue, double alpha) {
    gl.glClearColor(red, green, blue, alpha);
    // checkError('clearColor');
  }

  void clearDepth(double depth){
    gl.glClearDepthf(depth);
    // checkError('clearDepth');
  }

  void clearStencil(int s){
    gl.glClearStencil(s);
    // checkError('clearStencil');
  }

  void colorMask(bool red, bool green, bool blue, bool alpha){
    gl.glColorMask(red?1:0, green?1:0, blue?1:0, alpha?1:0);
    // checkError('colorMask');
  }


  void compileShader(WebGLShader shader, [bool checkForErrors = true]) {
    gl.glCompileShader(shader.id);

    if (checkForErrors) {
      final compiled = calloc<Int32>();
      gl.glGetShaderiv(shader.id, GL_COMPILE_STATUS, compiled);
      if (compiled.value == 0) {
        final infoLen = calloc<Int32>();

        gl.glGetShaderiv(shader.id, GL_INFO_LOG_LENGTH, infoLen);

        String message = '';
        if (infoLen.value > 1) {
          final infoLog = calloc<Int8>(infoLen.value);

          gl.glGetShaderInfoLog(shader.id, infoLen.value, nullptr, infoLog);
          message = "\nError compiling shader:\n${infoLog.cast<Utf8>().toDartString()}";

          calloc.free(infoLog);
        }
        calloc.free(infoLen);
        throw OpenGLException(message, 0);
      }
      calloc.free(compiled);
    }
  }

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, TypedData? pixels){
    Pointer<Void>? nativeBuffer; 
    late int size;

    if (pixels is List<double> || pixels is Float32List) {
      nativeBuffer = floatListToArrayPointer(pixels as List<double>).cast();
      size = pixels!.lengthInBytes * sizeOf<Float>();
    } else if (pixels is Int32List) {
      nativeBuffer = int32ListToArrayPointer(pixels).cast();
      size = pixels.length * sizeOf<Int32>();
    } else if (pixels is Uint16List) {
      nativeBuffer = uInt16ListToArrayPointer(pixels).cast();
      size = pixels.length * sizeOf<Uint16>();
    }

    gl.glCompressedTexImage2D(target, level, internalformat, width, height, border, size, nativeBuffer != null ? nativeBuffer.cast() : nullptr);
    
    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    
    // checkError('compressedTexImage2D');
  }

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format ,TypedData? pixels){
    Pointer<Void>? nativeBuffer;
    late int size;

    if (pixels is List<double> || pixels is Float32List) {
      nativeBuffer = floatListToArrayPointer(pixels as List<double>).cast();
      size = pixels!.lengthInBytes * sizeOf<Float>();
    } else if (pixels is Int32List) {
      nativeBuffer = int32ListToArrayPointer(pixels).cast();
      size = pixels.length * sizeOf<Int32>();
    } else if (pixels is Uint16List) {
      nativeBuffer = uInt16ListToArrayPointer(pixels).cast();
      size = pixels.length * sizeOf<Uint16>();
    } 

    gl.glCompressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, size,
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('compressedTexSubImage2D');
  }

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border){
    gl.glCopyTexImage2D(target, level, internalformat, x, y, width, height, border);
    // checkError('copyTexImage2D');
  }

  // void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height);
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height){
    gl.glCopyTexSubImage2D(target, level, xoffset, yoffset, x,y,width, height);
    // checkError('copyTexSubImage2D');
  }

  Buffer createBuffer() {
    Pointer<Uint32> id = calloc<Uint32>();
    gl.glGenBuffers(1, id);
    // checkError('createBuffer');
    int _v = id.value;
    calloc.free(id);
    return Buffer(_v);
  }

  Framebuffer createFramebuffer(){
    Pointer<Uint32> id = calloc<Uint32>();
    gl.glGenFramebuffers(1, id);
    checkError('createFramebuffer');
    int _v = id.value;
    calloc.free(id);
    return Framebuffer(_v);
  }

  Program createProgram() {
    final program = gl.glCreateProgram();
    // checkError('createProgram');
    return Program(program);
  }

  Renderbuffer createRenderbuffer(){
    final v = calloc<Uint32>();
    gl.glGenRenderbuffers(1, v);
    int _v = v.value;
    calloc.free(v);
    return Renderbuffer(_v);
  }

  WebGLShader createShader(int type) {
    final shader = gl.glCreateShader(type);
    // checkError('createShader');
    return WebGLShader(shader);
  }

  WebGLTexture createTexture() {
    Pointer<Uint32> vPointer = calloc<Uint32>();
    gl.glGenTextures(1, vPointer);
    // checkError('createBuffer');
    int _v = vPointer.value;
    calloc.free(vPointer);
    return WebGLTexture(_v);
  }

  int getParameter(int key) {
    // print("OpenGL getParameter key: ${key} ");

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
      WebGL.VIEWPORT,
      WebGL.MAX_TEXTURE_MAX_ANISOTROPY_EXT
    ];

    if (_intValues.indexOf(key) >= 0) {
      final v = calloc<Int32>(4);
      gl.glGetIntegerv(key, v);
      return v.value;
    } else {
      throw (" OpenGL getParameter key: ${key} is not support ");
    }
  }

  void cullFace(int mode){
    gl.glCullFace(mode);
    // checkError('cullFace');
  }

  void deleteBuffer(Buffer buffer){
    final List<int> _texturesList = [buffer.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteBuffers(1, ptr);
    calloc.free(ptr);
    // checkError('deleteBuffer');
  }

  void deleteFramebuffer(Framebuffer framebuffer){
    final List<int> _texturesList = [framebuffer.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteFramebuffers(1, ptr);
    calloc.free(ptr);
    // checkError('deleteFramebuffer');
  }

  void deleteProgram(Program program){
    gl.glDeleteProgram(program.id);
  }

  void deleteRenderbuffer(Renderbuffer renderbuffer){
    final List<int> _texturesList = [renderbuffer.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteRenderbuffers(1, ptr);
    calloc.free(ptr);
    // checkError('deleteFramebuffer');
  }

  void deleteShader(WebGLShader shader){
    gl.glDeleteShader(shader.id);
  }

  void deleteTexture(WebGLTexture texture){
    final List<int> _texturesList = [texture.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteTextures(1, ptr);
    calloc.free(ptr);
    // checkError('deleteTexture');
  }

  void depthFunc(int func){
    gl.glDepthFunc(func);
    // checkError('depthFunc');
  }

  void depthMask(bool flag){
    gl.glDepthMask(flag?1:0);
    // checkError('depthMask');
  }

  void disable(int cap) {
    gl.glDisable(cap);
    // checkError('disable');
  }

  void disableVertexAttribArray(int index){
    gl.glDisableVertexAttribArray(index);
  }

  void drawArrays(int mode, int first, int count) {
    gl.glDrawArrays(mode, first, count);
    // checkError('drawArrays');
  }

  void drawElements(int mode, int count, int type, int offset) {
    var offSetPointer = Pointer<Void>.fromAddress(offset);
    gl.glDrawElements(mode, count, type, offSetPointer.cast());
    // checkError('drawElements');
    calloc.free(offSetPointer);
  }

  void enable(int cap) {
    gl.glEnable(cap);
    // checkError('enable');
  }

  void enableVertexAttribArray(int index) {
    gl.glEnableVertexAttribArray(index);
    // checkError('enableVertexAttribArray');
  }

  void finish(){
    gl.glFinish();
  }

  void flush(){
    gl.glFlush();
  }

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer? renderbuffer){
    gl.glFramebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer?.id  ?? nullptr.address);
    // checkError('framebufferRenderbuffer');
  }

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level){
    gl.glFramebufferTexture2D(target, attachment, textarget, texture.id, level);
  }

  void frontFace(int mode){
    gl.glFrontFace(mode);
    // checkError('frontFace');
  }

  void generateMipmap(int target) {
    gl.glGenerateMipmap(target);
    // checkError('generateMipmap');
  }

  ActiveInfo getActiveAttrib(Program v0, int v1) {
    var length = calloc<Int32>();
    var size = calloc<Int32>();
    var type = calloc<Uint32>();
    var name = calloc<Int8>(100);

    gl.glGetActiveAttrib(v0.id, v1, 99, length, size, type, name);

    int _type = type.value;
    String _name = name.cast<Utf8>().toDartString();
    int _size = size.value;

    calloc.free(type);
    calloc.free(name);
    calloc.free(size);
    calloc.free(length);

    return ActiveInfo(_type, _name, _size);
  }

  ActiveInfo getActiveUniform(Program v0, int v1) {
    var length = calloc<Int32>();
    var size = calloc<Int32>();
    var type = calloc<Uint32>();
    var name = calloc<Int8>(100);

    gl.glGetActiveUniform(v0.id, v1, 99, length, size, type, name);

    int _type = type.value;
    String _name = name.cast<Utf8>().toDartString();
    int _size = size.value;

    calloc.free(type);
    calloc.free(name);
    calloc.free(size);
    calloc.free(length);

    return ActiveInfo(_type, _name, _size);
  }

  UniformLocation getAttribLocation(Program program, String name) {
    final locationName = name.toNativeUtf8();
    final location = gl.glGetAttribLocation(program.id, locationName.cast());
    // checkError('getAttribLocation');
    calloc.free(locationName);
    return UniformLocation(location);
  }

  dynamic getContextAttributes() {
    return null;
  }

  int getError(){
    return gl.glGetError();
  }

  Object? getExtension(String key) {
    if (Platform.isMacOS) {
      return getExtensionMacos(key);
    }
    Pointer _v = gl.glGetString(WebGL.EXTENSIONS);

    String _vstr = _v.cast<Utf8>().toDartString();
    List<String> _extensions = _vstr.split(" ");

    return _extensions;
  }

  List<String> getExtensionMacos(String key) {
    List<String> _extensions = [];
    var nExtension = getIntegerv(33309);
    for (int i = 0; i < nExtension; i++) {
      _extensions.add(getStringi(GL_EXTENSIONS, i));
    }

    return _extensions;
  }

  String getStringi(int key, int index) {
    Pointer _v = gl.glGetStringi(key, index);
    return _v.cast<Utf8>().toDartString();
  }

  int getIntegerv(int v0) {
    Pointer<Int32> ptr = calloc<Int32>();
    gl.glGetIntegerv(v0, ptr);

    int _v = ptr.value;
    calloc.free(ptr);

    return _v;
  }

  String? getProgramInfoLog(Program program){
    var infoLen = calloc<Int32>();

    gl.glGetProgramiv(program.id, 35716, infoLen);

    int _len = infoLen.value;
    calloc.free(infoLen);

    String message = '';

    if (_len > 0) {
      final infoLog = calloc<Int8>(_len);
      gl.glGetProgramInfoLog(program.id, _len, nullptr, infoLog);

      message = "\nError compiling shader:\n${infoLog.cast<Utf8>().toDartString()}";
      calloc.free(infoLog);
      return message;
    } 

    return null;
  }

  WebGLParameter getProgramParameter(Program program, int pname) {
    final status = calloc<Int32>();
    gl.glGetProgramiv(program.id, pname, status);
    final _v = status.value;
    calloc.free(status);
    // checkError('getProgramParameter');
    return WebGLParameter(_v);
  }


  String? getShaderInfoLog(WebGLShader shader){
    final infoLen = calloc<Int32>();
    gl.glGetShaderiv(shader.id, 35716, infoLen);

    int _len = infoLen.value;
    calloc.free(infoLen);

    String message = '';
    if (_len > 1) {
      final infoLog = calloc<Int8>(_len);

      gl.glGetShaderInfoLog(shader.id, _len, nullptr, infoLog);
      message = "\nError compiling shader:\n${infoLog.cast<Utf8>().toDartString()}";
      calloc.free(infoLog);
      return message;
    }
    return null;
  }

  bool getShaderParameter(WebGLShader shader, int pname){
    var _pointer = calloc<Int32>();
    gl.glGetShaderiv(shader.id, pname, _pointer);
    final _v = _pointer.value;
    calloc.free(_pointer);
    return _v == 0?false:true;
  }

  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype){
    return ShaderPrecisionFormat();
  }

  String? getShaderSource(int shader){
    // var sourceString = shaderSource.toNativeUtf8();
    // var arrayPointer = calloc<Int32>();
    // arrayPointer.value = Pointer.fromAddress(sourceString.address);
    // String temp = gl.glGetShaderSource(shader, 1, arrayPointer, nullptr);
    // calloc.free(arrayPointer);
    // calloc.free(sourceString);
    return null;
  }

  UniformLocation getUniformLocation(Program program, String name) {
    final locationName = name.toNativeUtf8();
    final location = gl.glGetUniformLocation(program.id, locationName.cast());
    // checkError('getProgramParameter');
    calloc.free(locationName);
    return UniformLocation(location);
  }

  bool isProgram(Program program){
    return gl.glIsProgram(program.id) != 0;
  }

  void lineWidth(double width){
    gl.glLineWidth(width);
    // checkError('lineWidth');
  }

  void linkProgram(Program program, [bool checkForErrors = true]) {
    gl.glLinkProgram(program.id);
    if (checkForErrors) {
      final linked = calloc<Int32>();
      gl.glGetProgramiv(program.id, GL_LINK_STATUS, linked);
      if (linked.value == 0) {
        final infoLen = calloc<Int32>();

        gl.glGetProgramiv(program.id, GL_INFO_LOG_LENGTH, infoLen);

        String message = '';
        if (infoLen.value > 1) {
          final infoLog = calloc<Int8>(infoLen.value);

          gl.glGetProgramInfoLog(program.id, infoLen.value, nullptr, infoLog);
          message = "\nError linking program:\n${infoLog.cast<Utf8>().toDartString()}";

          calloc.free(infoLog);
        }
        calloc.free(infoLen);
        throw OpenGLException(message, 0);
      }
      calloc.free(linked);
    }
  }

  void pixelStorei(int pname, int param) {
    gl.glPixelStorei(pname, param);
    // checkError('pixelStorei');
  }

  void polygonOffset(double factor, double units){
    gl.glPolygonOffset(factor, units);
  }

  void renderbufferStorage(int target, int internalformat, int width, int height){
    gl.glRenderbufferStorage(target, internalformat, width, height);
  }

  void scissor(int x, int y, int width, int height){
    gl.glScissor(x, y, width, height);
    // checkError('scissor');
  }

  void shaderSource(WebGLShader shader, String shaderSource) {
    var sourceString = shaderSource.toNativeUtf8();
    var arrayPointer = calloc<Pointer<Int8>>();
    arrayPointer.value = Pointer.fromAddress(sourceString.address);
    gl.glShaderSource(shader.id, 1, arrayPointer, nullptr);
    calloc.free(arrayPointer);
    calloc.free(sourceString);
    // checkError('shaderSource');
  }

  void stencilFunc(int func, int ref, int mask){
    gl.glStencilFunc(func, ref, mask);
  }

  void stencilMask(int mask){
    gl.glStencilMask(mask);
    // checkError('stencilMask');
  }

  void stencilOp(int fail, int zfail, int zpass){
    gl.glStencilOp(fail, zfail, zpass);
    // checkError('stencilOp');
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
    TypedData? pixels
  ) {
    /// TODO this can probably optimized depending on if the length can be devided by 4 or 2
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glTexImage2D(target, level, internalformat, width, height, border, format, type,
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texImage2D');
  }

  void texImage2D_NOSIZE(
    int target, 
    int level, 
    int internalformat, 
    int format, 
    int type, 
    TypedData? pixels
  ) {  
    texImage2D(target, level, internalformat, 0, 0, 0, format, type, pixels);
  }

  Future<void> texImage2DfromImage(
    int target,
    Image image, {
    int level = 0,
    int internalformat = WebGL.RGBA,
    int format = WebGL.RGBA,
    int type = WebGL.UNSIGNED_BYTE,
  }) async {
    texImage2D(target, level, internalformat, image.width, image.height, 0, format, type, (await image.toByteData())!);
  }

  Future<void> texImage2DfromAsset(
    int target,
    String assetPath, {
    int level = 0,
    int internalformat = WebGL.RGBA32UI,
    int format = WebGL.RGBA,
    int type = WebGL.UNSIGNED_INT,
  }) async {
    final image = await loadImageFromAsset(assetPath);
    texImage2D(target, level, internalformat, image.width, image.height, 0, format, type, (await image.toByteData())!);
  }

  Future<Image> loadImageFromAsset(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final loadingCompleter = Completer<Image>();
    decodeImageFromList(bytes.buffer.asUint8List(), (image) {
      loadingCompleter.complete(image);
    });
    return loadingCompleter.future;
  }

  void texParameterf(int target, int pname, double param) {
    gl.glTexParameterf(target, pname, param);
    // checkError('texParameterf');
  }

  void texParameteri(int target, int pname, int param) {
    gl.glTexParameteri(target, pname, param);
    // checkError('texParameteri');
  }

  // //JS ('texSubImage2D')
  void texSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, TypedData? pixels){
    /// TODO this can probably optimized depending on if the length can be devided by 4 or 2
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type,
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texImage2D');
  }

  void texSubImage2D_NOSIZE(int target, int level, int xoffset, int yoffset, int format, int type, TypedData? pixels){
    texSubImage2D(target, level, xoffset, yoffset, 0, 0, format, type, pixels);
  }

  void uniform1f(UniformLocation location, double x){
    gl.glUniform1f(location.id, x);
    // checkError('uniform1f');
  }

  void uniform1fv(UniformLocation location, List<double> v){
    var arrayPointer = floatListToArrayPointer(v);
    gl.glUniform1fv(location.id, v.length ~/ 1, arrayPointer);
    calloc.free(arrayPointer);
    // checkError('uniform1fv');  
  }

  void uniform1i(UniformLocation location, int x) {
    gl.glUniform1i(location.id, x);
    // checkError('uniform1i');
  }

  void uniform1iv(UniformLocation location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Int32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform1iv(location.id, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1iv'); 
  }

  void uniform2f(UniformLocation location, double x, double y){
    gl.glUniform2f(location.id, x, y);
    // checkError('uniform2f'); 
  }

  void uniform2fv(UniformLocation location, List<double> v){
    var arrayPointer = floatListToArrayPointer(v);
    gl.glUniform2fv(location.id, v.length ~/ 1, arrayPointer);
    calloc.free(arrayPointer);
    // checkError('uniform2fv'); 
  }

  // void uniform2i(UniformLocation? location, int x, int y);

  void uniform2iv(UniformLocation location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Int32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform2iv(location.id, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform2iv'); 
  }

  void uniform3f(UniformLocation location, double x, double y, double z) {
    gl.glUniform3f(location.id, x, y, z);
    // checkError('uniform3f');
  }

  void uniform3fv(UniformLocation location, List<double> vectors) {
    var arrayPointer = floatListToArrayPointer(vectors);
    gl.glUniform3fv(location.id, vectors.length ~/ 3, arrayPointer);
    // checkError('uniform3fv');
    calloc.free(arrayPointer);
  }

  void uniform3iv(UniformLocation location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Int32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform3iv(location.id, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform2iv'); 
  }

  void uniform4f(UniformLocation location, double x, double y, double z, double w){
    gl.glUniform4f(location.id, x, y, z,w);
    // checkError('uniform4f');
  }

  void uniform4fv(UniformLocation location, List<double> vectors) {
    var arrayPointer = floatListToArrayPointer(vectors);
    gl.glUniform4fv(location.id, vectors.length ~/ 3, arrayPointer);
    // checkError('uniform4fv');
    calloc.free(arrayPointer);
  }

  void uniform4iv(UniformLocation location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Int32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform4iv(location.id, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform2iv'); 
  }

  // void uniformMatrix2fv(UniformLocation? location, bool transpose, array);
  void uniformMatrix2fv(UniformLocation location, bool transpose, List<double> values) {
    var arrayPointer = floatListToArrayPointer(values);
    gl.glUniformMatrix2fv(location.id, values.length ~/ 9, transpose ? 1 : 0, arrayPointer);
    // checkError('uniformMatrix2fv');
    calloc.free(arrayPointer);
    
  }

  void uniformMatrix3fv(UniformLocation location, bool transpose, List<double> values) {
    var arrayPointer = floatListToArrayPointer(values);
    gl.glUniformMatrix3fv(location.id, values.length ~/ 9, transpose ? 1 : 0, arrayPointer);
    // checkError('uniformMatrix3fv');
    calloc.free(arrayPointer);
  }

  /// be careful, data always has a length that is a multiple of 16
  void uniformMatrix4fv(UniformLocation location, bool transpose, List<double> values) {
    var arrayPointer = floatListToArrayPointer(values);
    gl.glUniformMatrix4fv(location.id, values.length ~/ 16, transpose ? 1 : 0, arrayPointer);
    // checkError('uniformMatrix4fv');
    calloc.free(arrayPointer);
  }

  void useProgram(Program? program) {
    gl.glUseProgram(program?.id  ?? nullptr.address);
    // checkError('useProgram');
  }

  void vertexAttrib1fv(int index, List<double> values){
    var arrayPointer = floatListToArrayPointer(values);
    gl.glVertexAttrib1fv(index, arrayPointer);
    // checkError('vertexAttrib2fv');
    calloc.free(arrayPointer);
  }

  void vertexAttrib2fv(int index, List<double> values){
    var arrayPointer = floatListToArrayPointer(values);
    gl.glVertexAttrib2fv(index, arrayPointer);
    // checkError('vertexAttrib2fv');
    calloc.free(arrayPointer);
  }

  void vertexAttrib3fv(int index, List<double> values){
    var arrayPointer = floatListToArrayPointer(values);
    gl.glVertexAttrib3fv(index, arrayPointer);
    // checkError('vertexAttrib3fv');
    calloc.free(arrayPointer);
  }

  // void vertexAttrib4f(int indx, num x, num y, num z, num w);

  void vertexAttrib4fv(int index, List<double> values){
    var arrayPointer = floatListToArrayPointer(values);
    gl.glVertexAttrib4fv(index, arrayPointer);
    // checkError('vertexAttrib4fv');
    calloc.free(arrayPointer);
  }

  void vertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset) {
    var offsetPointer = Pointer<Void>.fromAddress(offset);
    gl.glVertexAttribPointer(index, size, type, normalized ? 1 : 0, stride, offsetPointer.cast<Void>());
    // checkError('vertexAttribPointer');
    //calloc.free(offsetPointer);
  }

  void viewport(int x, int y, int width, int height) {
    gl.glViewport(x, y, width, height);
    // checkError('viewPort');
  }

  void readPixels(int x, int y, int width, int height, int format, int type, TypedData? pixels) {
    /// TODO this can probably optimized depending on if the length can be devided by 4 or 2
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glReadPixels(x, y, width, height, format, type, 
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texImage2D');
  }
}