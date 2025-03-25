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
  
  s.osx.vendored_library = 'Assets/macos-arm64_x86_64/libEGL.dylib','Assets/macos-arm64_x86_64/libGLESv2.dylib','Assets/macos-arm64_x86_64/libc++_chrome.dylib','Assets/macos-arm64_x86_64/libchrome_zlib.dylib','Assets/macos-arm64_x86_64/libdawn_native.dylib','Assets/macos-arm64_x86_64/libdawn_proc.dylib','Assets/macos-arm64_x86_64/libdawn_platform.dylib','Assets/macos-arm64_x86_64/libthird_party_abseil-cpp_absl.dylib'
  s.osx.dependency 'FlutterMacOS'
  s.osx.deployment_target = '10.15'

  s.ios.dependency 'Flutter'
  s.ios.deployment_target = '12.0'
end