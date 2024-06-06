class AngleOptions{
  AngleOptions({
    required this.width,
    required this.height,
    required this.dpr,
    this.alpha = false,
    this.antialias = false,
    this.customRenderer = true,
    this.forceOpenGL = false
  });

  int width;
  int height;
  double dpr;
  bool antialias;
  bool alpha;
  bool customRenderer;
  bool forceOpenGL;
}