TARGET = simulator:clang
ARCHS = x86_64 i386
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = simject
simject_FILES = simject.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-all::
	@echo "Copying binaries..."
	@mkdir -p ../bin
	@cp -v $(THEOS_OBJ_DIR)/simject.dylib ../bin/
