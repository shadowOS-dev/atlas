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

/* Config */
enum PAGE_SIZE = 0x1000; // 4096

/* Globals */
__gshared flanterm_context* ftCtx;

struct KernelConfig
{
    bool graphical_kprintf;
}

__gshared KernelConfig kernelConf = KernelConfig(false);
__gshared ulong kernelAddrVirt;
__gshared ulong kernelAddrPhys;
__gshared ulong kernelStackTop;

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
    kernelConf.graphical_kprintf = !isInString(cmdline, "quiet".ptr);

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

    // Interrupts
    initGDT();
    kprintf("loaded gdt @ 0x%.16llx", gdtPtr.base);
    initIDT();
    kprintf("loaded idt @ 0x%.16llx", idtPtr.base);

    // Memory and heap
    assert(memmapReq.response, "Failed to get memory map");
    assert(hhdmReq.response, "Failed to get HHDM offset");
    initPMM();

    int* test = cast(int*) physRequestPages(64, true);
    kprintf("test phys alloc -> 0x%.16llx", cast(ulong) test);
    assert(test, "Failed to allocate 64 pages");
    *test = 32;
    physReleasePages(test, 64);
    kprintf("loaded phys bitmap @ 0x%.16llx", cast(ulong)&physBitmap);

    assert(kernelAddrReq.response, "Failed to get kernel address");
    kernelAddrPhys = kernelAddrReq.response.physicalBase;
    kernelAddrVirt = kernelAddrReq.response.virtualBase;

    initVMM();

    // we are done
    kprintf("Atlas kernel v1.0-alpha, very cool :3");
    halt();
}
