// Copyright (c) 2013, John Thomas McDole.
/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
part of 'learn_gl.dart';

/// Staticly draw a triangle and a square - With Color!
class Lesson2 extends Lesson {
  late GlProgram program;

  late Buffer triangleVertexPositionBuffer, squareVertexPositionBuffer;
  late Buffer triangleVertexColorBuffer, squareVertexColorBuffer;

  Float32Array? colors1;
  Float32Array? colors2; 
  Float32Array? indexes1;
  Float32Array? indexes2; 

  Lesson2(RenderingContext gl):super(gl) {
    program = GlProgram(
      gl,
      '''
          #version 300 es
          precision mediump float;
          out vec4 FragColor;

          in vec4 vColor;

          void main(void) {
            FragColor = vColor;
          }
        ''',
      '''
          #version 300 es
          in vec3 aVertexPosition;
          in vec4 aVertexColor;

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;

          out vec4 vColor;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vColor = aVertexColor;
          }
        ''',
      ['aVertexPosition', 'aVertexColor'],
      ['uMVMatrix', 'uPMatrix'],
    );
    gl.useProgram(program.program);

    // calloc and build the two buffers we need to draw a triangle and box.
    // createBuffer() asks the WebGL system to calloc some data for us
    triangleVertexPositionBuffer = gl.createBuffer();

    // bindBuffer() tells the WebGL system the target of future calls
    indexes1 ??= Float32Array.fromList([0.0, 1.0, 0.0, -1.0, -1.0, 0.0, 1.0, -1.0, 0.0]);
    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangleVertexPositionBuffer);
    gl.bufferData(WebGL.ARRAY_BUFFER, indexes1!, WebGL.STATIC_DRAW);

    triangleVertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangleVertexColorBuffer);
    colors1 ??= Float32Array.fromList([1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0]);
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      colors1!,
      WebGL.STATIC_DRAW,
    );

    squareVertexPositionBuffer = gl.createBuffer();
    indexes2 ??= Float32Array.fromList([1.0, 1.0, 0.0, -1.0, 1.0, 0.0, 1.0, -1.0, 0.0, -1.0, -1.0, 0.0]);
    gl.bindBuffer(WebGL.ARRAY_BUFFER, squareVertexPositionBuffer);
    gl.bufferData(WebGL.ARRAY_BUFFER,indexes2!, WebGL.STATIC_DRAW);

    squareVertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, squareVertexColorBuffer);
    colors2 ??= Float32Array.fromList([0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0]);
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      colors2!,
      WebGL.STATIC_DRAW,
    );

    // Specify the color to clear with (black with 100% alpha) and then enable
    // depth testing.
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
  }

  void dispose(){
    indexes1?.dispose();
    indexes2?.dispose();
    colors1?.dispose();
    colors2?.dispose();

    indexes1 = null;
    indexes2 = null;
    colors1 = null;
    colors2 = null;
  }

  void drawScene(int viewWidth, int viewHeight, double aspect) {
    // Basic viewport setup and clearing of the screen
    // gl.viewport(0, 0, viewWidth, viewHeight);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    gl.enable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.BLEND);

    // Setup the perspective - you might be wondering why we do this every
    // time, and that will become clear in much later lessons. Just know, you
    // are not crazy for thinking of caching this.
    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    // First stash the current model view matrix before we start moving around.
    mvPushMatrix();

    mvMatrix.translate([-1.5, 0.0, -7.0]);

    // Here's that bindBuffer() again, as seen in the constructor
    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangleVertexPositionBuffer);
    // Set the vertex attribute to the size of each individual element (x,y,z)
    gl.vertexAttribPointer(program.attributes['aVertexPosition']!, 3, WebGL.FLOAT, false, 0, 0);

    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangleVertexColorBuffer);
    gl.vertexAttribPointer(program.attributes['aVertexColor']!, 4, WebGL.FLOAT, false, 0, 0);

    setMatrixUniforms();
    // Now draw 3 vertices
    gl.drawArrays(WebGL.TRIANGLES, 0, 3);

    // Move 3 units to the right
    mvMatrix.translate([3.0, 0.0, 0.0]);

    // And get ready to draw the square just like we did the triangle...
    gl.bindBuffer(WebGL.ARRAY_BUFFER, squareVertexPositionBuffer);
    gl.vertexAttribPointer(program.attributes['aVertexPosition']!, 3, WebGL.FLOAT, false, 0, 0);

    gl.bindBuffer(WebGL.ARRAY_BUFFER, squareVertexColorBuffer);
    gl.vertexAttribPointer(program.attributes['aVertexColor']!, 4, WebGL.FLOAT, false, 0, 0);

    setMatrixUniforms();
    // Except now draw 2 triangles, re-using the vertices found in the buffer.
    gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, 4);

    // Finally, reset the matrix back to what it was before we moved around.
    mvPopMatrix();
  }

  /// Write the matrix uniforms (model view matrix and perspective matrix) so
  /// WebGL knows what to do with them.
  setMatrixUniforms() {
    gl.uniformMatrix4fv(program.uniforms['uPMatrix']!, false, pMatrix.buf);
    gl.uniformMatrix4fv(program.uniforms['uMVMatrix']!, false, mvMatrix.buf);
  }

  void animate(num now) {
    // We're not animating the scene, but if you want to experiment, here's
    // where you get to play around.
  }

  void handleKeys() {
    // We're not handling keys right now, but if you want to experiment, here's
    // where you'd get to play around.
  }
}
