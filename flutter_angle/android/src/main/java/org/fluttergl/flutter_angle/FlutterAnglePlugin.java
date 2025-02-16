package org.fluttergl.flutter_angle;

import android.graphics.SurfaceTexture;
import android.opengl.EGL14;
import android.opengl.EGLObjectHandle;
import android.opengl.EGLSurface;
import android.os.Build;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;
import java.util.HashMap;
import java.util.Map;

// For clarity, we use the tag below for logs
public class FlutterAnglePlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private static final String TAG = "FlutterAnglePlugin";
  private MethodChannel channel;
  private TextureRegistry textureRegistry;

  // Plugin1 (non‑ANGLE) state
  private OpenGLManager openGLManager = null;
  private android.opengl.EGLContext context = null;
  private Map<Long, FlutterGLTexture> flutterTextureMap;

  // Plugin2 (ANGLE) state
  private Map<Long, GLTexture> angleTextureMap;

  // Load ANGLE native libraries (used by ANGLE methods)
  static {
    try {
      System.loadLibrary("EGL_angle");
      System.loadLibrary("GLESv2_angle");
      System.loadLibrary("angle_android_graphic_jni");
      Log.i(TAG, "Native ANGLE libraries loaded successfully");
    } catch (UnsatisfiedLinkError e) {
      Log.e(TAG, "Failed to load native ANGLE libraries", e);
    }
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_angle");
    channel.setMethodCallHandler(this);
    textureRegistry = binding.getTextureRegistry();
    flutterTextureMap = new HashMap<>();
    angleTextureMap = new HashMap<>();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    switch(call.method) {
      case "getPlatformVersion":
        result.success("Android " + Build.VERSION.RELEASE);
        break;

      // Plugin1 methods (non‑ANGLE)
      case "initOpenGL":
        initOpenGLImplementation(result);
        break;
      case "createTexture":
        createTextureImplementation(call, result);
        break;

      // Plugin2 methods (ANGLE) – note the "Angle" suffix
      case "initOpenGLAngle":
        initOpenGLAngleImplementation(result);
        break;
      case "createTextureAngle":
        createTextureAngleImplementation(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  private void initOpenGLImplementation(MethodChannel.Result result) {
    // Plugin1: using OpenGLManager
    openGLManager = (openGLManager == null) ? new OpenGLManager() : openGLManager;
    if(!openGLManager.initGL()){
      result.error("OpenGL Init Error", openGLManager.getError(), null);
      return;
    }
    context = (context == null) ? openGLManager.getEGLContext() : context;

    TextureRegistry.SurfaceTextureEntry entry = textureRegistry.createSurfaceTexture();
    SurfaceTexture surfaceTexture = entry.surfaceTexture();
    surfaceTexture.setDefaultBufferSize(638, 320);
    long dummySurface = openGLManager.createDummySurface().getNativeHandle();

    Map<String, Object> response = new HashMap<>();
    response.put("context", context.getNativeHandle());
    response.put("eglConfigId", openGLManager.getConfigId());
    response.put("dummySurface", dummySurface);
    result.success(response);
  }

  private void createTextureImplementation(MethodCall call, MethodChannel.Result result) {
    // Plugin1: create texture using FlutterGLTexture
    Map<String, Object> arguments = (Map<String, Object>) call.arguments;
    int width = (int) arguments.get("width");
    int height = (int) arguments.get("height");

    if (width <= 0) {
      result.error("no texture width", "no texture width", 0);
      return;
    }
    if (height <= 0) {
      result.error("no texture height", "no texture height", null);
      return;
    }
    FlutterGLTexture texture;
    try {
      TextureRegistry.SurfaceTextureEntry entry = textureRegistry.createSurfaceTexture();
      texture = new FlutterGLTexture(entry, openGLManager, width, height);
    } catch(Exception ex) {
      result.error(ex.getMessage(), ex.toString(), null);
      return;
    }
    flutterTextureMap.put(texture.surfaceTextureEntry.id(), texture);

    Map<String, Object> response = new HashMap<>();
    response.put("textureId", texture.surfaceTextureEntry.id());
    response.put("surface", texture.surface.getNativeHandle());
    result.success(response);
    Log.i(TAG, "Created Flutter texture " + width + "x" + height);
  }

  // ANGLE (plugin2) methods: renamed with 'Angle'

  private void initOpenGLAngleImplementation(MethodChannel.Result result) {
    // Plugin2: using native ANGLE functions
    if (!init()) {
      String error = getError();
      Log.e(TAG, "ANGLE init failed: " + error);
      result.error("OpenGL Init Error", error, null);
      return;
    }
    TextureRegistry.SurfaceTextureEntry entry = textureRegistry.createSurfaceTexture();
    SurfaceTexture surfaceTexture = entry.surfaceTexture();
    surfaceTexture.setDefaultBufferSize(638, 320);
    long dummySurface = createWindowSurfaceFromTexture(surfaceTexture);

    Map<String, Object> response = new HashMap<>();
    response.put("context", getCurrentContext());
    response.put("dummySurface", dummySurface);
    result.success(response);
    Log.i(TAG, "ANGLE OpenGL initialized successfully");
  }

  private void createTextureAngleImplementation(MethodCall call, MethodChannel.Result result) {
    try {
      @SuppressWarnings("unchecked")
      Map<String, Object> args = (Map<String, Object>) call.arguments;
      int width = (int) args.get("width");
      int height = (int) args.get("height");
      if (width <= 0 || height <= 0) {
        result.error("Invalid dimensions", "Width and height must be positive", null);
        return;
      }
      GLTexture texture = new GLTexture(textureRegistry.createSurfaceTexture(), width, height);
      angleTextureMap.put(texture.entry.id(), texture);
      Map<String, Object> response = new HashMap<>();
      response.put("textureId", texture.entry.id());
      response.put("surface", texture.surfaceHandle);
      result.success(response);
      Log.i(TAG, String.format("Created ANGLE texture %dx%d", width, height));
    } catch (Exception e) {
      Log.e(TAG, "ANGLE texture creation failed", e);
      result.error("Texture creation failed", e.getMessage(), null);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    // Dispose Plugin1 textures
    for (FlutterGLTexture texture : flutterTextureMap.values()) {
      try {
        texture.finalize();
      } catch (Throwable e) {
        Log.e(TAG, "Error disposing Flutter texture", e);
      }
    }
    flutterTextureMap.clear();

    // Dispose ANGLE textures
    for (GLTexture texture : angleTextureMap.values()) {
      try {
        texture.dispose();
      } catch (Exception e) {
        Log.e(TAG, "Error disposing ANGLE texture", e);
      }
    }
    angleTextureMap.clear();

    // Deinitialize native ANGLE resources
    deinit();
  }

  // --- Native methods (used for ANGLE calls) ---
  private static native boolean init();
  private static native void deinit();
  private static native String getError();
  private static native long getCurrentContext();
  private static native long createWindowSurfaceFromTexture(SurfaceTexture texture);

  // --- Helper classes ---
  // FlutterGLTexture used by plugin1 implementation
  @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR1)
  static class FlutterGLTexture {
    final TextureRegistry.SurfaceTextureEntry surfaceTextureEntry;
    final OpenGLManager openGLManager;
    final int width;
    final int height;
    final EGLSurface surface;

    FlutterGLTexture(TextureRegistry.SurfaceTextureEntry entry, OpenGLManager manager, int width, int height) {
      this.surfaceTextureEntry = entry;
      this.openGLManager = manager;
      this.width = width;
      this.height = height;
      entry.surfaceTexture().setDefaultBufferSize(width, height);
      this.surface = manager.createSurfaceFromTexture(entry.surfaceTexture());
    }

    @Override
    protected void finalize() throws Throwable {
      surfaceTextureEntry.release();
      EGL14.eglDestroySurface(openGLManager.getEglDisplayAndroid(), surface);
      super.finalize();
    }
  }

  // GLTexture used by ANGLE (plugin2) implementation
  private static class GLTexture {
    final TextureRegistry.SurfaceTextureEntry entry;
    final long surfaceHandle;
    final int width;
    final int height;
    private boolean disposed = false;

    GLTexture(TextureRegistry.SurfaceTextureEntry entry, int width, int height) {
      this.entry = entry;
      this.width = width;
      this.height = height;
      entry.surfaceTexture().setDefaultBufferSize(width, height);
      this.surfaceHandle = createWindowSurfaceFromTexture(entry.surfaceTexture());
      if (this.surfaceHandle == 0) {
        throw new RuntimeException("Failed to create EGL surface: " + getError());
      }
    }

    void dispose() {
      if (!disposed) {
        entry.release();
        disposed = true;
      }
    }

    @Override
    protected void finalize() throws Throwable {
      dispose();
      super.finalize();
    }
  }
}