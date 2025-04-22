require 'yaml'

pubspec = YAML.load_file(File.join('..', 'pubspec.yaml'))
library_version = pubspec['version'].gsub('+', '-')

Pod::Spec.new do |s|
  s.name             = pubspec['name']
  s.version          = library_version
  s.summary          = pubspec['description']
  s.description      = pubspec['description']
  s.homepage         = pubspec['homepage']
  s.license          = { :file => '../LICENSE' }
  s.authors          = 'Multiple Authors'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,swift,inc,plist}'
  s.public_header_files = 'Classes/**/*.{h,inc}'
  s.swift_version = '5.0'
  s.library = 'c++'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES'} 

  s.vendored_frameworks = [
    '../../flutter_angle_darwin/darwin/libEGL.xcframework',
    '../../flutter_angle_darwin/darwin/libGLESv2.xcframework'
  ]

  s.dependency 'FlutterAngle', '~> 0.0.1'
  
  s.osx.dependency 'FlutterMacOS'
  s.osx.deployment_target = '10.14'

  s.ios.dependency 'Flutter'
  s.ios.deployment_target = '12.0'
end