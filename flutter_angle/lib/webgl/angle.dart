import 'package:flutter/foundation.dart';
import '../shared/classes.dart';
import '../shared/options.dart';
import 'dart:async';
import 'package:web/web.dart' as html;
import 'wrapper_wasm.dart'
  if(dart.library.js) 'wrapper.dart';
import 'gles_bindings.dart';
import 'dart:ui_web' as ui;

class FlutterAngleTexture {
  final int textureId;
  late final int rboId;
  late final dynamic surfaceId;
  late final int fboId;
  late AngleOptions options;
  LibOpenGLES? _libOpenGLES;
  
  
  FlutterAngleTexture(
    FlutterAngle flutterAngle,
    this.textureId, 
    this.rboId, 
    this.fboId,
    this.options
  ){}

  FlutterAngleTexture.fromSurface(
    FlutterAngle flutterAngle,
    this.textureId,
    this.surfaceId,
    this.options
  ) {
    rboId = 0;
    fboId = 0;
  }

  LibOpenGLES get rawOpenGl {
    if (_libOpenGLES == null) {
      if(kIsWasm){
        final rc = RenderingContext.createCanvas(surfaceId);
        _libOpenGLES = LibOpenGLES(rc);
      }
      else{
        var rc = surfaceId?.getContext(
          "webgl2", {
            "alpha": options.alpha, 
            "antialias": options.antialias
          }
        );
        _libOpenGLES = LibOpenGLES(rc);
      }
    }

    return _libOpenGLES!;
  }

  Map<String, int> toMap() {
    return {
      'textureId': textureId,
      'rbo': rboId,
    };
  }

  /// Whenever you finished your rendering you have to call this function to signal
  /// the Flutterengine that it can display the rendering
  /// Despite this being an asyc function it probably doesn't make sense to await it
  Future<void> signalNewFrameAvailable() async {}

  /// As you can have multiple Texture objects, but WebGL allways draws in the currently
  /// active one you have to call this function if you use more than one Textureobject before
  /// you can start rendering on it. If you forget it you will render into the wrong Texture.
  void activate() {}
  RenderingContext getContext() {
    return RenderingContext.create(rawOpenGl,options.width, options.height);
  }
}

class FlutterAngle{

  static void glDebugOutput(
    int source, 
    int type, 
    int id, 
    int severity,
    int length, 
    String pMessage, 
    int pUserParam
  ) {}

  Future<FlutterAngleTexture> createTexture(AngleOptions options) async {
    Completer<FlutterAngleTexture> c = Completer<FlutterAngleTexture>();
    final _divId = DateTime.now().microsecondsSinceEpoch;
    final String id = 'canvas-id$_divId';
    final width = (options.width * options.dpr).toInt();
    final height = (options.height * options.dpr).toInt();

    late final newTexture;
    
    final element = html.HTMLCanvasElement()
    ..width = width
    ..height = height
    ..id = id;

    ui.platformViewRegistry.registerViewFactory(_divId.toString(), (int viewId) {
      return element;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      newTexture = FlutterAngleTexture.fromSurface(
        this,
        _divId,
        element, 
        options
      );

      c.complete(newTexture);
    });


    return c.future;
  }

  Future<void> init([bool useDebugContext = false, bool useAngle = false]) async {}
  Future<void> updateTexture(FlutterAngleTexture texture,[WebGLTexture? sourceTexture]) async {
    texture.rawOpenGl.glFlush();
  }
  Future<void> resize(FlutterAngleTexture texture, AngleOptions options) async{
    texture.surfaceId?.width = (options.width * options.dpr).toInt();
    texture.surfaceId?.height = (options.height * options.dpr).toInt();
  }
  Future<void> deleteTexture(FlutterAngleTexture texture) async {}
  void activateTexture(FlutterAngleTexture texture) {}
  void printOpenGLError(String message) {}
  void dispose([List<FlutterAngleTexture>? textures]){}
}