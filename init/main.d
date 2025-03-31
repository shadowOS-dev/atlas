/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

module init.main;
import boot.limine;
import dev.portio;
import util.cpu;

/* Limine stuff */
static immutable ulong[3] limine_base_revision = LIMINE_BASE_REVISION!3.value;

void puts(string s)
{
    foreach (i, c; s)
    {
        Port.write!ubyte(0xE9, cast(char) c);
    }
}

/* Entry point */
extern (C) void kmain()
{
    if (LIMINE_BASE_REVISION_SUPPORTED(limine_base_revision))
    {
        puts("Invalid base revision!\n");
        hcf();
    }

    puts("Hello, World!\n");
    halt();
}
