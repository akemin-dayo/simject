ARCHS = x86_64
# If using Xcode 8.3.3 and below, uncomment the below line to enable building an i386 slice for simject to use with 32-bit iOS Simulators.
# ARCHS = x86_64 i386
DEBUG = 0

all::
	@make -C respring_simulator
	@make -C simject

clean::
	@rm -rfv bin
	@make -C respring_simulator clean
	@make -C simject clean

setup:: clean all
	@sudo mkdir -p /opt/simject
	@sudo chown -Rv $(USER) /opt/simject
	# simjectUIKit has been deprecated.
	@rm -fv /opt/simject/simjectUIKit.dylib
	@rm -fv /opt/simject/simjectUIKit.plist
	@cp -v bin/simject.dylib /opt/simject
	@cp -v simject/simject.plist /opt/simject
	@echo "Done. Place your tweak's dynamic libraries and accompanying property lists inside /opt/simject to load them in the iOS Simulator."
