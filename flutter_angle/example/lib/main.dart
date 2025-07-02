import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'learn_gl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin, WidgetsBindingObserver{
  FlutterAngle angle = FlutterAngle();
  final textures = <FlutterAngleTexture>[];

  int textureId = -1;
  int textureId2 = -1;

  Lesson? lesson;
  Lesson? lesson2;

  static const textureWidth = 640;
  static const textureHeight = 320;
  static const aspect = textureWidth / textureHeight;

  double dpr = 1.0;
  late double width;
  late double height;
  Size? screenSize;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose(){
    super.dispose();
    _debounceTimer?.cancel(); // Cancel timer if active
    WidgetsBinding.instance.removeObserver(this);

    angle.dispose(textures);
    ticker.dispose();
    lesson?.dispose();
    lesson2?.dispose();
  }

  @override
  void didChangeMetrics() {
    _debounceTimer?.cancel(); // Clear existing timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () { // Set a new timer
      onWindowResize(context);
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    didInit = true;
    final mq = MediaQuery.of(context);
    screenSize = mq.size;
    dpr = mq.devicePixelRatio;

    width = screenSize!.width;
    height = width;

    await angle.init();

    final options = AngleOptions(
      width: textureWidth,
      height: textureHeight,
      dpr: dpr,
      useSurfaceProducer: true
    );

    try {
      textures.add(await angle.createTexture(options));
      textures.add(await angle.createTexture(options));
    } on PlatformException catch (e) {
      print("failed to get texture id $e");
      return;
    }

    //resetLessons();
    lesson = Lesson3(textures[0].getContext());
    lesson2 = Lesson5(textures[1].getContext());

    /// Updating all Textues takes a slighllty less than 150ms
    /// so we can't get much faster than this at the moment because it could happen that
    /// the timer starts a new async function while the last one hasn't finished
    /// which creates an OpenGL Exception
    if (!mounted) return;
    setState(() {
      textureId = textures[0].textureId;
      textureId2 = textures[1].textureId;
    });
    // timer = Timer.periodic(const Duration(milliseconds: 16), updateTexture);
    ticker = createTicker(updateTexture);
    ticker.start();
  }

  Stopwatch stopwatch = Stopwatch();

  late Ticker ticker;
  static bool updating = false;
  int animationCounter = 0;
  int totalTime = 0;
  int iterationCount = 60;
  int framesOver = 0;
  bool didInit = false;
  void updateTexture(_) async {
    if (textureId < 0) return;
    if (!updating) {
      updating = true;
      stopwatch.reset();
      stopwatch.start();
      textures[0].activate();
      lesson?.handleKeys();
      lesson?.animate(animationCounter += 2);
      lesson?.drawScene(-1, 0, aspect);
      await textures[0].signalNewFrameAvailable();
      stopwatch.stop();
      totalTime += stopwatch.elapsedMilliseconds;
      if (stopwatch.elapsedMilliseconds > 16) {
        framesOver++;
      }
      if (--iterationCount == 0) {
        // print('Time: ${totalTime / 60} - Framesover $framesOver');
        totalTime = 0;
        iterationCount = 60;
        framesOver = 0;
      }
      textures[1].activate();
      lesson2?.handleKeys();
      lesson2?.animate(animationCounter += 2);
      lesson2?.drawScene(-1, 0, aspect);
      await textures[1].signalNewFrameAvailable();
      updating = false;
    } else {
      print('Too slow');
    }
  }

  Widget texture(bool useRow){
    return useRow? Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Transform.scale(
            scaleY: kIsWeb || Platform.isAndroid? -1: 1,
            child: kIsWeb?textureId == -1?Container():HtmlElementView(viewType: textureId.toString()):Texture(textureId: textureId),
          )
        ),
        Expanded(
          child: Transform.scale(
            scaleY: kIsWeb || Platform.isAndroid? -1: 1,
            child: kIsWeb?textureId2 == -1?Container():HtmlElementView(viewType: textureId2.toString()):Texture(textureId: textureId2),
          )
        ),
      ],
    ):Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Transform.scale(
            scaleY: kIsWeb || Platform.isAndroid? -1: 1,
            child: kIsWeb?textureId == -1?Container():HtmlElementView(viewType: textureId.toString()):Texture(textureId: textureId),
          )
        ),
        Expanded(
          child: Transform.scale(
            scaleY: kIsWeb || Platform.isAndroid? -1: 1,
            child: kIsWeb?textureId2 == -1?Container():HtmlElementView(viewType: textureId2.toString()):Texture(textureId: textureId2),
          )
        ),
      ],
    );
  }

  Future<void> onWindowResize(BuildContext context) async{
    final mqd = MediaQuery.of(context);
    if(screenSize != mqd.size){
      screenSize = mqd.size;
      width = screenSize!.width;
      height = screenSize!.height;
      dpr = mqd.devicePixelRatio;

      final options = AngleOptions(
        width: width.toInt(),
        height: height.toInt(),
        dpr: dpr,
      );
      //await angle.resize(textures[0], options);
      await angle.resize(textures[1], options);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final useRow = constraints.maxWidth > constraints.maxHeight;
          if (!didInit) {
            initPlatformState();
          }
          return SizeChangedLayoutNotifier(
            child: Builder(builder: (BuildContext context) {
              return Container(
                color: Colors.red,
                child: texture(useRow)
              );
            })
          );
        }),
      ),
    );
  }
}