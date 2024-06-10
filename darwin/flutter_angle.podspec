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
  s.source_files = 'Classes/**/*'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES'}  
  s.swift_version = '5.0'

  s.osx.dependency 'FlutterMacOS'
  s.osx.dependency "three3d_egl_osx", '~> 0.1.1'
  s.osx.deployment_target = '10.13'
  s.osx.preserve_paths = 'osx/MetalANGLE.framework', 'osx/three3d_egl.framework'

  s.ios.dependency 'Flutter'
  s.ios.dependency "three3d_egl", '~> 0.1.3'
  s.ios.deployment_target = '11.0'
  s.ios.preserve_paths = 'ios/MetalANGLE.framework', 'ios/three3d_egl.framework'

  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework libEGL', 'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/libEGL.xcframework/Headers"'}
  s.vendored_frameworks = 'frameworks/libEGL.xcframework', 'frameworks/libGLESv2.xcframework'
  s.library = 'c++'
end
