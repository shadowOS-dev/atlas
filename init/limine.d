module init.limine;

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

/* Kernel file */
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

/* Memory map */
template MemoryMapRequestID()
{
    const char[] MemoryMapRequestID = "[ " ~ mixin(
        CommonMagic!()) ~ ", 0x67cf3d9d378a806f, 0xe304acdfc50c3c62 ]";
}

immutable ulong MemoryMapUsable = 0;
immutable ulong MemoryMapReserved = 1;
immutable ulong MemoryMapACPIReclaimable = 2;
immutable ulong MemoryMapACPINVS = 3;
immutable ulong MemoryMapBadMemory = 4;
immutable ulong MemoryMapBootloaderReclaimable = 5;
immutable ulong MemoryMapKernelAndModules = 6;
immutable ulong MemoryMapFramebuffer = 7;

struct MemmapEntry
{
    ulong base;
    ulong length;
    ulong type;
}

struct MemmapResponse
{
    ulong revision;
    ulong entryCount;
    MemmapEntry** entries;
}

struct MemmapRequest
{
    ulong[4] id;
    ulong revision;
    MemmapResponse* response;
}

/* Higher half */
template HHDMRequestID()
{
    const char[] HHDMRequestID = "[ " ~ mixin(
        CommonMagic!()) ~ ", 0x48dcf1cb8ad2b852, 0x63984e959a98244b ]";
}

struct HHDMResponse
{
    ulong revision;
    ulong offset;
}

struct HHDMRequest
{
    ulong[4] id;
    ulong revision;
    HHDMResponse* response;
}

/* Kernel address */
template KernelAddressRequestID()
{
    const char[] KernelAddressRequestID = "[ " ~ mixin(
        CommonMagic!()) ~ ", 0x71ba76863cc55f63, 0xb2644a48c516a487 ]";
}

struct KernelAddressResponse
{
    ulong revision;
    ulong physicalBase;
    ulong virtualBase;
}

struct KernelAddressRequest
{
    ulong[4] id;
    ulong revision;
    KernelAddressResponse* response;
}

/* Modules */
template ModuleRequestID()
{
    const char[] ModuleRequestID = "[ " ~ mixin(
        CommonMagic!()) ~ ", 0x3e7e279702be32af, 0xca1c4f3bd1280cee ]";
}

immutable ulong InternalModuleRequired = (1 << 0);

struct InternalModule
{
    const(char)* path;
    const(char)* cmdline;
    ulong flags;
}

struct ModuleResponse
{
    ulong revision;
    ulong moduleCount;
    File** modules;
}

struct ModuleRequest
{
    ulong[4] id;
    ulong revision;
    ModuleResponse* response;
    ulong internalModuleCount;
    InternalModule** internalModules;
}
