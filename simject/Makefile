ifndef DYLIB_DIR
  DYLIB_DIR = /opt/simject
endif
# shouldn't need more than one unless it's being packaged

ifndef ARCH
  ARCHFLAG = 
else
  ARCHFLAG = -arch $(ARCH)
endif

ifndef SYSROOT
  SYSROOT = $(shell xcode-select -p)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk
endif

ifndef TRIPLE
  TRIPLE = $(shell clang -print-target-triple)
endif

clean::
	-@rm -r out/

build : simject.m
	@mkdir -p out
	@echo "$(PREFIX) Compiling simject for $(TRIPLE)"
	@echo "$(SUB_PREFIX) Using SDK at $(SYSROOT)"
	@echo "$(SUB_PREFIX) Target directory is $(DYLIB_DIR)"
	@$(CC) simject.m $(ARCHFLAG) -framework Foundation -isysroot $(SYSROOT) -target $(TRIPLE) -DDYLIB_DIR=@\"$(DYLIB_DIR)\" -dynamiclib -o out/simject.dylib
	@echo "$(SUB_PREFIX) Signing..."
	@codesign -f -s - out/simject.dylib
	@echo "$(SUB_PREFIX) Copying library..."
	@mkdir -p ../bin
	@cp out/simject.dylib ../bin
