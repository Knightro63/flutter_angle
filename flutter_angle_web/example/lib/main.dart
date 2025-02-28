import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle_web/flutter_angle_web.dart';

void main() {
  runApp(ExampleDemoTest());
}

class ExampleDemoTest extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<ExampleDemoTest> {
  late FlutterAngle flutterGlPlugin;

  int? fboId;
  bool ready = false;
  double dpr = 1.0;

  late Size screenSize;

  late FlutterAngleTexture sourceTexture;
  late final defaultFramebufferTexture;

  int n = 0;
  late final RenderingContext _gl;
  int t = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      setup();
    });
    super.initState();
  }

  @override
  void dispose(){
    FlutterAngle.deleteTexture(sourceTexture);
    super.dispose();
  }

  Future<void> setup() async {
    await FlutterAngle.initOpenGL(true);

    sourceTexture = await FlutterAngle.createTexture(      
      AngleOptions(
        width: screenSize.width.toInt(), 
        height: screenSize.height.toInt(), 
        dpr: dpr,
      ),
    );

    _gl = sourceTexture.getContext();

    setState(() {
      ready = true;
    });
    animate();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    screenSize = mq.size;
    dpr = mq.devicePixelRatio;

    return MaterialApp(
      home: Scaffold(
        body: Container(
          width: screenSize.width,
          height: screenSize.height,
          color: Colors.black,
          child: kIsWeb?ready?HtmlElementView(viewType: sourceTexture.textureId.toString()):Container()
            :ready?Texture(textureId: sourceTexture.textureId):Container()
        )
      ),
    );
  }

  void animate() {
    render();

    Future.delayed(Duration(milliseconds: 40), () {
      animate();
    });
  }

  void setupDefaultFBO() {
    int glWidth = (screenSize.width * dpr).toInt();
    int glHeight = (screenSize.height * dpr).toInt();

    final defaultFramebuffer = _gl.createFramebuffer();
    defaultFramebufferTexture = _gl.createTexture();
    _gl.activeTexture(WebGL.TEXTURE0);

    _gl.bindTexture(WebGL.TEXTURE_2D, defaultFramebufferTexture);
    _gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, glWidth, glHeight, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, null);
    _gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);
    _gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.LINEAR);

    _gl.bindFramebuffer(WebGL.FRAMEBUFFER, defaultFramebuffer);
    _gl.framebufferTexture2D(WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, defaultFramebufferTexture, 0);
  }

  Future<void> render() async {
    sourceTexture.activate();
    int _current = DateTime.now().millisecondsSinceEpoch;
    _gl.viewport(0, 0, screenSize.width.toInt(), screenSize.height.toInt());
    double _blue = sin((_current - t) / 500);
  
    // Clear canvas
    _gl.clearColor(1.0, 0.0, _blue, 1.0);
    _gl.clear(WebGL.COLOR_BUFFER_BIT);

    _gl.flush();
    await FlutterAngle.updateTexture(sourceTexture);
  }
}
