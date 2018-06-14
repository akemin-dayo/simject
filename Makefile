ARCHS = x86_64
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
	@codesign -f -s - /opt/simject/simject.dylib 
	@cp -v simject/simject.plist /opt/simject
	@echo "Done. Place your tweak's dynamic libraries and accompanying property lists inside /opt/simject to load them in the iOS Simulator."
