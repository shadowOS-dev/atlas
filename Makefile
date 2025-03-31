SRCDIR = .
BUILDDIR = build
DC = ldc2
CC = x86_64-elf-gcc
LD = x86_64-elf-ld
NASM = nasm
DFLAGS = -c -mtriple=x86_64-unknown-elf -fno-rtti -fno-exceptions -betterC --relocation-model=pic -code-model=kernel
NANOPRINTF_DEFINES = \
	-DNANOPRINTF_USE_FIELD_WIDTH_FORMAT_SPECIFIERS=1 \
	-DNANOPRINTF_USE_PRECISION_FORMAT_SPECIFIERS=1 \
	-DNANOPRINTF_USE_FLOAT_FORMAT_SPECIFIERS=0 \
	-DNANOPRINTF_USE_LARGE_FORMAT_SPECIFIERS=1 \
	-DNANOPRINTF_USE_BINARY_FORMAT_SPECIFIERS=0 \
	-DNANOPRINTF_USE_WRITEBACK_FORMAT_SPECIFIERS=0 \
	-DNANOPRINTF_SNPRINTF_SAFE_TRIM_STRING_ON_OVERFLOW=1 \

CFLAGS = -ffreestanding -fno-stack-protector -mno-red-zone -m64 -c -O2 -Wall -Wextra -fPIC $(NANOPRINTF_DEFINES)
LDFLAGS = -nostdlib -T linker.ld

SOURCES = $(shell find $(SRCDIR) -type f -name '*.d' ! -path './test/*')
C_SOURCES = $(shell find $(SRCDIR) -type f -name '*.c' ! -path './test/*')
ASM_SOURCES = $(shell find $(SRCDIR) -type f -name '*.asm' ! -path './test/*')
OBJECTS = $(patsubst ./%, $(BUILDDIR)/%, $(SOURCES:.d=.o)) \
          $(patsubst ./%, $(BUILDDIR)/_c_%, $(C_SOURCES:.c=.o)) \
          $(patsubst ./%, $(BUILDDIR)/_asm_%, $(ASM_SOURCES:.asm=.o))

KERNEL = $(BUILDDIR)/atlas.elf

all: $(KERNEL)

$(KERNEL): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(KERNEL)

$(BUILDDIR)/%.o: %.d
	@mkdir -p $(dir $@)
	$(DC) $(DFLAGS) -of=$@ $<

$(BUILDDIR)/_c_%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ $<

$(BUILDDIR)/_asm_%.o: %.asm
	@mkdir -p $(dir $@)
	$(NASM) -f elf64 -o $@ $<

clean:
	rm -rf $(BUILDDIR)/*

.PHONY: all clean
