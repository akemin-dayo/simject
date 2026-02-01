#!/usr/bin/env bash

set -e

if [[ -z $1 ]]
then
    echo -e "Error: Substrate type must be specified\n"
    echo -e "If you target iOS 12+ (of Xcode 10+), you must run the following:\n"
    echo -e "\t./installsubstrate.sh subst\n"
    echo -e "This will install Substitute\n"
    echo -e "Otherwise, you can run:\n"
    echo -e "\t./installsubstrate.sh cs\n"
    echo -e "This will install cycript's CydiaSubstrate\n"
    echo -e "If you only want to symlink CydiaSubstrate.framework to new iOS runtimes, you can run:\n"
    echo -e "\t./installsubstrate.sh link\n"
    echo -e "If you are developing simulator tweaks that utilize MSHookFunction, you can install the simulator-supported version of CydiaSubstrate.tbd (tbd v4) by running:\n"
    echo -e "\t./installsubstrate.sh theos\n"
    exit 1
fi

echo "You may be asked for the login password for sudo operations"

SELF_DIR=$PWD

SJ_RUNTIME_ROOT_PREFIX=/Library/Developer/CoreSimulator/Profiles/Runtimes
SJ_RUNTIME_ROOT_10=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot
SJ_RUNTIME_ROOT_10_BETA=/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot
SJ_RUNTIME_ROOT_11=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot
SJ_RUNTIME_ROOT_11_BETA=/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot

SJ_PATH=/opt/simject
SJ_FW_PATH=${SJ_PATH}/Frameworks
mkdir -p ${SJ_FW_PATH}

if [[ $1 = "theos" ]]
then
    CS_FW_PATH="$THEOS/vendor/lib/CydiaSubstrate.framework"
    if [[ ! -d $CS_FW_PATH ]]
    then
        echo "Error: CydiaSubstrate.framework not found in ${CS_FW_PATH}"
        exit 1
    fi
    if [[ -f ${CS_FW_PATH}/CydiaSubstrate.tbd.bak ]]
    then
        echo "Notice: CydiaSubstrate.tbd has already been backed up, skipping"
        exit 0
    fi
    echo "Backing up CydiaSubstrate.tbd..."
    mv $CS_FW_PATH/CydiaSubstrate.tbd $CS_FW_PATH/CydiaSubstrate.tbd.bak
    echo "Copying the new CydiaSubstrate.tbd to $CS_FW_PATH..."
    cp $SELF_DIR/CydiaSubstrate.tbd $CS_FW_PATH/
    exit 0
elif [[ $1 = "link" ]]
then
    cd ${SJ_FW_PATH}
    if [[ ! -d CydiaSubstrate.framework ]]
    then
        echo "Error: CydiaSubstrate.framework not found in ${SJ_FW_PATH}"
        exit 1
    fi
elif [[ $1 = "subst" ]]
then
    cd ${SJ_FW_PATH}
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
    cd ${SJ_FW_PATH}
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

echo "Symlinking CydiaSubstrate.framework for all installed iOS runtimes..."

if [[ -d "${SJ_RUNTIME_ROOT_10}" ]]
then
    echo "Symlinking to ${SJ_RUNTIME_ROOT_10}"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_10}/Library/Frameworks"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_10}/Library/MobileSubstrate"
    sudo rm -rf "${SJ_RUNTIME_ROOT_10}/Library/Frameworks/CydiaSubstrate.framework"
    sudo ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_RUNTIME_ROOT_10}/Library/Frameworks/"
    sudo rm -rf "${SJ_RUNTIME_ROOT_10}/Library/MobileSubstrate/DynamicLibraries"
    sudo ln -s ${SJ_PATH} "${SJ_RUNTIME_ROOT_10}/Library/MobileSubstrate/DynamicLibraries"
fi

if [[ -d "${SJ_RUNTIME_ROOT_10_BETA}" ]]
then
    echo "Symlinking to ${SJ_RUNTIME_ROOT_10_BETA}"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_10_BETA}/Library/Frameworks"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_10_BETA}/Library/MobileSubstrate"
    sudo rm -rf "${SJ_RUNTIME_ROOT_10_BETA}/Library/Frameworks/CydiaSubstrate.framework"
    sudo ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_RUNTIME_ROOT_10_BETA}/Library/Frameworks"
    sudo rm -rf "${SJ_RUNTIME_ROOT_10_BETA}/Library/MobileSubstrate/DynamicLibraries"
    sudo ln -s ${SJ_PATH} "${SJ_RUNTIME_ROOT_10_BETA}/Library/MobileSubstrate/DynamicLibraries"
