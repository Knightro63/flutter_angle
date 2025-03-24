#!/bin/zsh

cd `dirname $0`

echo "Cleaning up"
rm -rf **/Universal

build_xcframwork()
{
  echo "Building XCFramework for $1"
  mkdir -p Mac/Universal
  cp -a Mac/x64/$1.framework Mac/Universal
  cp -a Mac/x64/$1.dSYM Mac/Universal
  lipo -create Mac/arm64/$1.framework/$1 Mac/x64/$1.framework/$1 -o temp
  lipo -create Mac/arm64/$1.dSYM/Contents/Resources/DWARF/$1 Mac/x64/$1.dSYM/Contents/Resources/DWARF/$1 -o temp.dSYM
  mv temp Mac/Universal/$1.framework/Versions/A/$1
  mv temp.dSYM Mac/Universal/$1.dSYM/Contents/Resources/DWARF/$1

  mkdir -p Catalyst/Universal
  cp -a Catalyst/x64/$1.framework Catalyst/Universal
  cp -a Catalyst/x64/$1.dSYM Catalyst/Universal
  lipo -create Catalyst/arm64/$1.framework/$1 Catalyst/x64/$1.framework/$1 -o temp
  lipo -create Catalyst/arm64/$1.dSYM/Contents/Resources/DWARF/$1 Catalyst/x64/$1.dSYM/Contents/Resources/DWARF/$1 -o temp.dSYM
  mv temp Catalyst/Universal/$1.framework/Versions/A/$1
  mv temp.dSYM Catalyst/Universal/$1.dSYM/Contents/Resources/DWARF/$1

  mkdir -p Simulator/Universal
  cp -a Simulator/x64/$1.framework Simulator/Universal
  cp -a Simulator/x64/$1.dSYM Simulator/Universal
  lipo -create Simulator/arm64/$1.framework/$1 Simulator/x64/$1.framework/$1 -o temp
  lipo -create Simulator/arm64/$1.dSYM/Contents/Resources/DWARF/$1 Simulator/x64/$1.dSYM/Contents/Resources/DWARF/$1 -o temp.dSYM
  mv temp Simulator/Universal/$1.framework/$1
  mv temp.dSYM Simulator/Universal/$1.dSYM/Contents/Resources/DWARF/$1

  mkdir -p VisionOSSimulator/Universal
  cp -a VisionOSSimulator/x64/$1.framework VisionOSSimulator/Universal
  cp -a VisionOSSimulator/x64/$1.dSYM VisionOSSimulator/Universal
  lipo -create VisionOSSimulator/arm64/$1.framework/$1 VisionOSSimulator/x64/$1.framework/$1 -o temp
  lipo -create VisionOSSimulator/arm64/$1.dSYM/Contents/Resources/DWARF/$1 VisionOSSimulator/x64/$1.dSYM/Contents/Resources/DWARF/$1 -o temp.dSYM
  mv temp VisionOSSimulator/Universal/$1.framework/$1
  mv temp.dSYM VisionOSSimulator/Universal/$1.dSYM/Contents/Resources/DWARF/$1

  if [ "$1" = "libEGL" ]; then
    cp PrivacyInfo.xcprivacy iOS/arm64/$1.framework
    cp PrivacyInfo.xcprivacy VisionOS/arm64/$1.framework
  fi

  xcodebuild -create-xcframework -framework `pwd`/iOS/arm64/$1.framework \
                                 -framework `pwd`/VisionOS/arm64/$1.framework \
                                 -framework `pwd`/VisionOSSimulator/Universal/$1.framework \
                                 -framework `pwd`/Catalyst/Universal/$1.framework \
                                 -framework `pwd`/Simulator/Universal/$1.framework \
                                 -framework `pwd`/Mac/Universal/$1.framework \
                                 -output $1.xcframework
}

build_xcframwork "libEGL"
build_xcframwork "libGLESv2"