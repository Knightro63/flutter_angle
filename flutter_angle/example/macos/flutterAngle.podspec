Pod::Spec.new do |s|
    s.name             = 'flutterAngle'
    s.version          = '0.0.1'
    s.summary          = 'A macOS Flutter plugin for retrieving system information'
    s.description      = 'A simple macOS Flutter plugin to retrieve system information such as OS version, hostname, and CPU architecture.'
    s.homepage         = 'https://github.com/yourusername/systeminfo'
    s.license          = { :type => 'MIT' }
    s.author           = { 'Your Name' => 'your.email@example.com' }
    s.source           = { :path => '.' }
    s.source_files     = 'Classes/**/*'
    s.dependency 'FlutterMacOS'
    s.platform = :osx, '10.14'
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    s.swift_version = '5.0'
    s.module_name = 'FlutterAnglePlugin'
  end