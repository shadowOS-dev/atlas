SRCDIR = .
BUILDDIR = build
DC = ldc2
LD = x86_64-elf-ld
NASM = nasm
DFLAGS = -c -mcmodel=kernel -mtriple=x86_64-unknown-elf -fno-rtti -fno-exceptions -betterC
LDFLAGS = -nostdlib -T linker.ld
SOURCES = $(shell find $(SRCDIR) -type f -name '*.d' ! -path './test/*')
ASM_SOURCES = $(shell find $(SRCDIR) -type f -name '*.asm' ! -path './test/*')
OBJECTS = $(patsubst ./%, $(BUILDDIR)/%, $(SOURCES:.d=.o)) $(patsubst ./%, $(BUILDDIR)/_asm_%, $(ASM_SOURCES:.asm=.o))
KERNEL = $(BUILDDIR)/atlas.elf

all: $(KERNEL)

$(KERNEL): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(KERNEL)

$(BUILDDIR)/%.o: %.d
	@mkdir -p $(dir $@)
	$(DC) $(DFLAGS) -of=$@ $<

$(BUILDDIR)/_asm_%.o: %.asm
	@mkdir -p $(dir $@)
	$(NASM) -f elf64 -o $@ $<

clean:
	rm -rf $(BUILDDIR)/*

.PHONY: all clean
