# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.15)

# Project-level configuration.
set(PROJECT_NAME "flutter_angle_linux")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "flutter_angle_linux_plugin")

list(APPEND PLUGIN_SOURCES
  "flutter_angle_linux_plugin.cc"
)

add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
  flutter_texture_gl.cc
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_compile_options(${PLUGIN_NAME} PRIVATE -Wall -Wno-error -v -v)

target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_directories(
  ${PLUGIN_NAME} PUBLIC 
  ${OPENGL_LIB_DIR} 
)

target_link_libraries(
  ${PLUGIN_NAME} PRIVATE 
  flutter
  # EGL
  # GLEW
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libEGL.so" 
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libGLESv2.so"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(flutter_angle_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libEGL.so" 
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libGLESv2.so"
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libc++.so"
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libthird_party_abseil-cpp_absl.so"
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libchrome_zlib.so"
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libdawn_native.so"
  "${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/libdawn_platform.so"
  PARENT_SCOPE
)