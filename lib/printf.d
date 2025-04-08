module lib.printf;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

import lib.nanoprintf;
import sys.portio;
import core.vararg;
import dev.vfs;
import dev.stdout;
import init.entry;
import lib.flanterm;
import sys.idt;

extern (C) void putc(int c, void* ctx)
{
    char ch = cast(char) c;

    outb(0xE9, ch);

    if (panicking)
    {
        if (ftCtx)
        {
            flanterm_write(ftCtx, &ch, 1);
        }
    }
}

void puts(char* str)
{
    while (*str)
        putc(*str++, null);
}

void put(char* buff, size_t len)
{
    for (size_t i = 0; i < len; i++)
    {
        putc(buff[i], null);
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
        puts(cast(char*) buff);

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

    if (length >= cast(int) size && size > 0)
        buf[size - 1] = '\0';

    return length;
}

int fwrite(Vnode* vnode, const(void)* buffer, size_t size)
{
    int totalWritten = 0;
    while (totalWritten < size)
    {
        int written = vfsWrite(vnode, cast(const(char)*) buffer + totalWritten, size - totalWritten, 0);
        if (written <= 0)
        {
            return -1;
        }
        totalWritten += written;
    }
    return totalWritten;
}

int vfprintf(Vnode* vnode, const(char)* fmt, va_list args)
{
    char[1024] buffer;
    int length = npf_vsnprintf(cast(char*) buffer, buffer.sizeof, fmt, args);
    fwrite(vnode, cast(char*) buffer, length);
    return length;
}

extern (C) int fprintf(Vnode* vnode, const(char)* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    int length = vfprintf(vnode, fmt, args);
    va_end(args);
    return length;
}
