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
import init.entry;

extern (C) void putc(int c, void* ctx)
{
    char ch = cast(char) c;
    if (ftCtx && kernelConf.graphicalPrintf)
    {
        flanterm_write(ftCtx, &ch, 1);
    }
    outb(0xE9, cast(ubyte) c);
}

void puts(char* str)
{
    while (*str)
    {
        putc(*str++, null);
    }
}

int printf(S...)(S args)
{
    if (args.length == 0)
        return 0;

    return npf_pprintf(&putc, null, cast(const char*) args[0], args[1 .. $]);
}

int vprintf(const char* fmt, va_list args)
{
    char[1024] buff;
    int length = npf_vsnprintf(cast(char*) buff, buff.sizeof, fmt, args);
    if (length >= 0 && length < buff.sizeof)
    {
        puts(cast(char*) buff);
    }

    return length;
}

extern (C) int snprintf(char* buf, size_t size, const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    int length = vsnprintf(buf, size, fmt, args);
    va_end(args);
    return length;
}

int vsnprintf(char* buf, size_t size, const char* fmt, va_list args)
{
    int length = npf_vsnprintf(buf, size, fmt, args);

    if (length >= cast(int) size)
    {
        buf[size - 1] = '\0';
    }

    return length;
}
