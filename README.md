# simject

simject is a command-line tool and iOS dynamic library that allows iOS tweak developers to easily test their tweaks on the iOS Simulator.

simject is BSD-licensed. See `LICENSE` for more information.

### Setting up the simject environment
1. Ensure that you have added your developer account in Xcode > Preferences > Accounts tab. This is required for code-signing some binaries used in simject.
2. Ensure that there is "iOS Development" certificate listed once you clicked on "Manage Certificates", create one if there is not.
3. Run these commands in a Terminal instance:

```
git clone https://github.com/angelXwind/simject.git
cd simject/
make setup
```

**Note:** During the process, you will be asked by `sudo` to enter your login password. Please note that it is normal for nothing to be displayed as you type your password.

Now, we need to create a version of `CydiaSubstrate.framework` that has support for the `x86_64` (64-bit) and/or `i386` (32-bit) architectures.

### Getting Cydia Substrate to function properly with simject

Unless you want to do it manually, you can use `installsubstrate.sh` script to symlink `CydiaSubstrate.framework` to the appropriate directory **to every iOS runtime**. Otherwise, continue reading.

If you use Xcode 10 (and above) and target iOS 12 (and above), you need to rely on [substitute](https://github.com/coolstar/substitute) rather than cycript's included `CydiaSubstrate.framework`.

This is due to the incompatible `libstdc++` in iOS 12 simulator of Xcode 10. The Cydia Substrate from cycript that requires `libstdc++` will not work, but will complain `/usr/lib/libstdc++.6.dylib: mach-o, but not built for iOS simulator`. You can run the following commands to compile a working substitute framework:

```
# Xcode 10+ and iOS 12+
cd simject/
git clone https://github.com/PoomSmart/substitute.git
cd substitute/
./configure --xcode-sdk=iphonesimulator --xcode-archs=x86_64 && make
mv -v out/libsubstitute.dylib out/CydiaSubstrate
codesign -f -s - out/CydiaSubstrate
mkdir -p ../CydiaSubstrate.framework
mv -v out/CydiaSubstrate ../CydiaSubstrate.framework/CydiaSubstrate
cd .. && rm -rf substitute
```
Otherwise, run these commands to compile a working Cydia Substrate:

```
# Xcode 9 and below
cd simject/
curl -Lo /tmp/simject_cycript.zip https://cache.saurik.com/cycript/mac/cycript_0.9.594.zip
unzip /tmp/simject_cycript.zip -d /tmp/simject_cycript
mkdir -p CydiaSubstrate.framework
mv -v /tmp/simject_cycript/Cycript.lib/libsubstrate.dylib CydiaSubstrate.framework/CydiaSubstrate
rm -rfv /tmp/simject_cycript /tmp/simject_cycript.zip
```

1. Copy the resulting `CydiaSubstrate.framework` bundle to `/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS${SDK_VERSION}.simruntime/Contents/Resources/RuntimeRoot/Library/Frameworks/` where `${SDK_VERSION}` is your desired SDK version. If `/Library/Frameworks` does not exist, you can just create it manually.
   * Note: For runtimes bundled in Xcode 9.0+, instead copy the framework to `/Applications/${XCODE}.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/Library/Frameworks/` where `${XCODE}` is usually either `Xcode` or `Xcode-beta`.
2. Note that, from 1., you can symlink insteading copying `CydiaSubstrate.framework` to multiple places. This is what `installsubstrate.sh` does to ease your life.
3. Finally, select your Xcode directory with `sudo xcode-select -s /Applications/Xcode.app` (or wherever Xcode is located on your system).

### simject usage

1. Place your dynamic libraries and accompanying property lists inside `/opt/simject` to load them in the iOS Simulator. Do not delete `simject.plist` and `simject.dylib`.
   
2. Inside the `bin` subdirectory, you will find the `resim` command-line tool. Execute it to cause booted iOS Simulator(s) to respring and to be able to load tweaks.

3. IMPORTANT: Please note that you will need to run `resim` every time the iOS Simulator reboots or if SpringBoard crashes by itself.

4. `resim` can respring multiple simulators (check its usage notes), provided that the selected Xcode version is 9.0 or above.

5. Happy developing! (And don't make SpringBoard cry *too* hard... it has feelings, too! Probably.)

### Targeting the iOS Simulator

1. Open your project's `Makefile`.
2. Change your `TARGET` variable to `TARGET = simulator:clang::7.0` (a must for Xcode 10, with 64-bit compatibility) or `TARGET = simulator:clang::5.0` otherwise (with 32-bit compatibility). Note that this is just an example, you can change the SDK version used and iOS version to target if you wish.

3. If you want to support both 64-bit and 32-bit iOS Simulators, add `ARCHS = x86_64 i386` to your Makefile. If not (or if you're targeting iOS 11), add `ARCHS = x86_64`.

4. `make` your project and copy `.theos/obj/iphone_simulator/${YOUR_TWEAK}.dylib` to `/opt/simject/${YOUR_TWEAK}.dylib`.

5. If there is already `/opt/simject/${YOUR_TWEAK}.dylib`, you have to delete it first before copying.

6. Also make sure to copy `${YOUR_TWEAK}.plist` to `/opt/simject/${YOUR_TWEAK}.plist`. simject will not load your tweak if you miss this step!

7. An example tweak project is available in the `simjectExampleTweak/` subfolder. Use it as reference if you want. Its Makefile is also written so that you can just run `make setup` to copy over the dylib and its plist automatically.

8. If you encountered a problem while signing dylibs: `error: The specified item could not be found in the keychain.`, you can try to fix it by following [this](https://github.com/angelXwind/simject/issues/43#issuecomment-441659203) or [this](https://github.com/angelXwind/simject/issues/42#issuecomment-440920466).

9. If you encoutered a problem while signing dylibs: `iPhone Developer: no identity found`, check out [this comment by iAlex11](https://github.com/angelXwind/simject/issues/55#issuecomment-615894757) (a neat way to get your identity is to run `security find-identity -p codesigning -v | head -n 1 | xargs | cut -d " " -f 2`).

### Final notes

Please understand that that testing your tweaks on the iOS Simulator is not necessarily a 100% accurate representation of how it will behave on an actual iOS device.

Certain features and frameworks are usually missing from or incomplete in the iOS Simulator (such as anything related to the Weather frameworks).

Yes, in *most* cases, it will work identically across both the iOS Simulator and a real iOS device, but there will always be some edge cases where this does not apply.

For those who want to test their preference bundle inside the simulator, you need to compile a simulator version of preferenceloader and do some extra steps that you can consult from [here](https://github.com/PoomSmart/preferenceloader-sim). It may not be as convenient as using only simject, but it works, at least.

Also, special thanks to [PoomSmart](https://github.com/PoomSmart) for his countless contributions to the simject project! Without him, I would have never even had the idea of creating such a tool.
