module lib.printf;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

import lib.nanoprintf;
import dev.portio;
import core.vararg;
import lib.flanterm;
import core.entry; // For flanterm writing on printf

int printf(S...)(S args)
{
    if (args.length == 0)
        return 0;

    extern (C) void putc(int c, void* ctx)
    {
        char ch = cast(char) c;
        if (ftCtx)
        {
            flanterm_write(ftCtx, &ch, 1);
        }
        outb(0xE9, cast(ubyte) c);
    }

    return npf_pprintf(&putc, null, cast(const char*) args[0], args[1 .. $]);
}
