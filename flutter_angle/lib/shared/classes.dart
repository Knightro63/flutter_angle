import 'package:flutter_angle/flutter_angle.dart';

List disposeWebGL = [];

class OpenGLException implements Exception {
  OpenGLException(this.message, this.error);

  final String message;
  final int error;

  @override
  String toString() => '$message GLES error $error ';
}

class ShaderPrecisionFormat{
  int rangeMin;
  int rangeMax;
  int precision;

  ShaderPrecisionFormat({
    this.rangeMin = 1, 
    this.rangeMax = 1, 
    this.precision = 1
  });
} 

class ActiveInfo{
  ActiveInfo(this.type,this.name,this.size);
  String name;
  int size;
  int type;
}

class WebGLTexture {
  final dynamic id;
  WebGLTexture(this.id){
    disposeWebGL.add(this);
  }

  void dispose(RenderingContext context){
    context.deleteTexture(this);
  }
}

class Program {
  final dynamic id;
  Program(this.id){
    disposeWebGL.add(this);
  }

  void dispose(RenderingContext context){
    context.deleteProgram(this);
  }
}

class Buffer {
  final dynamic id;
  Buffer(this.id){
    disposeWebGL.add(this);
  }

  void dispose(RenderingContext context){
    context.deleteBuffer(this);
  }
}

class Renderbuffer {
  final dynamic id;
  Renderbuffer(this.id){
    disposeWebGL.add(this);
  }

  void dispose(RenderingContext context){
    context.deleteRenderbuffer(this);
  }
}

class Framebuffer{
  final dynamic id;
  Framebuffer(this.id){
    disposeWebGL.add(this);
  }

  void dispose(RenderingContext context){
    context.deleteFramebuffer(this);
  }
}

class TransformFeedback{
  final dynamic id;
  TransformFeedback(this.id){
    disposeWebGL.add(this);
  }

  void dispose(RenderingContext context){
    context.deleteTransformFeedback(this);
  }
}

class VertexArrayObject{
  final dynamic id;
  VertexArrayObject(this.id){
    disposeWebGL.add(this);
  }

  void dispose(RenderingContext context){
    context.deleteVertexArray(this);
  }
}

class WebGLShader{
  final dynamic id;
  WebGLShader(this.id){
    disposeWebGL.add(this);
  }

  void dispose(RenderingContext context){
    context.deleteShader(this);
  }
}

class UniformLocation{
  final dynamic id;
  UniformLocation(this.id);
}

class WebGLParameter{
  final dynamic id;
  WebGLParameter(this.id);
}