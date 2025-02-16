cmake_minimum_required(VERSION 3.31.4)

project(angle_android_graphic_jni)

# Find required Android libraries (we only need these)
find_library(log-lib log)
find_library(android-lib android)

# Set C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set the path to ANGLE libraries relative to the CMakeLists.txt location
set(ANGLE_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI})

# Add your source files
add_library(angle_android_graphic_jni
        SHARED
        angle_android_graphic_jni.cpp)

# Include directories
target_include_directories(angle_android_graphic_jni PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${ANDROID_NDK}/sources/android/native_app_glue)

# Add ANGLE libraries directory to linker search path
link_directories(${ANGLE_LIB_DIR})

# Link against the required libraries
target_link_libraries(angle_android_graphic_jni
        ${log-lib}
        ${android-lib}
        # Only ANGLE libraries, no native EGL/GLES
        ${ANGLE_LIB_DIR}/libEGL_angle.so
        ${ANGLE_LIB_DIR}/libGLESv2_angle.so)

# Set library output directory to match your jniLibs structure
set_target_properties(angle_android_graphic_jni PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}")