module dev.portio;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

@trusted
static void outb(ushort port, ubyte value)
{
    asm
    {
        mov DX, port;
        mov AL, value;
        out DX, AL;
    }
}

@trusted
static void outw(ushort port, ushort value)
{
    asm
    {
        mov DX, port;
        mov AX, value;
        out DX, AX;
    }
}

@trusted
static void outl(ushort port, uint value)
{
    asm
    {
        mov DX, port;
        mov EAX, value;
        out DX, EAX;
    }
}
