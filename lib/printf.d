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

void put(const(char)* data, size_t len)
{
    foreach (i; 0 .. len)
    {
        outb(0xE9, data[i]); // Write only to 0xE9 (debugcon) for now.
    }
}

int printf(S...)(S args)
{
    npf_putc putc = (int c, void* ctx) { char temp = cast(char) c; put(&temp, 1); };
    return npf_pprintf(putc, null, cast(const(char)*) args[0], args[1 .. $]);
}
