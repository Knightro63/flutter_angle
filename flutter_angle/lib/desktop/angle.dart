import 'package:flutter/widgets.dart';
import 'package:flutter_angle/desktop/bindings/egl_bindings.dart';
import 'package:flutter_angle/desktop/render_worker.dart';
import 'package:flutter_angle/flutter_angle.dart';

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:dylib/dylib.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_angle/shared/console.dart';
import 'lib_egl.dart';

class FlutterAngleTexture {
  final dynamic element;
  final int textureId;
  final int rboId;
  final Pointer<Void>? surfaceId;
  final int fboId;
  final int loc;
  late AngleOptions options;
  late final FlutterAngle _flutterAngle;

  LibOpenGLES get rawOpenGl {
    return _flutterAngle._rawOpenGl;
  }

  FlutterAngleTexture(
    FlutterAngle flutterAngle,
    this.textureId,
    this.rboId,
    this.surfaceId,
    this.element,
    this.fboId,
    this.loc,
    this.options
  ) {
    _flutterAngle = flutterAngle;
  }

  Map<String, int> toMap() {
    return {
      'textureId': textureId,
      'rbo': rboId,
    };
  }

  RenderingContext getContext() {
    assert(_flutterAngle._baseAppContext != nullptr, "OpenGL isn't initialized! Please call FlutterAngle.initOpenGL");
    return RenderingContext.create(_flutterAngle._rawOpenGl, options.width, options.height);
  }

  /// Whenever you finished your rendering you have to call this function to signal
  /// the Flutterengine that it can display the rendering
  /// Despite this being an asyc function it probably doesn't make sense to await it
  Future<void> signalNewFrameAvailable() async {
    await _flutterAngle.updateTexture(this);
  }

  /// As you can have multiple Texture objects, but WebGL allways draws in the currently
  /// active one you have to call this function if you use more than one Textureobject before
  /// you can start rendering on it. If you forget it you will render into the wrong Texture.
  void activate() {
    _flutterAngle.activateTexture(this);
    _flutterAngle._rawOpenGl.glViewport(0, 0, options.width, options.height);
  }
}

class FlutterAngle {
  final MethodChannel _channel = const MethodChannel('flutter_angle');
  LibOpenGLES? _libOpenGLES;
  Pointer<Void> _display = nullptr;
  late Pointer<Void> _EGLconfig;
  Pointer<Void> _baseAppContext = nullptr;
  Pointer<Void> _pluginContext = nullptr;
  late Pointer<Void> _dummySurface;
  int? _activeFramebuffer;
  late RenderWorker _worker;

  bool _useAngle = false;
  bool _didInit = false;
  bool _isApple = false;

  LibOpenGLES get _rawOpenGl {
    if (_libOpenGLES == null) {
      if (Platform.isIOS || Platform.isMacOS) {
        _libOpenGLES = LibOpenGLES(DynamicLibrary.process());
      } else if (Platform.isAndroid) {
        if (_useAngle) {
          _libOpenGLES = LibOpenGLES(DynamicLibrary.open('libGLESv2_angle.so'));
        } else {
          _libOpenGLES = LibOpenGLES(DynamicLibrary.open('libGLESv3.so'));
        }
      } else {
        _libOpenGLES = LibOpenGLES(DynamicLibrary.open(resolveDylibPath('libGLESv2')));
      }
    }
    return _libOpenGLES!;
  }

