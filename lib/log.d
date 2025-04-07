module lib.log;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 1, 2025
 */

import lib.printf;
import core.vararg;
import lib.nanoprintf;

void kprintf(S...)(S args)
{
    printf("[0.000000]: "); // TODO: actual time since we started
    printf(args);
    printf("\n");
}

int vkprintf(const char* fmt, va_list args)
{
    printf("[0.000000]: ");
    char[1024] buff;
    int length = npf_vsnprintf(cast(char*) buff, buff.sizeof, fmt, args);
    if (length >= 0 && length < buff.sizeof)
    {
        puts(cast(char*) buff);
    }
    printf("\n");
    return length;
}
