module mm.liballoc;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 6, 2025
 */

import mm.vma;
import mm.vmm;
import init.entry;
import lib.lock;
import lib.printf;
import lib.log;
import core.vararg;

/* Logging */
extern (C) void la_trace(char* fmt, ...)
{
    if (kernelConf.heapTrace)
    {
        va_list args;
        va_start(args, fmt);
        vkprintf(fmt, args);
        va_end(args);
    }
}

extern (C) void la_error(char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vkprintf(fmt, args);
    va_end(args);
}

extern (C) void la_info(char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vkprintf(fmt, args);
    va_end(args);
}

/* Wrappers for liballoc */
__gshared Spinlock lock;
extern (C) int liballoc_lock()
{
    lock.lock();
    return 0;
}

extern (C) int liballoc_unlock()
{
    lock.unlock();
    return 0;
}

extern (C) void* liballoc_alloc(size_t pages)
{
    return vmaAllocPages(kernelVmaContext, pages, VMM_PRESENT | VMM_WRITE);
}

extern (C) int liballoc_free(void* ptr, size_t pages)
{
    vmaFreePages(kernelVmaContext, ptr);
    return 0;
}

/* Misc */
extern (C) extern void liballoc_dump();
