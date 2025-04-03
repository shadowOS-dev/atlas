module util.bitmap;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 3, 2025
 */

void bitmapSet(ubyte[] bitmap, ulong bit)
{
    bitmap[bit / 8] |= 1 << (bit % 8);
}

void bitmapClear(ubyte[] bitmap, ulong bit)
{
    bitmap[bit / 8] &= ~(1 << (bit % 8));
}

ubyte bitmapGet(ubyte[] bitmap, ulong bit)
{
    return bitmap[bit / 8] & (1 << (bit % 8));
}
