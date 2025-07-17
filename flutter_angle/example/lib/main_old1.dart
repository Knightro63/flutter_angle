import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';

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
  FlutterAngle angle = FlutterAngle();
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
    angle.dispose([sourceTexture]);
    super.dispose();
  }

  Future<void> setup() async {
    await angle.init(true);

    sourceTexture = await angle.createTexture(      
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

  Future<void> render() async {
    sourceTexture.activate();
    int _current = DateTime.now().millisecondsSinceEpoch;
    _gl.viewport(0, 0, screenSize.width.toInt(), screenSize.height.toInt());
    double _blue = sin((_current - t) / 500);
  
    // Clear canvas
    _gl.clearColor(1.0, 0.0, _blue, 1.0);
    _gl.clear(WebGL.COLOR_BUFFER_BIT);

    _gl.flush();
    await angle.updateTexture(sourceTexture);
  }
}
