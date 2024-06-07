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
  s.osx.dependency 'FlutterMacOS'
  s.ios.dependency 'Flutter'
  s.osx.deployment_target = '10.14'
  s.ios.deployment_target = '11.0'
  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES'}  
  s.swift_version = '5.0'
  
  s.preserve_paths = 'frameworks/libEGL.xcframework', 'frameworks/libGLESv2.xcframework'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework libEGL', 'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/libEGL.xcframework/Headers"'}
  s.vendored_frameworks = 'frameworks/libEGL.xcframework', 'frameworks/libGLESv2.xcframework'
  s.library = 'c++'
end
