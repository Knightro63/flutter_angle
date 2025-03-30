Pod::Spec.new do |s|
    s.name             = 'flutterAngle'
    s.version          = '0.0.1'
    s.summary          = 'Flutter plugin for OpenGL ES and ANGLE integration'
    s.description      = 'A Flutter plugin that provides OpenGL ES integration for iOS platforms'
    s.homepage         = 'https://github.com/yourusername/wayzen'
    s.license          = { :type => 'MIT' }
    s.author           = { 'Your Name' => 'your.email@example.com' }
    s.source           = { :path => '.' }
    s.source_files     = 'Classes/**/*'
    s.dependency 'Flutter'
    s.platform = :ios, '16.6'
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    s.swift_version = '5.0'
    s.module_name = 'FlutterAnglePlugin'
  end