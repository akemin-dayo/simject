#!/usr/bin/env bash

set -e

if [[ -z $1 ]]
then
    echo "Error: Substrate type must be specified\n"
    echo "If you target iOS 12+ (of Xcode 10+), you must run the following:\n"
    echo "\t./installsubstrate.sh subst\n"
    echo "This will install Substitute\n"
    echo "Otherwise, you can run:\n"
    echo "\t./installsubstrate.sh cs\n"
    echo "This will install cycript's CydiaSubstrate\n"
    echo "If you only want to symlink CydiaSubstrate.framework to new iOS runtimes, you can run:\n"
    echo "\t./installsubstrate.sh link\n"
    exit 1
fi

CURRENT_DIR=$PWD

SJ_RUNTIME_ROOT_PREFIX=/Library/Developer/CoreSimulator/Profiles/Runtimes
SJ_RUNTIME_ROOT_10=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot
SJ_RUNTIME_ROOT_10_BETA=/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot
SJ_RUNTIME_ROOT_11=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot
SJ_RUNTIME_ROOT_11_BETA=/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot

SJ_FW_PATH=/opt/simject/Frameworks
mkdir -p ${SJ_FW_PATH}
cd ${SJ_FW_PATH}

if [[ $1 = "link" ]]
then
    if [[ ! -d CydiaSubstrate.framework ]]
    then
        echo "Error: CydiaSubstrate.framework not found in ${SJ_FW_PATH}"
        exit 1
    fi
elif [[ $1 = "subst" ]]
then
    echo "Installing Substitute..."
    rm -rf substitute CydiaSubstrate.framework
    git clone https://github.com/PoomSmart/substitute.git
    cd substitute/
    ./configure --xcode-sdk=iphonesimulator --xcode-archs=$(uname -m) && make
    mv out/libsubstitute.dylib out/CydiaSubstrate
    codesign -f -s - out/CydiaSubstrate
    mkdir -p ../CydiaSubstrate.framework
    mv out/CydiaSubstrate ../CydiaSubstrate.framework/CydiaSubstrate
    cd .. && rm -rf substitute
elif [[ $1 = "cs" ]]
then
    echo "Installing CydiaSubstrate..."
    rm -rf CydiaSubstrate.framework
    curl -Lo /tmp/simject_cycript.zip https://cache.saurik.com/cycript/mac/cycript_0.9.594.zip
    unzip /tmp/simject_cycript.zip -d /tmp/simject_cycript
    mkdir -p CydiaSubstrate.framework
    mv /tmp/simject_cycript/Cycript.lib/libsubstrate.dylib CydiaSubstrate.framework/CydiaSubstrate
    rm -rf /tmp/simject_cycript /tmp/simject_cycript.zip
else
    echo "Error: Unrecognized substrate type (${1}), exiting"
    exit 1
fi

echo "Symlink CydiaSubstrate.framework for all installed iOS runtimes..."

if [[ -d "${SJ_RUNTIME_ROOT_10}" ]]
then
    echo "Symlink to ${SJ_RUNTIME_ROOT_10}"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_10}/Library/Frameworks"
    sudo rm -rf "${SJ_RUNTIME_ROOT_10}/Library/Frameworks/CydiaSubstrate.framework"
    sudo ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_RUNTIME_ROOT_10}/Library/Frameworks/"
fi

if [[ -d "${SJ_RUNTIME_ROOT_10_BETA}" ]]
then
    echo "Symlink to ${SJ_RUNTIME_ROOT_10_BETA}"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_10_BETA}/Library/Frameworks"
    sudo rm -rf "${SJ_RUNTIME_ROOT_10_BETA}/Library/Frameworks/CydiaSubstrate.framework"
    sudo ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_RUNTIME_ROOT_10_BETA}/Library/Frameworks/"
fi

if [[ -d "${SJ_RUNTIME_ROOT_11}" ]]
then
    echo "Symlink to ${SJ_RUNTIME_ROOT_11}"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_11}/Library/Frameworks"
    sudo rm -rf "${SJ_RUNTIME_ROOT_11}/Library/Frameworks/CydiaSubstrate.framework"
    sudo ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_RUNTIME_ROOT_11}/Library/Frameworks/"
fi

if [[ -d "${SJ_RUNTIME_ROOT_11_BETA}" ]]
then
    echo "Symlink to ${SJ_RUNTIME_ROOT_11_BETA}"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_11_BETA}/Library/Frameworks"
    sudo rm -rf "${SJ_RUNTIME_ROOT_11_BETA}/Library/Frameworks/CydiaSubstrate.framework"
    sudo ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_RUNTIME_ROOT_11_BETA}/Library/Frameworks/"
fi

if [[ -d "${SJ_RUNTIME_ROOT_PREFIX}" ]]
then
    OIFS="$IFS"
    IFS=$'\n'
    for SJ_runtime in $(find ${SJ_RUNTIME_ROOT_PREFIX} -type d -maxdepth 1 -name "*.simruntime")
    do
        echo "Symlink to ${SJ_runtime}"
        mkdir -p "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/Frameworks"
        rm -rf "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/Frameworks/CydiaSubstrate.framework"
        ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/Frameworks/"
    done
    IFS="$OIFS"
fi

SJ_VOLUMES=/Library/Developer/CoreSimulator/Volumes
OIFS="$IFS"
IFS=$'\n'
for SJ_volume in $(find ${SJ_VOLUMES} -type d -maxdepth 1 -name "iOS_*")
do
    echo "Remounting ${SJ_volume} as read-write..."
    sh $CURRENT_DIR/remount.sh ${SJ_volume}${SJ_RUNTIME_ROOT_PREFIX}/*.simruntime/Contents/Resources/RuntimeRoot/Library/Frameworks || echo 'Continuing...'
    cd ${SJ_volume}${SJ_RUNTIME_ROOT_PREFIX}/*.simruntime/Contents/Resources/RuntimeRoot/Library/Frameworks
    FRAMEWORK_PATH=$(pwd)
    echo "Symlink to ${SJ_volume}"
    rm -rf "$FRAMEWORK_PATH/CydiaSubstrate.framework"
    ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "$FRAMEWORK_PATH/"
done
IFS="$OIFS"
