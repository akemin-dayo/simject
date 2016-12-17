<<<<<<< HEAD
TARGET = simulator:clang
THEOS_PACKAGE_DIR_NAME = debs
ARCHS = x86_64 i386
DEBUG = 0
GO_EASY_ON_ME = 1
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

AGGREGATE_NAME = simjectProject
SUBPROJECTS = simject simjectUIKit respring_simulator

include $(THEOS_MAKE_PATH)/aggregate.mk

after-all::
	@echo Copying binaries...
	@mkdir -p bin
	@cp -v $(THEOS_OBJ_DIR)/respring_simulator $(THEOS_OBJ_DIR)/simject.dylib $(THEOS_OBJ_DIR)/simjectUIKit.dylib bin
=======
all::
	@make -C respring_simulator
	@make -C simject
	@make -C simjectUIKit
>>>>>>> angelXwind/master

clean::
	@rm -rfv bin
	@make -C respring_simulator clean
	@make -C simject clean
	@make -C simjectUIKit clean

setup:: clean all
	@sudo mkdir -p /opt/simject
	@sudo chown -R $(USER) /opt/simject
<<<<<<< HEAD
	@cp -v bin/simject.dylib /opt/simject
	@cp -v simject/simject.plist /opt/simject
	@cp -v bin/simjectUIKit.dylib /opt/simject
	@cp -v simjectUIKit/simjectUIKit.plist /opt/simject
=======
	@cp bin/simject.dylib /opt/simject
	@cp simject/simject.plist /opt/simject
	@cp bin/simjectUIKit.dylib /opt/simject
	@cp simjectUIKit/simjectUIKit.plist /opt/simject
>>>>>>> angelXwind/master
	@echo Done. Place your tweak\'s dynamic libraries and accompanying property lists inside /opt/simject to load them in the iOS Simulator.
