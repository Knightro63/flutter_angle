library flutter_angle_web;

export 'angle.dart';
export 'wrapper.dart'
  if(dart.library.js_interop) 'wrapper_wasm.dart';
export 'gles_bindings.dart';