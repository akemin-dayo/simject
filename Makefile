all::
	@make -C respring_simulator
	@make -C simject

clean::
	@rm -rfv bin
	@make -C respring_simulator clean
	@make -C simject clean

setup:: clean all
	@sudo mkdir -p /opt/simject
	@sudo chown -R $(USER) /opt/simject
	@# simjectUIKit has been deprecated:
	@rm -f /opt/simject/simjectUIKit.dylib:
	@rm -f /opt/simject/simjectUIKit.plist:
	@cp bin/simject.dylib /opt/simject
	@cp simject/simject.plist /opt/simject
	@echo Done. Place your tweak\'s dynamic libraries and accompanying property lists inside /opt/simject to load them in the iOS Simulator.
