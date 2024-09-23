// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// API docs from [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web).
// Attributions and copyright licensing by Mozilla Contributors is licensed
// under [CC-BY-SA 2.5](https://creativecommons.org/licenses/by-sa/2.5/.

// Generated from Web IDL definitions.

@JS()
library;

import 'dart:js_interop';
import 'package:web/web.dart';

typedef Float32List = JSObject;

extension WebGL2RenderingContextExtrnsion on WebGL2RenderingContext{
  external int glGetUniformBlockIndex(
    GLint id,
    String uniformBlockName,
  );
  external int glUniformBlockBinding(
    GLint id,
    GLint uniformBlockIndex,
    GLint uniformBlockBinding
  );
}
