module core.entry;

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
import core.limine;
import lib.flanterm;
import lib.log;
import util.string;
import sys.gdt;

/* Globals */
__gshared flanterm_context* ftCtx;

struct KernelConfig
{
    bool graphical_kprintf;
}

__gshared KernelConfig kernelConf = KernelConfig(false);

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

/* Entry Point */
extern (C) void __assert(const(char)* msg, const(char)* file, uint line)
{
    printf("%s:%d: Assertion failed: \"%s\"\n", file, line, msg);
    hcf();
}

extern (C) void kmain()
{
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

    // Interrupts and stuff
    initGDT();
    kprintf("loaded gdt @ 0x%.16llx", gdtPtr.base);

    // we are done
    kprintf("Atlas kernel v1.0-alpha");
    halt();
}