fi

if [[ -d "${SJ_RUNTIME_ROOT_11}" ]]
then
    echo "Symlinking to ${SJ_RUNTIME_ROOT_11}"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_11}/Library/Frameworks"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_11}/Library/MobileSubstrate"
    sudo rm -rf "${SJ_RUNTIME_ROOT_11}/Library/Frameworks/CydiaSubstrate.framework"
    sudo ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_RUNTIME_ROOT_11}/Library/Frameworks"
    sudo rm -rf "${SJ_RUNTIME_ROOT_11}/Library/MobileSubstrate/DynamicLibraries"
    sudo ln -s ${SJ_PATH} "${SJ_RUNTIME_ROOT_11}/Library/MobileSubstrate/DynamicLibraries"
fi

if [[ -d "${SJ_RUNTIME_ROOT_11_BETA}" ]]
then
    echo "Symlinking to ${SJ_RUNTIME_ROOT_11_BETA}"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_11_BETA}/Library/Frameworks"
    sudo mkdir -p "${SJ_RUNTIME_ROOT_11_BETA}/Library/MobileSubstrate"
    sudo rm -rf "${SJ_RUNTIME_ROOT_11_BETA}/Library/Frameworks/CydiaSubstrate.framework"
    sudo ln -s ${SJ_FW_PATH}/CydiaSubstrate.framework "${SJ_RUNTIME_ROOT_11_BETA}/Library/Frameworks"
    sudo rm -rf "${SJ_RUNTIME_ROOT_11_BETA}/Library/MobileSubstrate/DynamicLibraries"
    sudo ln -s ${SJ_PATH} "${SJ_RUNTIME_ROOT_11_BETA}/Library/MobileSubstrate/DynamicLibraries"
fi

if [[ -d "${SJ_RUNTIME_ROOT_PREFIX}" ]]
then
    OIFS="$IFS"
    IFS=$'\n'
    for SJ_runtime in $(find ${SJ_RUNTIME_ROOT_PREFIX} -type d -maxdepth 1 -name "*.simruntime")
    do
        echo "Symlinking to ${SJ_runtime}"
        sudo mkdir -p "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/Frameworks"
        sudo mkdir -p "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/MobileSubstrate"
        sudo rm -rf "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/Frameworks/CydiaSubstrate.framework"
        sudo ln -s "${SJ_FW_PATH}/CydiaSubstrate.framework" "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/Frameworks"
        sudo rm -rf "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/MobileSubstrate/DynamicLibraries"
        sudo ln -s ${SJ_PATH} "${SJ_runtime}/Contents/Resources/RuntimeRoot/Library/MobileSubstrate/DynamicLibraries"
    done
    IFS="$OIFS"
fi

SJ_VOLUMES=/Library/Developer/CoreSimulator/Volumes
if [ -d "${SJ_VOLUMES}" ]
then
    OIFS="$IFS"
    IFS=$'\n'
    for SJ_volume in $(find ${SJ_VOLUMES} -type d -maxdepth 1 -name "iOS_*")
    do
        RUNTIME_ROOT=${SJ_volume}${SJ_RUNTIME_ROOT_PREFIX}/*.simruntime/Contents/Resources/RuntimeRoot
        echo "Remounting ${RUNTIME_ROOT}/Library as read-write..."
        sh $SELF_DIR/remount.sh ${RUNTIME_ROOT}/Library || echo "Continue or Could not remount ${RUNTIME_ROOT}/Library"
        cd ${RUNTIME_ROOT}/Library
        LIBRARY_PATH=$(pwd)
        FRAMEWORK_PATH=${LIBRARY_PATH}/Frameworks
        echo "Symlink to ${SJ_volume}"
        rm -rf "$FRAMEWORK_PATH/CydiaSubstrate.framework"
        ln -s "${SJ_FW_PATH}/CydiaSubstrate.framework" "$FRAMEWORK_PATH/"
        mkdir -p "$LIBRARY_PATH/MobileSubstrate"
        rm -rf "$LIBRARY_PATH/MobileSubstrate/DynamicLibraries"
        ln -s "${SJ_PATH}" "$LIBRARY_PATH/MobileSubstrate/DynamicLibraries"
        sh $SELF_DIR/remount.sh ${RUNTIME_ROOT}/usr/lib || echo "Continue or Could not remount ${RUNTIME_ROOT}/usr/lib"
    done
    IFS="$OIFS"
fi
