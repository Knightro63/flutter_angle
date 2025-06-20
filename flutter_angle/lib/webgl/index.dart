library flutter_angle_web;

export 'angle.dart';
export 'wrapper_wasm.dart'
  if(dart.library.js) 'wrapper.dart';
export 'gles_bindings.dart';