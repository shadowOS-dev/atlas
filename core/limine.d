module core.limine;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 1, 2025
 */

/* Miscellaneous Templates */
template BaseRevision(const char[] N)
{
    const char[] BaseRevision = "__gshared pragma(linkerDirective, \"used, section=.limine_requests\")  ulong[3] limine_base_revision = [ 0xf9562b2d5c95a6c8, 0x6a7b384944536bdc, " ~ N ~ "];";
}

template BaseRevisionSupported()
{
    const char[] BaseRevisionSupported = "(limine_base_revision[2] == 0)";
}

template CommonMagic()
{
    const char[] CommonMagic = "\"0xc7b1dd30df4c8b88, 0x0a82e883a194f07b\"";
}

struct UUID
{
    uint a;
    ushort b;
    ushort c;
    ubyte[8] d;
}

struct File
{
    ulong revision;
    void* address;
    ulong size;
    char* path;
    char* cmdline;
    uint mediaType;
    uint unused;
    uint tftpIP;
    uint tftpPort;
    uint partitionIndex;
    uint mbrDiskID;
    UUID gptDiskUUID;
    UUID gptPartUUID;
    UUID partUUID;
}

/* Framebuffer */
template FramebufferRequestID()
{
    const char[] FramebufferRequestID = "[ " ~ mixin(
        CommonMagic!()) ~ ", 0x9d5827dcd881dd75, 0xa3148604f6fab11b ]";
}

struct VideoMode
{
    ulong pitch;
    ulong width;
    ulong height;
    ushort bpp;
    ubyte memoryModel;
    ubyte redMaskSize;
    ubyte redMaskShift;
    ubyte greenMaskSize;
    ubyte greenMaskShift;
    ubyte blueMaskSize;
    ubyte blueMaskShift;
}

struct Framebuffer
{
    void* address;
    ulong width;
    ulong height;
    ulong pitch;
    ushort bpp;
    ubyte memoryModel;
    ubyte redMaskSize;
    ubyte redMaskShift;
    ubyte greenMaskSize;
    ubyte greenMaskShift;
    ubyte blueMaskSize;
    ubyte blueMaskShift;
    ubyte[7] unused;
    ulong edidSize;
    void* edid;
    /* Response revision 1 */
    ulong modeCount;
    VideoMode** modes;
}

struct FramebufferResponse
{
    ulong revision;
    ulong framebufferCount;
    Framebuffer** framebuffers;
}

struct FramebufferRequest
{
    ulong[4] id;
    ulong revision;
    FramebufferResponse* response;
}

/* Files (kernel file) */
template KernelFileRequestID()
{
    const char[] KernelFileRequestID = "[ " ~ mixin(
        CommonMagic!()) ~ ", 0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69 ]";
}

struct KernelFileResponse
{
    ulong revision;
    File* kernelFile;
}

struct KernelFileRequest
{
    ulong[4] id;
    ulong revision;
    KernelFileResponse* response;
}
