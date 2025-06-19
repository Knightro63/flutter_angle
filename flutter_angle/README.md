# flutter_angle

[![Pub Version](https://img.shields.io/pub/v/flutter_angle)](https://pub.dev/packages/flutter_angle)
[![analysis](https://github.com/Knightro63/flutter_angle/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63//flutter_angle/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A graphics library for dart (based on [angle](https://github.com/google/angle)) that allows users to view more complex rendering projects like 3D objects and more complex shaders. 

## Features

![Gif of angle working.](https://github.com/Knightro63/flutter_angle/blob/main/assets/example.gif?raw=true)

This is a dart conversion of [flutter_web_gl](https://github.com/FlutterGL/flutter_web_gl/tree/master) originally created by [@escamoteur](https://github.com/escamoteur) and [@kentcb](https://github.com/kentcb).

## Requirements

**MacOS**
 - Minimum os Deployment Target: 10.14
 - Xcode 13 or newer
 - Swift 5
 - Metal supported

**iOS**
 - Minimum os Deployment Target: 12.0
 - Xcode 13 or newer
 - Swift 5
 - Metal supported

**iOS-Simulator**
 - Supported: Use flutter_angle: 0.3.0.

**Android Angle**
 - compileSdkVersion: 34
 - minSdk: 28
 - OpenGL supported
 - Vulkan supported

**Android Opengl**
 - compileSdkVersion: 34
 - minSdk: 21
 - OpenGL supported

**Android Emulator**
 - Supported opengl only.

**Windows**
 - Intel supported.
 - AMD supported.
 - Qualcom supported.
 - Direct3D 11 and OpenGL supported

**Web**
 - WebGL2 supported.

**WASM**
 - WebGL2 supported; please add `<script src="https://cdn.jsdelivr.net/gh/Knightro63/flutter_angle/assets/gles_bindings.js"></script>` to your index.html to load the file.

**Linux**
 - Unsupported

## Getting started

To get started add flutter_angle to your pubspec.yaml file.

## Usage

This project is a simple rendering engine for flutter to view 3D models and complex shaders.

## Example

Find the example for this API [here](https://github.com/Knightro63/flutter_angle/tree/main/example/).

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/flutter_angle/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/flutter_angle/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/flutter_angle/pulls) directly.
