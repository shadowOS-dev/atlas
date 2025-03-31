module util.cpu;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

/* Halting functions */
void halt()
{
    while (true)
    {
        asm
        {
            hlt;
        }
    }
}

void hcf()
{
    asm
    {
        cli;
    }

    while (true)
    {
        asm
        {
            hlt;
        }
    }
}
