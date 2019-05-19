TARGET = macosx:clang::10.9
ARCHS = x86_64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = resim
resim_FILES = resim.mm
resim_CFLAGS = -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tool.mk

after-all::
	@echo "Copying binaries..."
	@mkdir -p ../bin
	@cp -v $(THEOS_OBJ_DIR)/resim ../bin/
