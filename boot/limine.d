/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

// === Up-to specification for Limine v9.x ===
module boot.limine;

/* Misc */
static enum LIMINE_API_REVISION = 0;

template LIMINE_PTR(T)
{
    alias LIMINE_PTR = T;
}

template LIMINE_BASE_REVISION(ulong N)
{
    enum value = [
            0xf9562b2d5c95a6c8, 0x6a7b384944536bdc, N
        ];
}

/* Utility functions */
bool LIMINE_BASE_REVISION_SUPPORTED(ulong[3] limineBaseRevision)
{
    return limineBaseRevision[2] == 0; // Check if the third element is 0
}
