TARGET = simulator:clang::5.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = simject
simject_FILES = simject.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-all::
	@echo "Copying binaries..."
	@mkdir -p ../bin
	@cp -v $(THEOS_OBJ_DIR)/simject.dylib ../bin/
