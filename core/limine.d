module core.limine;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

/* Misc */
enum ulong LIMINE_COMMON_MAGIC_1 = 0xc7b1dd30df4c8b88;
enum ulong LIMINE_COMMON_MAGIC_2 = 0x0a82e883a194f07b;

template LIMINE_BASE_REVISION(uint N)
{
    enum ulong[3] LIMINE_BASE_REVISION = [
            0xf9562b2d5c95a6c8, 0x6a7b384944536bdc, N
        ];
}

mixin template LIMINE_LINKER_DIRECTIVE()
{
    __gshared pragma(linkerDirective, "used, section=.limine_requests");
}

/* Framebuffer */
enum LIMINE_FRAMEBUFFER_RGB = 1;
enum LIMINE_FRAMEBUFFER_REQUEST = [
        LIMINE_COMMON_MAGIC_1, LIMINE_COMMON_MAGIC_2, 0x9d5827dcd881dd75,
        0xa3148604f6fab11b
    ];

struct limine_video_mode
{
    ulong pitch;
    ulong width;
    ulong height;
    ushort bpp;
    ubyte memory_model;
    ubyte red_mask_size;
    ubyte red_mask_shift;
    ubyte green_mask_size;
    ubyte green_mask_shift;
    ubyte blue_mask_size;
    ubyte blue_mask_shift;
}

struct limine_framebuffer
{
    void* address;
    ulong width;
    ulong height;
    ulong pitch;
    ushort bpp;
    ubyte memory_model;
    ubyte red_mask_size;
    ubyte red_mask_shift;
    ubyte green_mask_size;
    ubyte green_mask_shift;
    ubyte blue_mask_size;
    ubyte blue_mask_shift;
    ubyte[7] unused;
    ulong edid_size;
    void* edid;
    /* Response revision 1 */
    ulong mode_count;
    limine_video_mode*[] modes;
}

struct limine_framebuffer_response
{
    ulong revision;
    ulong framebuffer_count;
    limine_framebuffer*[] framebuffers;
}

struct limine_framebuffer_request
{
    ulong[4] id;
    ulong revision;
    limine_framebuffer_response* response;
}
