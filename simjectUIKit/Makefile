TARGET = simulator:clang
ARCHS = x86_64 i386
DEBUG = 0
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = simjectUIKit
simjectUIKit_FILES = simjectUIKit.xm ../simjectCore.mm

include $(THEOS_MAKE_PATH)/tweak.mk
<<<<<<< HEAD
=======

after-all::
	@echo Copying binaries...
	@mkdir -p ../bin
	@cp $(THEOS_OBJ_DIR)/simjectUIKit.dylib ../bin/
>>>>>>> angelXwind/master