  // Next stepps:
  // * test on all plaforms
  // * mulitple textures on Android and the other OSs
  Future<void> init([bool useDebugContext = false, bool useAngle = true]) async {
    if (_didInit) return;
    _isApple = Platform.isIOS || Platform.isMacOS;
    _useAngle = useAngle;
    _didInit = true;
    
    /// make sure we don't call this twice
    if (_display != nullptr) {
      return;
    }

    // Initialize native part of he plugin
    late final dynamic result;
    if (Platform.isAndroid && _useAngle) {
      result = await _channel.invokeMethod('initOpenGLAngle');
      _useAngle = result['isEmulator'] == null?_useAngle:!result['isEmulator'];
    } else {
      _useAngle = false;
      result = await _channel.invokeMethod('initOpenGL');
    }

    loadEGL(useAngle: _useAngle);
    angleConsole.info(result);

    if (result == null) {
      throw EglException('Plugin.initOpenGL didn\'t return anything. Something is really wrong!');
    }
    if (!_isApple) {
      final pluginContextAdress = result['context'] ?? result['openGLContext'];
      if (pluginContextAdress == null) {
        throw EglException('Plugin.initOpenGL didn\'t return a Context. Something is really wrong!');
      }

      _pluginContext = Pointer<Void>.fromAddress(pluginContextAdress);

      final dummySurfacePointer = result['dummySurface'] as int?;
      if (dummySurfacePointer == null) {
        throw EglException('Plugin.initOpenGL didn\'t return a dummy surface. Something is really wrong!');
      }
      _dummySurface = Pointer<Void>.fromAddress(dummySurfacePointer);
    }

    /// Init OpenGL on the Dart side too
    _display = eglGetDisplay();
    final initializeResult = eglInitialize(_display);

    debugPrint('EGL version: $initializeResult');

    late final Map<EglConfigAttribute, int> eglAttributes;

    /// In case the plugin returns its selected EGL config we use it.
    /// Finally this should be how all platforms behave. Till all platforms
    /// support this we leave this check here
    final eglConfigId = (result is Map && result.containsKey('eglConfigId'))? result['eglConfigId'] as int?: null;
    if (eglConfigId != null) {
      eglAttributes = {
        EglConfigAttribute.configId: eglConfigId,
      };
    } else {
      eglAttributes = {
        EglConfigAttribute.renderableType: EglValue.openglEs3Bit.toIntValue(),
        EglConfigAttribute.redSize: 8,
        EglConfigAttribute.greenSize: 8,
        EglConfigAttribute.blueSize: 8,
        EglConfigAttribute.alphaSize: 8,
        EglConfigAttribute.depthSize: 24,
        EglConfigAttribute.samples: 4,
        EglConfigAttribute.stencilSize: 8,
        EglConfigAttribute.sampleBuffers: 1,
      };
    }
    final chooseConfigResult = eglChooseConfig(
      _display,
      attributes: eglAttributes,
      maxConfigs: 1,
    );
    _EGLconfig = chooseConfigResult[0];

    _baseAppContext = eglCreateContext(
      _display, 
      _EGLconfig,
      shareContext: _pluginContext == nullptr?null:_pluginContext,
      contextClientVersion: 3,
      isDebugContext: useDebugContext && !Platform.isAndroid
    );

    if(!_isApple){
      /// bind context to this thread. All following OpenGL calls from this thread will use this context
      eglMakeCurrent(_display, _dummySurface, _dummySurface, _baseAppContext);
    
      if (useDebugContext && Platform.isWindows) {
        _rawOpenGl.glEnable(GL_DEBUG_OUTPUT);
        _rawOpenGl.glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
        _rawOpenGl.glDebugMessageCallback(Pointer.fromFunction<GLDEBUGPROC>(glDebugOutput), nullptr);
        _rawOpenGl.glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, nullptr, GL_TRUE);
      }
    }
  }

  static void glDebugOutput(int source, int type, int id, int severity,
      int length, Pointer<Int8> pMessage, Pointer<Void> pUserParam) {
    final message = pMessage.cast<Utf8>().toDartString();
    // ignore non-significant error/warning codes
    // if (id == 131169 || id == 131185 || id == 131218 || id == 131204) return;

    String error = "---------------\n";
    error += "Debug message $id  $message\n";

    switch (source) {
      case GL_DEBUG_SOURCE_API:
        error += "Source: API";
        break;
      case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
        error += "Source: Window System";
        break;
      case GL_DEBUG_SOURCE_SHADER_COMPILER:
        error += "Source: Shader Compiler";
        break;
      case GL_DEBUG_SOURCE_THIRD_PARTY:
        error += "Source: Third Party";
        break;
      case GL_DEBUG_SOURCE_APPLICATION:
        error += "Source: Application";
        break;
      case GL_DEBUG_SOURCE_OTHER:
        error += "Source: Other";
        break;
    }
    error += '\n';
    switch (type) {
      case GL_DEBUG_TYPE_ERROR:
        error += "Type: Error";
        break;
      case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
        error += "Type: Deprecated Behaviour";
        break;
      case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
        error += "Type: Undefined Behaviour";
        break;
      case GL_DEBUG_TYPE_PORTABILITY:
        error += "Type: Portability";
        break;
      case GL_DEBUG_TYPE_PERFORMANCE:
        error += "Type: Performance";
        break;
      case GL_DEBUG_TYPE_MARKER:
        error += "Type: Marker";
        break;
      case GL_DEBUG_TYPE_PUSH_GROUP:
        error += "Type: Push Group";
        break;
      case GL_DEBUG_TYPE_POP_GROUP:
        error += "Type: Pop Group";
        break;
      case GL_DEBUG_TYPE_OTHER:
        error += "Type: Other";
        break;
    }
    error += '\n';
    switch (severity) {
      case GL_DEBUG_SEVERITY_HIGH:
        error += "Severity: high";
        break;
      case GL_DEBUG_SEVERITY_MEDIUM:
        error += "Severity: medium";
        break;
      case GL_DEBUG_SEVERITY_LOW:
        error += "Severity: low";
        break;
      case GL_DEBUG_SEVERITY_NOTIFICATION:
        error += "Severity: notification";
        break;
    }
    error += '\n';

    angleConsole.error(error);
  }

  /// For iOS only: Creates an EGL surface from an IOSurface pointer
  Pointer<Void>? createEGLSurfaceFromIOSurface(Pointer<Void> ioSurfacePtr, int width, int height) {
    if (!_isApple) return null;

    final textureTarget = getTextureTarget(_display, _EGLconfig);

    final surfaceAttribs = calloc<Int32>(20);
    int i = 0;
    surfaceAttribs[i++] = EGL_WIDTH;
    surfaceAttribs[i++] = width;
    surfaceAttribs[i++] = EGL_HEIGHT;
    surfaceAttribs[i++] = height;
    surfaceAttribs[i++] = EGL_IOSURFACE_PLANE_ANGLE;
    surfaceAttribs[i++] = 0;
    surfaceAttribs[i++] = EGL_TEXTURE_TARGET;
    surfaceAttribs[i++] = textureTarget;
    surfaceAttribs[i++] = EGL_TEXTURE_INTERNAL_FORMAT_ANGLE;
    surfaceAttribs[i++] = GL_BGRA_EXT;
    surfaceAttribs[i++] = EGL_TEXTURE_FORMAT;
    surfaceAttribs[i++] = EGL_TEXTURE_RGBA;
    surfaceAttribs[i++] = EGL_TEXTURE_TYPE_ANGLE;
    surfaceAttribs[i++] = GL_UNSIGNED_BYTE;
    surfaceAttribs[i++] = EGL_NONE;

    Pointer<Void>? macIosSurface;
    try {
      macIosSurface = eglCreatePbufferFromClientBuffer(
        _display,
        EGL_IOSURFACE_ANGLE, // 0x3454
        ioSurfacePtr,
        _EGLconfig,
        surfaceAttribs
      );

      if (macIosSurface != nullptr) {
        // Immediately make the surface current to initialize it properly
        try {
          eglMakeCurrent(_display, macIosSurface, macIosSurface, _baseAppContext);
          angleConsole.info("Successfully made EGL surface current from IOSurface");
        } catch (e) {
          angleConsole.error("Failed to make EGL surface current: $e");
          return null;
        }
      }

      angleConsole.info("Successfully created EGL surface from IOSurface");
    } catch (e) {
      angleConsole.error("Failed to create EGL surface from IOSurface: $e");
      macIosSurface = nullptr;
    } finally {
      calloc.free(surfaceAttribs);
    }

    return macIosSurface;
  }

  Future<FlutterAngleTexture> createTexture(AngleOptions options) async {
    final height = (options.height * options.dpr).toInt();
    final width = (options.width * options.dpr).toInt();
    late final dynamic result;
    if (_useAngle) {
      result = await _channel.invokeMethod('createTextureAngle', {
        "width": width,
        "height": height,
        "useSurfaceProducer": options.useSurfaceProducer
      });
    } else {
      result = await _channel.invokeMethod('createTexture', {
        "width": width,
        "height": height,
        "useSurfaceProducer": options.useSurfaceProducer
      });
    }

    if (Platform.isAndroid) {
      final newTexture = FlutterAngleTexture(
        this,
        result['textureId']! as int,
        result['rbo'] as int? ?? 0,
        Pointer.fromAddress(result['surface'] as int? ?? 0),
        null,
        0,
        result['location'] as int? ?? 0,
        options
      );
      _rawOpenGl.glViewport(0, 0, width, height);

      if (!options.customRenderer) {
        _worker = RenderWorker(newTexture);
      }

      return newTexture;
    }
    else if (_isApple) {
      // Create the EGL surface from IOSurface before creating the texture object
      Pointer<Void>? macIosSurface;
      if (result.containsKey('surfacePointer')) {
        final surfacePointer = result['surfacePointer'] as int;
        if (surfacePointer != 0) {
          final ioSurfacePtr = Pointer<Void>.fromAddress(surfacePointer);
          macIosSurface = createEGLSurfaceFromIOSurface(ioSurfacePtr, width, height);
          if (macIosSurface == null) {
            angleConsole.error("Failed to create EGL surface from IOSurface");
          } else {
            angleConsole.info("Successfully created EGL surface from IOSurface");
          }
        }
      }

      final newTexture = FlutterAngleTexture(
        this,
        result['textureId']! as int,
        result['rbo'] as int? ?? 0,
        macIosSurface, // We'll use an IOSurface instead
        null,
        0,
        result['location'] as int? ?? 0,
        options
      );

      _rawOpenGl.glViewport(0, 0, width, height);

      if (!options.customRenderer) {
        _worker = RenderWorker(newTexture);
      }

      return newTexture;
    }

    Pointer<Uint32> fbo = calloc();
    _rawOpenGl.glGenFramebuffers(1, fbo);
    _rawOpenGl.glBindFramebuffer(GL_FRAMEBUFFER, fbo.value);

    final newTexture = FlutterAngleTexture(
      this,
      result['textureId']! as int,
      result['rbo'] as int? ?? 0,
      Pointer.fromAddress(result['surface'] as int? ?? 0),
      null,
      fbo.value,
      result['location'] as int? ?? 0,
      options
    );
    angleConsole.info(newTexture.toMap());
    angleConsole.info(_rawOpenGl.glGetError());
    _rawOpenGl.glActiveTexture(WebGL.TEXTURE0);

    _rawOpenGl.glBindRenderbuffer(GL_RENDERBUFFER, newTexture.rboId);
    _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, newTexture.rboId);

    var frameBufferCheck = _rawOpenGl.glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE) {
      angleConsole.error("Framebuffer (color) check failed: $frameBufferCheck");
    }

    _rawOpenGl.glViewport(0, 0, width, height);

    Pointer<Int32> depthBuffer = calloc();
    _rawOpenGl.glGenRenderbuffers(1, depthBuffer.cast());
    _rawOpenGl.glBindRenderbuffer(GL_RENDERBUFFER, depthBuffer.value);
    _rawOpenGl.glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height); //,GL_DEPTH_COMPONENT16//GL_DEPTH24_STENCIL8

    _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthBuffer.value);

    frameBufferCheck = _rawOpenGl.glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE) {
      angleConsole.error("Framebuffer (depth) check failed: $frameBufferCheck");
    }

    _activeFramebuffer = fbo.value;

    calloc.free(depthBuffer);
    calloc.free(fbo);

    if (!options.customRenderer) {
      _worker = RenderWorker(newTexture);
    }

    return newTexture;
  }

  Future<void> updateTexture(FlutterAngleTexture texture, [WebGLTexture? sourceTexture]) async {
    if (sourceTexture != null) {
      _rawOpenGl.glClearColor(0.0, 0.0, 0.0, 0.0);
      _rawOpenGl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
      _rawOpenGl.glViewport(0, 0, (texture.options.width*texture.options.dpr).toInt(),( texture.options.height*texture.options.dpr).toInt());
      _worker.renderTexture(sourceTexture, isFBO: Platform.isAndroid);
      _rawOpenGl.glFinish();
    }

    // If we have an iOS EGL surface created from IOSurface, use it
    if ((_isApple || Platform.isAndroid) && texture.surfaceId != nullptr) {
      eglSwapBuffers(_display, texture.surfaceId!);
      if (_isApple) {
        await _channel.invokeMethod('textureFrameAvailable', texture.textureId);
      }
      return;
    }

    _rawOpenGl.glFlush();
    assert(_activeFramebuffer != null, 'There is no active FlutterGL Texture to update');
    await _channel.invokeMethod('updateTexture', {"textureId": texture.textureId, "location": texture.loc});
  }

  Future<void> deleteTexture(FlutterAngleTexture texture) async {
    if (Platform.isAndroid) {
      return;
    }
    else if(_isApple){
      await _channel.invokeMethod('deleteTexture',texture.textureId);
      return;
    }

    assert(_activeFramebuffer != null, 'There is no active FlutterGL Texture to delete');
    if (_activeFramebuffer == texture.fboId) {
      _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, 0);

      Pointer<Uint32> fbo = calloc();
      fbo.value = texture.fboId;
      _rawOpenGl.glDeleteBuffers(1, fbo);
      calloc.free(fbo);
    }

    await _channel.invokeMethod('deleteTexture',{"textureId": texture.textureId, "location": texture.loc});
  }

  void dispose([List<FlutterAngleTexture>? textures]) {
    textures?.forEach((t) {
      deleteTexture(t);
    });
    // if(_display != nullptr) calloc.free(_display);
    // if(_EGLconfig != nullptr) calloc.free(_EGLconfig);
    // if(_baseAppContext != nullptr) calloc.free(_baseAppContext);
    // if(_pluginContext != nullptr) calloc.free(_pluginContext);
    // if(_dummySurface != nullptr) calloc.free(_dummySurface);
    _worker.dispose();
    _libOpenGLES = null;
  }

  void activateTexture(FlutterAngleTexture texture) {
    _rawOpenGl.glBindFramebuffer(GL_FRAMEBUFFER, texture.fboId);

    // If we have an iOS EGL surface created from IOSurface, use it
    if ((_isApple || Platform.isAndroid) && texture.surfaceId != nullptr) {
      eglMakeCurrent(_display, texture.surfaceId!, texture.surfaceId!, _baseAppContext);
      return;
    }

    _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, texture.rboId);
    _activeFramebuffer = texture.fboId;
  }

  void printOpenGLError(String message) {
    var glGetError = _rawOpenGl.glGetError();
    if (glGetError != GL_NO_ERROR) {
      angleConsole.error('$message: $glGetError');
    }
  }
}
