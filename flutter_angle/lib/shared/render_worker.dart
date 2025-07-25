import 'dart:typed_data';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:flutter_angle/shared/gl_program.dart';
import './shaders.dart';

class RenderWorker{
  late final Buffer vertexBuffer;
  late final Buffer vertexBuffer4FBO;
  late final RenderingContext _gl;
  
  RenderWorker(FlutterAngleTexture texture){
    _gl = texture.getContext();
    setupVBO();
    setupVBO4FBO();
  }

  void renderTexture(WebGLTexture? texture, {Float32List? matrix, bool isFBO = false}){
    late final Buffer _vertexBuffer;
    
    if(isFBO) {
      _vertexBuffer = vertexBuffer4FBO;
    } else {
      _vertexBuffer = vertexBuffer;
    }
    
    drawTexture(texture: texture, vertexBuffer: _vertexBuffer, matrix: matrix);
  }

  void setupVBO() {
    double w = 1.0;
    double h = 1.0;

    Float32Array vertices = Float32Array.fromList([
      -w,-h,0,0,1,
      w,-h,0,1,1,
      -w,h,0,0,0,
      w,h,0,1,0
    ]);
    
    vertexBuffer = _gl.createBuffer();
    _gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexBuffer);
    _gl.bufferData(WebGL.ARRAY_BUFFER, vertices, WebGL.STATIC_DRAW);
    vertices.dispose();
  }
  
  void setupVBO4FBO() {
    double w = 1.0;
    double h = 1.0;

    Float32Array vertices = Float32Array.fromList([
      -w,-h,0,0,0,
      w,-h,0,1,0,
      -w,h,0,0,1,
      w,h,0,1,1,
    ]);
    
    vertexBuffer4FBO = _gl.createBuffer();
    _gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexBuffer4FBO);
    _gl.bufferData(WebGL.ARRAY_BUFFER, vertices, WebGL.STATIC_DRAW);
    vertices.dispose();
  }

  void drawTexture({required WebGLTexture? texture, required Buffer vertexBuffer, Float32List? matrix}) {
    _gl.checkError("drawTexture 01");
    
    final program = GlProgram(
      _gl,
      fragment_shader, 
      vertex_shader
    ).program;

    _gl.useProgram(program);
    _gl.checkError("drawTexture 02");
    
    final _positionSlot = _gl.getAttribLocation(program, "Position");
    final _textureSlot = _gl.getAttribLocation(program, "TextureCoords");
    final _texture0Uniform = _gl.getUniformLocation(program, "Texture0");
    
    _gl.activeTexture(WebGL.TEXTURE10);
    _gl.bindTexture(WebGL.TEXTURE_2D, texture!);
    _gl.uniform1i(_texture0Uniform, 10);
    _gl.checkError("drawTexture 03");
    
    Float32List _matrix = Float32List.fromList([
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]);
    
    if(matrix != null) {
      _matrix = matrix;
    }

    final _matrixUniform = _gl.getUniformLocation(program, "matrix");
    _gl.uniformMatrix4fv(_matrixUniform, false, _matrix);
    
    _gl.checkError("drawTexture 04");
    _gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexBuffer);
    
    _gl.checkError("drawTexture 05");

    final vao = _gl.createVertexArray();
    _gl.bindVertexArray(vao);
    
    _gl.vertexAttribPointer(_positionSlot.id, 3, WebGL.FLOAT, false, Float32List.bytesPerElement * 5, 0);
    _gl.checkError("drawTexture 06");

    _gl.enableVertexAttribArray(_positionSlot.id);
    _gl.checkError("drawTexture 07");
    
    _gl.vertexAttribPointer(_textureSlot.id, 2, WebGL.FLOAT, false, Float32List.bytesPerElement * 5, Float32List.bytesPerElement * 3);
    _gl.enableVertexAttribArray(_textureSlot.id);
    
    _gl.checkError("drawTexture 08");
    _gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, 4);
    _gl.deleteVertexArray(vao);
    _gl.checkError("drawTexture 09");
    _gl.deleteProgram(program);
  }

  void dispose(){
    _gl.deleteBuffer(vertexBuffer);
    _gl.deleteBuffer(vertexBuffer4FBO);
  }
}