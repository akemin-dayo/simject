export PREFIX = \033[1;36m>>\033[0m
export SUB_PREFIX = \033[1;36m>>>\033[0m
export DONE_PREFIX = \033[1;32m>>\033[0m

ifndef DYLIB_DIR
  DYLIB_DIR = /opt/simject
endif

PARENT = $(shell dirname $(DYLIB_DIR))
DD_NOT_EXISTS = $(shell test -d $(DYLIB_DIR); echo $$?)
DD_NOT_WRITABLE = $(shell test -w $(PARENT); echo $$?)
ifeq '$(DD_NOT_WRITABLE)' '1'
NEED_ROOT = sudo
NEED_ROOT_ASK = \033[1;32m>>\033[0m $(PARENT) is not writable. Using sudo.
endif

ifndef SYSROOT
  SYSROOT = $(shell xcode-select -p)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk
endif

ifndef TRIPLE
  TRIPLE = $(shell clang -print-target-triple)
endif

all::
	@make -C resim build
	@make -C simject build

clean::
	@rm -rfv bin
	@make -C resim clean
	@make -C simject clean

setup:: all
	@test -w $(PARENT) || echo "$(NEED_ROOT_ASK)"
	@$(NEED_ROOT) mkdir -p $(DYLIB_DIR)
	@$(NEED_ROOT) chown -R $(USER) $(DYLIB_DIR)
	@echo "$(PREFIX) Copying Tweak Loader to $(DYLIB_DIR)"
	@cp bin/simject.dylib $(DYLIB_DIR)
	@cp simject/simject.plist $(DYLIB_DIR)
	@echo "$(PREFIX) Installing resim"
	@cp bin/resim /usr/local/bin/resim
	@echo "$(DONE_PREFIX) Done. Place your tweak's dynamic libraries and accompanying property lists inside $(DYLIB_DIR) to load them in the iOS Simulator."
	@echo "$(DONE_PREFIX) To load/reload tweaks, run 'resim' in your terminal"
