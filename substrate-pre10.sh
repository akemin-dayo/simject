#!/bin/sh

if [ "$EUID" -ne 0 ];then
	echo "This script must be run as root"
	exit 1
fi

if [[ -z $1 ]];then
	echo "Runtime version is required"
	echo "Example: ./substrate-pre10.sh 8.4"
	exit 1
fi

SJ_RUNTIME_ROOT=/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ ${1}.simruntime/Contents/Resources/RuntimeRoot
# In-Xcode directory: /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot

if [[ ! -d "${SJ_RUNTIME_ROOT}" ]];then
	echo "Error: iOS $1 runtime is not found in /Library/Developer/CoreSimulator/Profiles/Runtimes"
	exit 1
fi

mkdir -p "${SJ_RUNTIME_ROOT}/Library/Frameworks"

curl -Lo /tmp/simject_cycript.zip https://cache.saurik.com/cycript/mac/cycript_0.9.594.zip
unzip /tmp/simject_cycript.zip -d /tmp/simject_cycript
mkdir -p CydiaSubstrate.framework
mv /tmp/simject_cycript/Cycript.lib/libsubstrate.dylib CydiaSubstrate.framework/CydiaSubstrate
rm -rf /tmp/simject_cycript /tmp/simject_cycript.zip

rm -rf "${SJ_RUNTIME_ROOT}/Library/Frameworks/CydiaSubstrate.framework"
mv CydiaSubstrate.framework "${SJ_RUNTIME_ROOT}/Library/Frameworks/CydiaSubstrate.framework"

if [ $? -eq 0 ];then
	echo "Done copying"
else
	echo "Error copying"
fi