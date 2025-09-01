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
  s.library = 'c++'

  s.osx.dependency 'FlutterMacOS'
  s.osx.deployment_target = '10.13'
  s.osx.preserve_paths = 'osxFramework/MetalANGLE.framework'
  s.osx.xcconfig = { 'OTHER_LDFLAGS' => '-framework MetalANGLE', 'HEADER_SEARCH_PATHS' => '${PODS_TARGET_SRCROOT}/osxFramework/MetalANGLE.framework/Headers'}
  s.osx.vendored_frameworks = 'osxFramework/MetalANGLE.framework'

  s.ios.dependency 'Flutter'
  s.ios.deployment_target = '11.0'
  s.ios.preserve_paths = 'iosFramework/MetalANGLE.framework'
  s.ios.xcconfig = { 'OTHER_LDFLAGS' => '-framework MetalANGLE', 'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/iosFramework/MetalANGLE.framework/Headers"'}
  s.ios.vendored_frameworks = 'iosFramework/MetalANGLE.framework'

  s.library = 'c++'
end
