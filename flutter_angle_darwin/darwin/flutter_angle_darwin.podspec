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
  s.source_files = 'flutter_angle_darwin/Sources/flutter_angle_darwin/**/*.{h,m,swift,inc,plist}'
  s.public_header_files = 'flutter_angle_darwin/Sources/flutter_angle_darwin/**/*.{h,inc}'
  s.swift_version = '5.0'
  s.library = 'c++'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES'} 

  s.vendored_frameworks = 'flutter_angle_darwin/Frameworks/libEGL.xcframework', 'flutter_angle_darwin/Frameworks/libGLESv2.xcframework'
  s.preserve_paths = 'flutter_angle_darwin/Frameworks/libEGL.xcframework', 'flutter_angle_darwin/Frameworks/libGLESv2.xcframework'

  s.osx.dependency 'FlutterMacOS'
  s.osx.deployment_target = '10.14'

  s.ios.dependency 'Flutter'
  s.ios.deployment_target = '12.0'
end
