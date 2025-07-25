import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';

void main() {
  runApp(ExampleTriangle01());
}


class ExampleTriangle01 extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<ExampleTriangle01> {
  int? fboId;
  double dpr = 1.0;
  bool ready = false;
  late double width;
  late double height;

  late final glProgram;

  Size? screenSize;
  late final RenderingContext _gl;

  late FlutterAngleTexture sourceTexture;
  FlutterAngle angle = FlutterAngle();
  Framebuffer? defaultFramebuffer;
  WebGLTexture? defaultFramebufferTexture;

  int n = 0;

  int t = DateTime.now().millisecondsSinceEpoch;
  Float32Array? vertices; 
  @override
  void initState() {
    super.initState();
    print(" init state..... ");
  }

  @override
  void dispose(){
    vertices?.dispose();
    vertices = null;
    angle.dispose([sourceTexture]);
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = width;

    await angle.init(true);
    setState(() {});

    // web need wait dom ok!!!
    Future.delayed(Duration(milliseconds: 100), () {
      setup();
    });
  }

  void setup() async {
    sourceTexture = await angle.createTexture(      
      AngleOptions(
        width: width.toInt(), 
        height: height.toInt(), 
        dpr: dpr,
      )
    );
    _gl = sourceTexture.getContext();
    ready = true;

    setState(() {});
    // if(!kIsWeb && Platform.isLinux){
    //   setupDefaultFBO();
    // }

    prepare();
    animate();
  }

  void initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mq = MediaQuery.of(context);

    screenSize = mq.size;
    dpr = mq.devicePixelRatio;

    print(" screenSize: ${screenSize} dpr: ${dpr} ");
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            initSize(context);
            return SingleChildScrollView(child: _build(context));
          },
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Container(
            width: width,
            height: width,
            color: Colors.black,
            child: Builder(builder: (BuildContext context) {
              if (kIsWeb) {
                return ready
                    ? HtmlElementView(
                        viewType: sourceTexture.textureId.toString())
                    : Container();
              } else {
                return ready
                    ? Texture(textureId: sourceTexture.textureId)
                    : Container();
              }
            })),
      ],
    );
  }

  void animate() {
    render();

    Future.delayed(Duration(milliseconds: 40), () {
      animate();
    });
  }

  void setupDefaultFBO() {
    int glWidth = (width * dpr).toInt();
    int glHeight =  (height * dpr).toInt();

    defaultFramebuffer = _gl.createFramebuffer();
    defaultFramebufferTexture = _gl.createTexture();

    _gl.activeTexture(WebGL.TEXTURE0);
    _gl.bindTexture(WebGL.TEXTURE_2D, defaultFramebufferTexture);
    _gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, glWidth, glHeight, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, null);
    _gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);
    _gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.LINEAR);

    _gl.bindFramebuffer(WebGL.FRAMEBUFFER, defaultFramebuffer);
    _gl.framebufferTexture2D(WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, defaultFramebufferTexture, 0);
  }

  Future<void> render() async{
    int _current = DateTime.now().millisecondsSinceEpoch;
    double _blue = sin((_current - t) / 500);
    double _green = cos((_current - t) / 500);
    double _red = tan((_current - t) / 500);

    _gl.viewport(0, 0, width.toInt(), height.toInt());
    _gl.clearColor(_red, _green, _blue, 1.0);
    _gl.clear(WebGL.COLOR_BUFFER_BIT);
    
    _gl.useProgram(glProgram);
    _gl.drawArrays(WebGL.TRIANGLES, 0, n);
    _gl.gl.glFinish();

    await angle.updateTexture(sourceTexture,defaultFramebufferTexture);
  }

  void prepare() {
    var vs = """
      #version 300 es
      #define attribute in
      #define varying out
      attribute vec3 a_Position;
      // layout (location = 0) in vec3 a_Position;
      void main() {
          gl_Position = vec4(a_Position, 1.0);
      }
    """;

    var fs = """
      #version 300 es
      out highp vec4 pc_fragColor;
      #define gl_FragColor pc_fragColor

      void main() {
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
      }
    """;

    if (!initShaders(_gl, vs, fs)) {
      print('Failed to intialize shaders.');
      return;
    }

    // Write the positions of vertices to a vertex shader
    n = initVertexBuffers(_gl);
    if (n < 0) {
      print('Failed to set the positions of the vertices');
      return;
    }
  }

  int initVertexBuffers(RenderingContext gl) {
    // Vertices
    final dim = 3;
    vertices = Float32Array.fromList([
      -0.5, -0.5, 0, // Vertice #2
      0.5, -0.5, 0, // Vertice #3
      0, 0.5, 0, // Vertice #1
    ]);
    
    // Create a buffer object
    dynamic vertexBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferData(WebGL.ARRAY_BUFFER, vertices!, WebGL.STATIC_DRAW);

    // Assign the vertices in buffer object to a_Position variable
    final a_Position = gl.getAttribLocation(glProgram, 'a_Position').id;
    if (a_Position < 0) {
      print('Failed to get the storage location of a_Position');
      return -1;
    }

    gl.vertexAttribPointer(a_Position, dim, WebGL.FLOAT, false, Float32List.bytesPerElement * 3, 0);
    gl.enableVertexAttribArray(a_Position);

    // Return number of vertices
    return vertices!.length ~/ dim;
  }

  bool initShaders(RenderingContext gl, String vs_source, String fs_source) {
    // Compile shaders
    final vertexShader = makeShader(gl, vs_source, WebGL.VERTEX_SHADER);
    final fragmentShader = makeShader(gl, fs_source, WebGL.FRAGMENT_SHADER);

    // Create program
    glProgram = gl.createProgram();

    // Attach and link shaders to the program
    gl.attachShader(glProgram, vertexShader);
    gl.attachShader(glProgram, fragmentShader);
    gl.linkProgram(glProgram);
    final _res = gl.getProgramParameter(glProgram, WebGL.LINK_STATUS);
    print(" initShaders LINK_STATUS _res: ${_res} ");
    if (_res == false || _res == 0) {
      print("Unable to initialize the shader program");
      return false;
    }

    // Use program
    gl.useProgram(glProgram);

    return true;
  }

  dynamic makeShader(RenderingContext gl, String src, int type) {
    dynamic shader = gl.createShader(type);
    gl.shaderSource(shader, src);
    gl.compileShader(shader);
    gl.shaderSource(shader, WebGL.COMPILE_STATUS.toString());
    // if (_res == 0 || _res == false) {
    //   print("Error compiling shader: ${gl.getShaderInfoLog(shader)}");
    //   return;
    // }
    return shader;
  }
}
