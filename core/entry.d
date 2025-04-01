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

/* Limine stuff */
mixin LIMINE_LINKER_DIRECTIVE;
immutable ulong[3] limine_base_revision = LIMINE_BASE_REVISION!3;

// Framebuffer request
mixin LIMINE_LINKER_DIRECTIVE;
static immutable framebuffer_request = limine_framebuffer_request(
    LIMINE_FRAMEBUFFER_REQUEST, 0, null);

// Requests start and end
extern (C) __gshared pragma(linkerDirective, "used, section=.limine_requests_start") static immutable ulong[4] limine_requests_start_marker = [
    0xf6b8f4b39de7d1ae, 0xfab91a6940fcb9cf,
    0x785c6ed015d3e316, 0x181e920a7852b9d9
];

extern (C) __gshared pragma(linkerDirective, "used, section=.limine_requests_end") static immutable ulong[2] limine_requests_end_marker = [
    0xadc0e0531bb10d03, 0x9572709f31764c62
];

/* Utility functions */
extern (C) void __assert(const(char)* msg, const(char)* file, uint line)
{
    printf("%s:%d: Assertion failed: \"%s\"\n", file, line, msg);
    hcf();
}

/* Entry point */
extern (C) void kmain()
{
    foreach (i, ulong v; limine_base_revision)
    {
        printf("%d: 0x%.16llx\n", i, v);
    }
    assert(limine_base_revision[2] == 0, "Unsupported limine base revision");
    printf("Atlas kernel v1.0-alpha\n");
    if (framebuffer_request.response == null || framebuffer_request.response.framebuffer_count <= 0)
    {
        printf("no framebuffer :^(\n");
        hcf();
    }

    printf("we got %d framebuffer(s)!\n", framebuffer_request.response.framebuffer_count);
    printf("response rev: %d\n", framebuffer_request.response.revision);
    halt();
}
