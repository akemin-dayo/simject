TARGET = macosx:clang::10.9
ARCHS = x86_64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = respring_simulator
respring_simulator_FILES = respring_simulator.mm
respring_simulator_CFLAGS = -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tool.mk

after-all::
	@echo "Copying binaries..."
	@mkdir -p ../bin
	@cp -v $(THEOS_OBJ_DIR)/respring_simulator ../bin/
