module core_entry;

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

/* Limine Stuff */
mixin(BaseRevision!("3"));
__gshared pragma(linkerDirective, "used, section=.limine_requests") FramebufferRequest framebufferReq = {
    id: mixin(FramebufferRequestID!()),
    revision: 0
};

/* Utility Functions */
extern (C) void __assert(const(char)* msg, const(char)* file, uint line)
{
    printf("%s:%d: Assertion failed: \"%s\"\n", file, line, msg);
    hcf();
}

/* Entry Point */
extern (C) void kmain()
{
    assert(BaseRevisionSupported!(), "Unsupported limine base revision");
    printf("info: Supported limine base revision\n");

    assert(framebufferReq.response != null && framebufferReq.response.framebuffers[0] != null, "Failed to get framebuffer");
    auto framebufferRes = framebufferReq.response;
    printf("info: Got %d framebuffer(s)\n", framebufferRes.framebufferCount);

    Framebuffer* framebuffer = framebufferRes.framebuffers[0];
    printf("info: Framebuffer bpp: %d\n", framebuffer.bpp);

    foreach (ulong i; 0 .. 100)
    {
        uint* fbPtr = cast(uint*) framebuffer.address;
        fbPtr[i * (framebuffer.pitch / 4) + i] = 0xffffff;
    }

    halt();
}
