THEOS_PACKAGE_DIR_NAME = debs
TARGET = simulator:clang
DEBUG = 0
GO_EASY_ON_ME = 1
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = simject
simject_FILES = simject.xm simjectCore.mm

include $(THEOS_MAKE_PATH)/tweak.mk

# TODO: This is a rather poor hack-job because respring_simulator ends up being compiled with the simulator target
# The better (proper) way to do this is to create a separate Makefile using the macosx target...

TOOL_NAME = respring_simulator
respring_simulator_FILES = respring_simulator.mm simjectCore.mm
respring_simulator_CFLAGS = -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tool.mk

after-all::
	@echo Copying binaries...
	@mkdir -p bin
	@cp -v $(THEOS_OBJ_DIR)/respring_simulator $(THEOS_OBJ_DIR)/simject.dylib bin

clean::
	@rm -rfv bin

setup:: clean all
	@sudo mkdir -p /opt/simject
	@sudo chown -R $(USER) /opt/simject
	@cp -v bin/simject.dylib /opt/simject
	@cp -v simject.plist /opt/simject
	@echo Done. Place your tweak\'s dynamic libraries and accompanying property lists inside /opt/simject to load them in the iOS Simulator.
