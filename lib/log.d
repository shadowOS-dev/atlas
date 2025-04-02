module lib.log;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 1, 2025
 */

import lib.printf;

void kprintf(S...)(S args)
{
    printf("[0.000000]: "); // TODO: actual time since we started
    printf(args);
    printf("\n");
}
