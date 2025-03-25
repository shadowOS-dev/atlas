MAKEFLAGS += -rR
.SUFFIXES:

override OUTPUT := atlas.elf
PREFIX := /usr/local
CC ?= cc
LD := $(CC)
AR := ar
CFLAGS := -g -O2 -pipe
CPPFLAGS :=
NASMFLAGS := -F dwarf -g
LDFLAGS :=

override CFLAGS += \
	-Wall \
	-Wextra \
	-std=gnu11 \
	-nostdinc \
	-ffreestanding \
	-fno-stack-protector \
	-fno-stack-check \
	-fno-PIC \
	-ffunction-sections \
	-fdata-sections

override CPPFLAGS := \
	-I include \
	-isystem freestnd-c-hdrs-0bsd \
	$(CPPFLAGS) \
	-DLIMINE_API_REVISION=3 \
	-MMD \
	-MP

override CFLAGS += \
	-m64 \
	-march=x86-64 \
	-mno-80387 \
	-mno-mmx \
	-mno-sse \
	-mno-sse2 \
	-mno-red-zone \
	-mcmodel=kernel

override LDFLAGS += \
	-Wl,-m,elf_x86_64

override NASMFLAGS += \
	-f elf64

override CFLAGS += \
	-m64 \
	-march=x86-64

override LDFLAGS += \
	-Wl,--build-id=none \
	-nostdlib \
	-static \
	-z max-page-size=0x1000 \
	-Wl,--gc-sections \
	-T linker.ld

# Collect all source files
override SRCFILES := $(shell find src -type f -name "*.c" -o -name "*.S" -o -name "*.asm" | grep -v "cc-runtime/" | grep -v "^./test/" | sort)

# Separate the source files based on extensions
override CFILES := $(filter src/%.c,$(SRCFILES))
override ASFILES := $(filter src/%.S,$(SRCFILES))
override NASMFILES := $(filter src/%.asm,$(SRCFILES))

# Ensure object files are placed in the correct build subdirectories
override OBJ := $(addprefix build/,$(CFILES:src/%.c=%.o) $(ASFILES:src/%.S=%.o) $(NASMFILES:src/%.asm=%.o))

# Handle dependencies
override HEADER_DEPS := $(addprefix build/,$(CFILES:src/%.c=%.d) $(ASFILES:src/%.S=%.d))
override HEADER_DEPS := $(patsubst src/%, build/%, $(HEADER_DEPS))

.PHONY: all
all: $(OUTPUT)

-include $(HEADER_DEPS)

build/cc-runtime/cc-runtime.a: $(wildcard cc-runtime/*)
	@if [ ! -f build/cc-runtime/cc-runtime.a ] || [ $(shell find cc-runtime/ -type f -newer build/cc-runtime/cc-runtime.a) ]; then \
		echo "Rebuilding cc-runtime.a..."; \
		mkdir -p build/cc-runtime; \
		cp -r cc-runtime/* build/cc-runtime/; \
		$(MAKE) -C build/cc-runtime -f cc-runtime.mk CC="$(CC)" AR="$(AR)" CFLAGS="$(CFLAGS)" CPPFLAGS='-isystem ../../freestnd-c-hdrs-0bsd -DCC_RUNTIME_NO_FLOAT'; \
	fi

$(OUTPUT): Makefile linker.ld $(OBJ) build/cc-runtime/cc-runtime.a
	mkdir -p "$$(dirname $@)"
	$(LD) $(CFLAGS) $(LDFLAGS) $(OBJ) build/cc-runtime/cc-runtime.a -o $@

# Compilation rules for .c, .S, and .asm files
build/%.o: src/%.c Makefile
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

build/%.o: src/%.S Makefile
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

build/%.o: src/%.asm Makefile
	mkdir -p "$$(dirname $@)"
	nasm $(NASMFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -rf build/ atlas.elf

.PHONY: install
install: all
	install -d "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)"
	install -m 644 build/$(OUTPUT) "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)/$(OUTPUT)"

.PHONY: uninstall
uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)/$(OUTPUT)"
	-rmdir "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)"
