module init.entry;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

import util.cpu;
import dev.portio;
import lib.printf;
import init.limine;
import lib.flanterm;
import lib.log;
import util.string;
import sys.gdt;
import sys.idt;
import mm.pmm;
import mm.vmm;
import mm.vma;
import mm.kmalloc;
import mm.liballoc;
import dev.vfs;
import fs.ramfs;

/* Config */
enum PAGE_SIZE = 0x1000; // 4096

/* Globals */
__gshared flanterm_context* ftCtx;

struct KernelConfig
{
    bool graphicalPrintf;
    bool heapTrace;
}

__gshared KernelConfig kernelConf = KernelConfig(false);
__gshared ulong kernelAddrVirt;
__gshared ulong kernelAddrPhys;
__gshared ulong kernelStackTop;

__gshared VMAContext* kernelVmaContext;

/* Limine Stuff */
mixin(BaseRevision!("3"));
__gshared pragma(linkerDirective, "used, section=.limine_requests") KernelFileRequest kernelFileReq = {
    id: mixin(KernelFileRequestID!()),
    revision: 0
};

__gshared pragma(linkerDirective, "used, section=.limine_requests") FramebufferRequest framebufferReq = {
    id: mixin(FramebufferRequestID!()),
    revision: 0
};

__gshared pragma(linkerDirective, "used, section=.limine_requests") MemmapRequest memmapReq = {
    id: mixin(MemoryMapRequestID!()),
    revision: 0
};

__gshared pragma(linkerDirective, "used, section=.limine_requests") HHDMRequest hhdmReq = {
    id: mixin(HHDMRequestID!()),
    revision: 0
};

__gshared pragma(linkerDirective, "used, section=.limine_requests") KernelAddressRequest kernelAddrReq = {
    id: mixin(KernelAddressRequestID!()),
    revision: 0
};

__gshared pragma(linkerDirective, "used, section=.limine_requests") ModuleRequest moduleReq = {
    id: mixin(ModuleRequestID!()),
    revision: 0
};

/* Entry Point */
extern (C) void __assert(const(char)* msg, const(char)* file, uint line)
{
    printf("%s:%d: Assertion failed: \"%s\"\n", file, line, msg);
    hcf();
}

extern (C) void kmain()
{
    asm
    {
        movq kernelStackTop, RSP;
    }

    assert(BaseRevisionSupported!(), "Unsupported limine base revision");
    kprintf("Supported limine base revision");

    assert(kernelFileReq.response, "Failed to get kernel file");
    char* cmdline = kernelFileReq.response.kernelFile.cmdline;
    kprintf("cmdline: %s", cmdline);
    kernelConf.graphicalPrintf = !isInString(cmdline, "quiet".ptr);
    kernelConf.heapTrace = isInString(cmdline, "heapTrace".ptr);

    // Framebuffer shit
    assert(framebufferReq.response != null && framebufferReq.response.framebuffers[0] != null, "Failed to get framebuffer");
    auto framebufferRes = framebufferReq.response;
    kprintf("Got %d framebuffer(s)", framebufferRes.framebufferCount);

    Framebuffer* framebuffer = framebufferRes.framebuffers[0];
    kprintf("Framebuffer bpp: %d", framebuffer.bpp);
    kprintf("Framebuffer pitch: %d", framebuffer.pitch);
    kprintf("Framebuffer address: %p", framebuffer.address);
    kprintf("Framebuffer width: %d", framebuffer.width);
    kprintf("Framebuffer height: %d", framebuffer.height);

    ftCtx = flanterm_fb_init(
        null,
        null,
        cast(uint*) framebuffer.address, framebuffer.width, framebuffer.height, framebuffer.pitch,
        framebuffer.redMaskSize, framebuffer.redMaskShift,
        framebuffer.greenMaskSize, framebuffer.greenMaskShift,
        framebuffer.blueMaskSize, framebuffer.blueMaskShift,
        null,
        null, null,
        null, null,
        null, null,
        null, 0, 0, 1,
        0, 0,
        0);
    assert(ftCtx, "Failed to initialize flanterm");

    kprintf("Atlas kernel v1.0-alpha");

    // Interrupts
    gdtInit();
    kprintf("loaded gdt @ 0x%.16llx", gdtPtr.base);
    idtInit();
    kprintf("loaded idt @ 0x%.16llx", idtPtr.base);

    // Memory and heap
    assert(memmapReq.response, "Failed to get memory map");
    assert(hhdmReq.response, "Failed to get HHDM offset");
    pmmInit();

    ulong numPages = 1024;
    int* a = cast(int*) physRequestPages(numPages, true);
    assert(a, "Failed to allocate pages");
    kprintf("test phys alloc -> 0x%.16llx", cast(ulong) a);
    *a = 32;
    physReleasePages(a, numPages);
    kprintf("loaded phys bitmap @ 0x%.16llx", cast(ulong)&physBitmap);

    assert(kernelAddrReq.response, "Failed to get kernel address");
    kernelAddrPhys = kernelAddrReq.response.physicalBase;
    kernelAddrVirt = kernelAddrReq.response.virtualBase;
    vmmInit();
    kernelVmaContext = vmaCreateContext(kernelPagemap);
    assert(kernelVmaContext, "Failed to create kernel VMA context");
    kprintf("Created kernel VMA context @ 0x%.16llx", cast(ulong) kernelVmaContext);
    int* b = cast(int*) vmaAllocPages(kernelVmaContext, 1024, VMM_PRESENT | VMM_WRITE);
    assert(b, "Failed to allocate pages");
    kprintf("test virt alloc -> 0x%.16llx", cast(ulong) b);
    *b = 32;
    vmaFreePages(kernelVmaContext, b);

    // Test heap
    int* c = cast(int*) kmalloc(int.sizeof);
    assert(c, "Failed to allocate on the heap");
    *c = 32;
    kprintf("test heap alloc -> 0x%.16llx", cast(ulong) c);
    kfree(c);

    // Filesystem
    vfsInit();
    kprintf("Root mount at 0x%.16llx", cast(ulong) rootMount);
    assert(moduleReq.response.moduleCount >= 1, "Expected at-least one module passed");
    kprintf("Found %d modules", moduleReq.response.moduleCount);
    void* ramfsData = moduleReq.response.modules[0].address;
    ulong ramfsSize = cast(ulong) moduleReq.response.modules[0].size;
    assert(ramfsData);
    assert(ramfsSize != 0);
    ramfsInit(rootMount, RAMFS_TYPE_USTAR, ramfsData, ramfsSize);

    Vnode* test = vfsLazyLookup(rootMount, cast(char*) "/test.txt".ptr);
    assert(test, "Failed to find /a.txt");
    char* buff = cast(char*) kmalloc(test.size);
    vfsRead(test, buff, test.size, 0);

    printf("\033[2J\033[H");
    printf("%s", buff);

    halt();
}
