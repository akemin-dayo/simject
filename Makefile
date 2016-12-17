all::
	@make -C respring_simulator
	@make -C simject
	@make -C simjectUIKit

clean::
	@rm -rfv bin
	@make -C respring_simulator clean
	@make -C simject clean
	@make -C simjectUIKit clean

setup:: clean all
	@sudo mkdir -p /opt/simject
	@sudo chown -R $(USER) /opt/simject
	@cp -v bin/simject.dylib /opt/simject
	@cp -v simject/simject.plist /opt/simject
	@cp -v bin/simjectUIKit.dylib /opt/simject
	@cp -v simjectUIKit/simjectUIKit.plist /opt/simject
	@cp bin/simject.dylib /opt/simject
	@cp simject/simject.plist /opt/simject
	@cp bin/simjectUIKit.dylib /opt/simject
	@cp simjectUIKit/simjectUIKit.plist /opt/simject
	@echo Done. Place your tweak\'s dynamic libraries and accompanying property lists inside /opt/simject to load them in the iOS Simulator.
