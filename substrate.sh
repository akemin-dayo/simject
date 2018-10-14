#!/bin/sh

if [ "$EUID" -ne 0 ];then
    echo "This script must be run as root"
    exit 1
fi

if [[ -z $1 ]];then
	echo "Runtime version is required"
    echo "Example: ./substrate.sh 12.0"
	exit 1
fi

SJ_RUNTIME_ROOT=/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ ${1}.simruntime/Contents/Resources/RuntimeRoot
# In-Xcode directory: /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot

if [[ ! -d "${SJ_RUNTIME_ROOT}" ]];then
	echo "Error: iOS $1 runtime is not found in /Library/Developer/CoreSimulator/Profiles/Runtimes"
	exit 1
fi

mkdir -p "${SJ_RUNTIME_ROOT}/Library/Frameworks"

git clone https://github.com/PoomSmart/substitute.git
cd substitute/
./configure --xcode-sdk=iphonesimulator --xcode-archs=x86_64 && make
mv out/libsubstitute.dylib out/CydiaSubstrate
codesign -f -s - out/CydiaSubstrate
mkdir -p ../CydiaSubstrate.framework
mv out/CydiaSubstrate ../CydiaSubstrate.framework/CydiaSubstrate
cd .. && rm -rf substitute

rm -rf "${SJ_RUNTIME_ROOT}/Library/Frameworks/CydiaSubstrate.framework"
mv CydiaSubstrate.framework "${SJ_RUNTIME_ROOT}/Library/Frameworks/CydiaSubstrate.framework"

if [ $? -eq 0 ];then
	echo "Done copying"
else
	echo "Error copying"
fi