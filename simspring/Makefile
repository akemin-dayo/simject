# TODO: This is a rather poor hack-job because simspring ends up being compiled with the simulator target
# Targeting the simulator for a macOS binary no longer works as of macOS 10.12
# However, changing this target to macosx:clang results in a Theos error for the time being
# I'll change this after I fix the corresponding issue in Theos.
TARGET = simulator:clang
# TARGET = macosx:clang
ARCHS = x86_64 i386
DEBUG = 0
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TOOL_NAME = simspring
simspring_FILES = simspring.mm ../simjectCore.mm
simspring_CFLAGS = -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tool.mk
