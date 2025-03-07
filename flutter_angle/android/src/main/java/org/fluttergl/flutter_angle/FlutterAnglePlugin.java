package org.fluttergl.flutter_angle;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import io.flutter.view.TextureRegistry;

import android.graphics.SurfaceTexture;
import android.opengl.EGL14;
import android.opengl.EGL15;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLObjectHandle;
import android.opengl.EGLSurface;
import android.opengl.GLES30;
import android.os.Build;
import android.util.Log;
import android.view.Surface;

import java.util.HashMap;
import java.util.Map;

import static android.opengl.EGL14.EGL_ALPHA_SIZE;
import static android.opengl.EGL14.EGL_BLUE_SIZE;
import static android.opengl.EGL14.EGL_CONTEXT_CLIENT_VERSION;
import static android.opengl.EGL14.EGL_DEFAULT_DISPLAY;
import static android.opengl.EGL14.EGL_DEPTH_SIZE;
import static android.opengl.EGL14.EGL_GREEN_SIZE;
import static android.opengl.EGL14.EGL_HEIGHT;
import static android.opengl.EGL14.EGL_NONE;
import static android.opengl.EGL14.EGL_NO_CONTEXT;
import static android.opengl.EGL14.EGL_NO_SURFACE;
import static android.opengl.EGL14.EGL_RED_SIZE;
import static android.opengl.EGL14.EGL_RENDERABLE_TYPE;
import static android.opengl.EGL14.EGL_WIDTH;
import static android.opengl.EGL14.eglCreateWindowSurface;
import static android.opengl.EGL14.eglMakeCurrent;
import static android.opengl.EGL15.EGL_OPENGL_ES3_BIT;
import static android.opengl.EGL15.EGL_PLATFORM_ANDROID_KHR;
import static android.opengl.EGLExt.EGL_OPENGL_ES3_BIT_KHR;
import static android.opengl.GLES20.GL_NO_ERROR;
import static android.opengl.GLES20.GL_RENDERER;
import static android.opengl.GLES20.GL_VENDOR;
import static android.opengl.GLES20.GL_VERSION;
import static android.opengl.GLES20.glGetError;

class OpenGLException extends Throwable {

  OpenGLException(String message, int error)
  {
    this.error = error;
    this.message = message;
  }
  int error;
  String message;
};

@RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR1)
class MyEGLContext extends EGLObjectHandle {
  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  MyEGLContext(long handle)
  {
    super(handle);
  }
}


class FlutterGLTexture {
  public
  FlutterGLTexture(TextureRegistry.SurfaceTextureEntry textureEntry, OpenGLManager openGLManager, int width, int height) {
    this.with = width;
    this.height = height;
    this.openGLManager = openGLManager;
    this.usingSurfaceProducer = false;
    this.surfaceTextureEntry = textureEntry;
    this.surfaceProducer = null;
    surfaceTextureEntry.surfaceTexture().setDefaultBufferSize(width, height);
    surface = openGLManager.createSurfaceFromTexture(surfaceTextureEntry.surfaceTexture());
  }
  
  public
  FlutterGLTexture(TextureRegistry.SurfaceProducer surfaceProducer, OpenGLManager openGLManager, int width, int height) {
    this.with = width;
    this.height = height;
    this.openGLManager = openGLManager;
    this.usingSurfaceProducer = true;
    this.surfaceTextureEntry = null;
    this.surfaceProducer = surfaceProducer;
    surfaceProducer.setSize(width, height);
    surface = openGLManager.createSurfaceFromSurface(surfaceProducer.getSurface());
  }

  protected void finalize() {
    if (usingSurfaceProducer && surfaceProducer != null) {
      surfaceProducer.release();
    } else if (surfaceTextureEntry != null) {
      surfaceTextureEntry.release();
    }
    EGL14.eglDestroySurface(openGLManager.getEglDisplayAndroid(), surface);
  }

  OpenGLManager openGLManager;
  int with;
  int height;
  EGLSurface surface;
  TextureRegistry.SurfaceTextureEntry surfaceTextureEntry;
  TextureRegistry.SurfaceProducer surfaceProducer;
  boolean usingSurfaceProducer;
  
  public long getTextureId() {
    return usingSurfaceProducer ? surfaceProducer.id() : surfaceTextureEntry.id();
  }
}

/** FlutterAnglePlugin */
public class FlutterAnglePlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private EGLContext context = null;
  private TextureRegistry textureRegistry;
  private OpenGLManager openGLManager = null;
  private Map<Long,FlutterGLTexture> textureMap;
  private static final String TAG = "FlutterAnglePlugin";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_angle");
    channel.setMethodCallHandler(this);
    textureRegistry = flutterPluginBinding.getTextureRegistry();
    textureMap = new HashMap<>();
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Map<String, Object> arguments = (Map<String, Object>) call.arguments;
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }
    else if (call.method.equals("initOpenGL")) {
      openGLManager = openGLManager == null? new OpenGLManager():openGLManager;

      if(!openGLManager.initGL()){
        result.error("OpenGL Init Error",openGLManager.getError(),null);
        return;
      }
      context = context == null?openGLManager.getEGLContext():context;

      TextureRegistry.SurfaceTextureEntry surfaceTextureEntry = textureRegistry.createSurfaceTexture();
      SurfaceTexture surfaceTexture = surfaceTextureEntry.surfaceTexture();
      surfaceTexture.setDefaultBufferSize(638,320);
      long surface = openGLManager.createSurfaceFromTexture(surfaceTexture).getNativeHandle();

      Map<String, Object> response = new HashMap<>();
      response.put("context", context.getNativeHandle());
      response.put("eglConfigId",openGLManager.getConfigId());
      //response.put("dummySurface",surface );
      response.put("dummySurface",openGLManager.createDummySurface().getNativeHandle());
      result.success(response);
      return;
    }
    else if (call.method.equals("createTexture")){
      int width = (int) arguments.get("width");
      int height = (int) arguments.get("height");

      if (width == 0) {
        result.error("no texture width","no texture width",0);
        return;
      }
      if (height==0) {
        result.error("no texture height","no texture height",null);
        return;
      }
      
      FlutterGLTexture flutterGLTexture;

      try {
        // Try to use the new SurfaceProducer API first
        boolean useSurfaceProducer = true;
        
        if (useSurfaceProducer) {
          // Use the new API
          TextureRegistry.SurfaceProducer producer = textureRegistry.createSurfaceProducer();
          flutterGLTexture = new FlutterGLTexture(producer, openGLManager, width, height);
          Log.i(TAG, "Created texture using SurfaceProducer API");
        } else {
          // Fall back to the old API
          TextureRegistry.SurfaceTextureEntry surfaceTextureEntry = textureRegistry.createSurfaceTexture();
          flutterGLTexture = new FlutterGLTexture(surfaceTextureEntry, openGLManager, width, height);
          Log.i(TAG, "Created texture using SurfaceTextureEntry API (legacy)");
        }
      }
      catch (Exception ex) {
        result.error(ex.getMessage() + " : " + ex.toString(), null, null);
        return;
      }
      
      textureMap.put(flutterGLTexture.getTextureId(), flutterGLTexture);
      
      Map<String, Object> response = new HashMap<>();
      response.put("textureId", flutterGLTexture.getTextureId());
      response.put("surface", flutterGLTexture.surface.getNativeHandle());
      result.success(response);

      Log.i(TAG, "Created a new texture " + width + "x" + height);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
