# simject

simject is a command-line tool and iOS dynamic library that allows developers to easily test their tweaks on the iOS Simulator.

simject is BSD-licensed. See `LICENSE` for more information.

### simject setup (requires the latest version of [Theos](https://github.com/theos/theos))

1. `git clone https://github.com/angelXwind/simject.git`

1. `cd simject/`

1. `make setup`

1. Note: During the process, you will be asked by `sudo` to enter in your login password. Please note that it is normal for nothing to be displayed as you type your password.

1. Download the simulator version of [CydiaSubstrate.framework](https://cydia.saurik.com/api/latest/3). Extract the zip file and head inside Cycript.lib, rename the file `libsubtrate.dylib` to `CydiaSubstrate` then have it inside the folder named `CydiaSubstrate.framework`). Copy this framework to `/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS <SDK-Version>.simruntime/Contents/Resources/RuntimeRoot/Library/Frameworks` where `<SDK-Version>` is your target runtime version. If `/Library/Frameworks` doesn't exist, you can create it manually.

1. Alternatively, you can obtain the framework ready to be copied this way (using `wget`): `cd ~/Downloads; wget -O cycript.zip https://cydia.saurik.com/api/latest/3; unzip cycript.zip -d cycript; mkdir -p CydiaSubstrate.framework; mv cycript/Cycript.lib/libsubstrate.dylib CydiaSubstrate.framework/CydiaSubstrate; rm -r cycript; rm cycript.zip`

1. Select your Xcode directory (for example): `sudo xcode-select -s /Applications/Xcode.app`

### simject usage

1. Place your dynamic libraries and accompanying property lists inside `/opt/simject` to load them in the iOS Simulator. Do not delete `simject.plist` or `simject.dylib`.

1. Inside the `bin` subdirectory, you will find the `respring_simulator` command-line tool. Execute it to cause booted iOS Simulator(s) to respring and be able to load tweaks.

1. You might need to run `respring_simulator` every time the device reboots or if SpringBoard crashes.

1. You can respring multiple simulators as well (check its usage), provided that the selected Xcode version is 9 or above.

1. Happy developing! (And don't make SpringBoard cry *too* hard... it has feelings, too! Probably.)

### Targeting the iOS Simulator

1. Open your project's `Makefile`.

1. Change your `TARGET` variable to `TARGET = simulator:clang` (you may optionally specify the SDK/deployment versions)

1. If you want to support 32-bit iOS Simulators (in addition to 64-bit), add `ARCHS = x86_64 i386` to your Makefile. If you are fine without 32-bit support, then simply add `ARCHS = x86_64`.

1. `make` your project and copy `.theos/obj/iphone_simulator/$YOUR_TWEAK.dylib` to `/opt/simject/$YOUR_TWEAK.dylib`

1. If there is already `/opt/simject/$YOUR_TWEAK.dylib`, you have to delete it first before copying.

1. Also make sure to copy `$YOUR_TWEAK.plist` to `/opt/simject/$YOUR_TWEAK.plist`. simject will not load your tweak if you miss this step!

1. An example tweak project is available in the `simjectExampleTweak/` subfolder. Use it as reference if you want.

### Final notes

Do keep in mind that just because your tweak works in the Simulator doesn't necessarily mean it'll work on an actual iOS device. Yes, in 99% of cases, it will work just fine, but there will always be some strange edge cases where this does not apply. Plus, certain features are usually ripped out of simulator runtimes so please don't expect testing on simulators are 100% similar to on real devices.

Also, special thanks to PoomSmart for his countless contributions.
