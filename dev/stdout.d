module dev.stdout;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 8, 2025
 */

import init.entry;
import fs.devfs;
import lib.flanterm;
import dev.vfs;

/* globals */
__gshared Vnode* stdout = null;

/* devfs operations */
int stdoutRead(void* buf, size_t size, size_t offset)
{
    return -1; // stdout is not readable
}

int stdoutWrite(const(void)* buf, size_t size, size_t offset)
{
    if (buf is null || size == 0)
        return -1;

    if (offset >= size)
        return 0;

    auto remaining = size - offset;
    flanterm_write(ftCtx, cast(const(char)*) buf + offset, remaining);
    return cast(int) remaining;
}

/* main */
void stdoutInit()
{
    devfsAddDevice("stdout", &stdoutRead, &stdoutWrite); // hope it works
    stdout = vfsLazyLookup(rootMount, "/dev/stdout");
}
