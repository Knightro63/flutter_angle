#!/bin/zsh

cd `dirname $0`

check_success()
{
  if [ $? -eq 0 ]; then
    echo "Succeeded"
  else
    echo "Failed"
    exit
  fi
}

echo "Fecthing depot tools"
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
check_success

export PATH=`pwd`/depot_tools:$PATH

mkdir angle
cd angle

echo "Fetching source code"
fetch angle
check_success

echo "Apply Apple ANGLE patch"
git apply ../angle.apple.patch --ignore-whitespace --whitespace=nowarn -3
check_success

 echo "Apply Flip-y ANGLE patch"
 git apply ../flip_y.patch --ignore-whitespace --whitespace=nowarn -3
 check_success

echo "Apply Variable Rasterization Rate Map ANGLE patch"
git apply ../variable_rasterization_rate_map.patch --ignore-whitespace --whitespace=nowarn -3
check_success

cd build
echo "Apply Apple chromium build patch"
git apply ../../chromium.build.apple.patch --ignore-whitespace --whitespace=nowarn -3
check_success

cd ..

build_angle()
{
  echo "Building for $1 $2"
  mkdir -p out/$1/$2/
  check_success

  cp ../$1.$2.args.gn out/$1/$2/args.gn
  check_success

  gn gen out/$1/$2/
  check_success

  autoninja -j4 -C out/$1/$2/
  check_success

  if [ "$1" = "Mac" ]; then
    cp ../bundle_in_framework.sh out/$1/$2/
    check_success
    out/$1/$2/bundle_in_framework.sh
    check_success
    MIN_MAC_VERSION=10.15
    ../generate_info_plist.sh `pwd`/../Info.plist `pwd`/out/$1/$2/libEGL.framework/Versions/A/Resources/Info.plist org.chromium.ost.libEGL libEGL $MIN_MAC_VERSION
    ../generate_info_plist.sh `pwd`/../Info.plist `pwd`/out/$1/$2/libGLESv2.framework/Versions/A/Resources/Info.plist org.chromium.ost.libGLESv2 libGLESv2 $MIN_MAC_VERSION

    plutil -insert CFBundleShortVersionString -string 1.0 `pwd`/out/$1/$2/libGLESv2.framework/Versions/A/Resources/Info.plist
    plutil -insert CFBundleShortVersionString -string 1.0 `pwd`/out/$1/$2/libEGL.framework/Versions/A/Resources/Info.plist
  elif [ "$1" = "Catalyst" ]; then
    plutil -insert CFBundleShortVersionString -string 1.0 `pwd`/out/$1/$2/libGLESv2.framework/Versions/A/Resources/Info.plist
    plutil -insert CFBundleShortVersionString -string 1.0 `pwd`/out/$1/$2/libEGL.framework/Versions/A/Resources/Info.plist
  else
    plutil -insert CFBundleShortVersionString -string 1.0 `pwd`/out/$1/$2/libGLESv2.framework/Info.plist
    plutil -insert CFBundleShortVersionString -string 1.0 `pwd`/out/$1/$2/libEGL.framework/Info.plist
  fi
}

complete_framework()
{
  ../create_egl_headers.sh . ../resources/libEGL/Headers
  ../create_glesv2_headers.sh . ../resources/libGLESv2/Headers
  for FRAMEWORK in 'libEGL' 'libGLESv2';
  do
    if [ "$1" = "Mac" ] || [ "$1" = "Catalyst" ]; then
      cp -r ../resources/$FRAMEWORK/Headers out/$1/$2/$FRAMEWORK.framework/Versions/A
      cp -r ../resources/$FRAMEWORK/Modules out/$1/$2/$FRAMEWORK.framework/Versions/A
      cd out/$1/$2/$FRAMEWORK.framework
      ln -s Versions/Current/Headers Headers
      ln -s Versions/Current/Modules Modules
      cd ../../../..
    else
      cp -r ../resources/$FRAMEWORK/Headers out/$1/$2/$FRAMEWORK.framework
      cp -r ../resources/$FRAMEWORK/Modules out/$1/$2/$FRAMEWORK.framework
    fi
  done
}

build_angle $1 $2
complete_framework $1 $2
check_success

rm -rf out/$1/$2/obj
tar -czvf angle.tar.gz out/