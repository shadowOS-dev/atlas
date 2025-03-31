/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

module dev.portio;

import std.traits;

struct Port
{
    @trusted
    private static void outb(ubyte port, ubyte value) nothrow
    {
        asm nothrow
        {
            mov DX, port;
            mov AL, value;
            out DX, AL;
        }
    }

    @trusted
    private static void outw(ubyte port, ushort value) nothrow
    {
        asm nothrow
        {
            mov DX, port;
            mov AX, value;
            out DX, AX;
        }
    }

    @trusted
    private static void outl(ubyte port, uint value) nothrow
    {
        asm nothrow
        {
            mov DX, port;
            mov EAX, value;
            out DX, EAX;
        }
    }

    @trusted
    private static ubyte inb(ubyte port) nothrow
    {
        ubyte result;
        asm nothrow
        {
            mov DX, port;
             in AL, DX;
            mov result, AL;
        }
        return result;
    }

    @trusted
    private static ushort inw(ubyte port) nothrow
    {
        ushort result;
        asm nothrow
        {
            mov DX, port;
             in AX, DX;
            mov result, AX;
        }
        return result;
    }

    @trusted
    private static uint inl(ubyte port) nothrow
    {
        uint result;
        asm nothrow
        {
            mov DX, port;
             in EAX, DX;
            mov result, EAX;
        }
        return result;
    }

    static void write(T)(ubyte port, T value) @safe nothrow
    {
        static if (is(T == ubyte))
            outb(port, cast(ubyte) value);
        else static if (is(T == ushort))
            outw(port, cast(ushort) value);
        else static if (is(T == uint))
            outl(port, cast(uint) value);
        else
            static assert(false, "Unsupported port write size: " ~ T.stringof);
    }

    static T read(T)(ubyte port) @safe nothrow
    {
        static if (is(T == ubyte))
            return inb(port);
        else static if (is(T == ushort))
            return inw(port);
        else static if (is(T == uint))
            return inl(port);
        else
            static assert(false, "Unsupported port read size: " ~ T.stringof);
    }
}
