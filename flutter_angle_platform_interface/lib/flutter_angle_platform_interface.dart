import './shared/classes.dart';
import './shared/options.dart';
import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

class FlutterAngleTexture {
  final dynamic element;
  final int textureId;
  final int rboId;
  final int surfaceId;
  final int fboId;
  final int loc;
  late AngleOptions options;
  
  FlutterAngleTexture(
    FlutterAnglePlatform flutterAngle,
    this.textureId, 
    this.rboId, 
    this.surfaceId,
    this.element,
    this.fboId,
    this.loc,
    this.options
  ) {}

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
  RenderingContext getContext() {}
}

abstract class FlutterAnglePlatform{
  static void glDebugOutput(
    int source, 
    int type, 
    int id, 
    int severity,
    int length, 
    String pMessage, 
    int pUserParam
  ) {}

  Future<FlutterAngleTexture> createTexture(AngleOptions options) async {}
  Future<void> init([bool useDebugContext = false, bool useAngle = false]) async {}
  Future<void> updateTexture(FlutterAngleTexture texture,[dynamic sourceTexture]) async {}
  Future<void> deleteTexture(FlutterAngleTexture texture) async {}
  void activateTexture(FlutterAngleTexture texture) {}
  void printOpenGLError(String message) {}
  void dispose([List<FlutterAngleTexture>? textures]){}
}