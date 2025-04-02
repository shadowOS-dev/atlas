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
import lib.flanterm;

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
    printf("info: Framebuffer pitch: %d\n", framebuffer.pitch);
    printf("info: Framebuffer address: %p\n", framebuffer.address);
    printf("info: Framebuffer width: %d\n", framebuffer.width);
    printf("info: Framebuffer height: %d\n", framebuffer.height);

    flanterm_context* ftCtx = flanterm_fb_init(
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
    flanterm_write(ftCtx, "Test".ptr, 4);

    halt();
}
