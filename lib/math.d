module lib.math;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 3, 2025
 */

template divRoundUp(T)
{
    T divRoundUp(T x, T y)
    {
        return (x + (y - 1)) / y;
    }
}

template alignUp(T)
{
    T alignUp(T x, T y)
    {
        return divRoundUp(x, y) * y;
    }
}

template alignDown(T)
{
    T alignDown(T x, T y)
    {
        return (x / y) * y;
    }
}
