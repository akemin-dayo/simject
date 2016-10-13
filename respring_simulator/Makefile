TARGET = macosx:clang
ARCHS = x86_64 i386
DEBUG = 0
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TOOL_NAME = respring_simulator
respring_simulator_FILES = respring_simulator.mm ../simjectCore.mm
respring_simulator_CFLAGS = -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tool.mk

after-all::
	@echo Copying binaries...
	@mkdir -p ../bin
	@cp $(THEOS_OBJ_DIR)/respring_simulator ../bin/