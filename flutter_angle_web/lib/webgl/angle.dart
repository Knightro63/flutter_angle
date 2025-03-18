import 'dart:js_interop';
import 'package:web/web.dart' as html;
import './wrapper.dart';
import '../shared/classes.dart';
import '../shared/options.dart';
import 'dart:async';
import 'gles_bindings.dart';
import 'dart:ui_web' as ui;
import 'dart:math' as math;

class FlutterAngleTexture {
  final html.HTMLCanvasElement? element;
  final int textureId;
  final int rboId;
  final int metalAsGLTextureId;
  late final int androidSurface;
  final int fboId;
  LibOpenGLES? _libOpenGLES;
  late AngleOptions options;
  
  FlutterAngleTexture(
    this.textureId, 
    this.rboId, 
    this.metalAsGLTextureId,
    this.androidSurface, 
    this.element,
    this.fboId, 
    this.options
  );


  LibOpenGLES get rawOpenGl {
    if (_libOpenGLES == null) {
      html.RenderingContext? rc = element?.getContext(
          "webgl", {
            "alpha": options.alpha, 
            "antialias": options.antialias
          }.jsify()
        )!;
      _libOpenGLES = LibOpenGLES(
        rc as html.WebGL2RenderingContext
      );
    }

    return _libOpenGLES!;
  }

  static FlutterAngleTexture fromMap(
    dynamic map, 
    html.HTMLCanvasElement? element,
    int fboId, 
    AngleOptions options
  ) {
    return FlutterAngleTexture(
      map['textureId']! as int,
      map['rbo'] as int? ?? 0,
      map['metalAsGLTexture'] as int? ?? 0,
      map['surface'] as int? ?? 0,
      element,
      fboId,
      options
    );
  }

  Map<String, int> toMap() {
    return {
      'textureId': textureId,
      'rbo': rboId,
      'metalAsGLTexture': metalAsGLTextureId
    };
  }

  /// Whenever you finished your rendering you have to call this function to signal
  /// the Flutterengine that it can display the rendering
  /// Despite this being an asyc function it probably doesn't make sense to await it
  Future<void> signalNewFrameAvailable() async {}

  /// As you can have multiple Texture objects, but WebGL allways draws in the currently
  /// active one you have to call this function if you use more than one Textureobject before
  /// you can start rendering on it. If you forget it you will render into the wrong Texture.
  void activate() {
    //rawOpenGl.glViewport(0, 0, width, height);
  }

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
    print('create texture');
    final _divId = DateTime.now().microsecondsSinceEpoch;
    final element = html.HTMLCanvasElement()
    ..width = (options.width * options.dpr).toInt()
    ..height = (options.height * options.dpr).toInt()
    ..id = 'canvas-id${math.Random().nextInt(100)}';
    print(element);
    ui.platformViewRegistry.registerViewFactory(_divId.toString(), (int viewId) {
      print('did register');
      return element;
    });

    final newTexture = FlutterAngleTexture.fromMap({
      "textureId": _divId
    }, element, 0, options);

    return newTexture;
  }

  Future<void> init([bool useDebugContext = false]) async {
    print('did init');
  }
  Future<void> updateTexture(FlutterAngleTexture texture,[WebGLTexture? sourceTexture]) async {
    texture.rawOpenGl.glFlush();
  }
  Future<void> deleteTexture(FlutterAngleTexture texture) async {}
  void activateTexture(FlutterAngleTexture texture) {}
  void printOpenGLError(String message) {}
}