module dev.vfs;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 7, 2025
 */

import mm.kmalloc;
import util.string;
import lib.lock;
import lib.log;
import lib.printf;

/* Globals */
__gshared Mount* rootMount = null;

/* Defines */
enum
{
    VNODE_DIR = 0x0001,
    VNODE_FILE = 0x0002,
    VNODE_DEV = 0x0003
}

enum
{
    VNODE_FLAG_MOUNTPOINT = 0x0001,

    VNODE_MODE_RUSR = 0x0100, // Read permission for the owner
    VNODE_MODE_WUSR = 0x0080, // Write permission for the owner
    VNODE_MODE_XUSR = 0x0040, // Execute permission for the owner

    VNODE_MODE_RGRP = 0x0020, // Read permission for the group
    VNODE_MODE_WGRP = 0x0010, // Write permission for the group
    VNODE_MODE_XGRP = 0x0008, // Execute permission for the group

    VNODE_MODE_ROTH = 0x0004, // Read permission for others
    VNODE_MODE_WOTH = 0x0002, // Write permission for others
    VNODE_MODE_XOTH = 0x0001 // Execute permission for others
}

/* Structs */
struct VnodeOps
{
    int function(Vnode* vnode, void* buf, size_t size, size_t offset) read;
    int function(Vnode* vnode, const(void)* buf, size_t size, size_t offset) write;
    Vnode* function(Vnode* self, const(char)* name, uint type) create;
}

struct Vnode
{
    Vnode* parent;
    Vnode* next;
    Vnode* child;
    Mount* mount;

    uint type;
    char* name;

    ulong size;
    void* data;

    uint uid;
    uint gid;

    uint mode;

    uint ctime;
    uint atime;
    uint mtime;

    VnodeOps* ops;
    uint flags;
    Spinlock lock;
}

struct Mount
{
    Vnode* root;
    Mount* next;
    Mount* prev;
    char* mountPoint;
    char* type;
    void* data;
}

/* Functions */
void vfsInit()
{
    Mount* mount = cast(Mount*) kmalloc(Mount.sizeof);
    assert(mount, "Failed to allocate memory for root mount");

    mount.root = cast(Vnode*) kmalloc(Vnode.sizeof);
    assert(mount.root, "Failed to allocate memory root vnode");

    mount.root.name = cast(char*) kmalloc(strlen("/") + 1);
    assert(mount.root.name, "Failed to allocate memory for root vnode name");
    strncpy(mount.root.name, "/", 1);
    mount.root.name[1] = '\0';

    mount.root.type = VNODE_DIR;
    mount.root.child = null;
    mount.root.mount = mount;
    mount.root.parent = mount.root;
    mount.root.uid = 0;
    mount.root.gid = 0;
    mount.root.mode = VNODE_MODE_RUSR | VNODE_MODE_WUSR | VNODE_MODE_XUSR |
        VNODE_MODE_RGRP | VNODE_MODE_XGRP |
        VNODE_MODE_ROTH | VNODE_MODE_XOTH;
    spinlockInit(&mount.root.lock);
    mount.root.data = null;
    mount.root.ops = null;
    mount.root.size = 0;
    mount.root.ctime = 0;
    mount.root.atime = 0;
    mount.root.mtime = 0;
    mount.root.flags = 0;

    mount.next = null;
    mount.prev = null;

    mount.mountPoint = cast(char*) kmalloc(strlen("") + 1);
    assert(mount.mountPoint, "Failed to allocate memory for mount point string");
    strncpy(mount.mountPoint, "", 1);
    mount.mountPoint[1] = '\0';
    mount.type = cast(char*) kmalloc(strlen("rootfs") + 1);
    assert(mount.type, "Failed to allocate memory for mount type string");
    strncpy(mount.type, "rootfs", strlen("rootfs"));
    mount.type[strlen("rootfs")] = '\0';
    mount.data = null;
    rootMount = mount;
}

Vnode* vfsLookup(Vnode* parent, const(char)* name)
{
    Vnode* current = parent.child;
    while (current != null)
    {
        if (strcmp(current.name, name) == 0)
        {
            return current;
        }
        current = current.next;
    }
    return null;
}

Vnode* vfsLazyLookup(Mount* mount, const(char)* p)
{
    char* path = cast(char*) p;
    if (mount is null || path is null || path[0] != '/')
    {
        kprintf("Invalid mount or path\n");
        return null;
    }

    Vnode* currentVnode = mount.root;
    if (currentVnode is null)
    {
        kprintf("No root vnode in the mount\n");
        return null;
    }

    char* currentPath = path + 1;
    size_t bufferSize = 256;
    char* nameBuffer = cast(char*) kmalloc(bufferSize);
    assert(nameBuffer, "Failed to allocate memory for nameBuffer");

    ulong bufferIndex = 0;

    while (*currentPath != '\0')
    {
        bufferIndex = 0;

        while (*currentPath != '/' && *currentPath != '\0' && bufferIndex < bufferSize - 1)
        {
            nameBuffer[bufferIndex++] = *currentPath++;
        }
        nameBuffer[bufferIndex] = '\0';

        if (bufferIndex == bufferSize - 1 && *currentPath != '/')
        {
            bufferSize *= 2;
            nameBuffer = cast(char*) krealloc(nameBuffer, bufferSize);
            assert(nameBuffer, "Failed to reallocate memory for nameBuffer");
        }

        currentVnode = vfsLookup(currentVnode, nameBuffer);
        if (currentVnode is null)
        {
            if (mount.next)
                return vfsLazyLookup(mount.next, path);
            kprintf("Invalid path '%s'", path);
            return null;
        }

        if (currentVnode.type != VNODE_DIR)
            break;

        if (*currentPath == '/')
            currentPath++;
    }

    if (*currentPath == '\0' && currentVnode.type == VNODE_DIR)
        return currentVnode;

    return currentVnode;
}

Mount* vfsMount(const(char)* path, const(char)* type)
{
    Mount* current = rootMount;
    while (current !is null)
    {
        assert(current.mountPoint, "Invalid mount point");
        if (strcmp(current.mountPoint, path) == 0)
        {
            kprintf("Mount point '%s' is already in use", path);
            return null;
        }
        current = current.next;
    }

    Vnode* parentVnode = vfsLazyLookup(rootMount, cast(char*) path);
    if (parentVnode is null || parentVnode.type != VNODE_DIR)
    {
        kprintf("Failed to resolve path '%s' or path is not a directory", path);
        return null;
    }

    Mount* newMount = cast(Mount*) kmalloc(Mount.sizeof);
    assert(newMount, "Failed to allocate memory for mount point");

    newMount.root = null;
    newMount.next = null;
    newMount.prev = null;
    newMount.mountPoint = cast(char*) path;
    newMount.type = cast(char*) type;
    newMount.data = null;

    current = rootMount;
    while (current.next !is null)
    {
        current = current.next;
    }
    current.next = newMount;
    newMount.prev = current;

    kprintf("Mounted '%s' with type '%s'", path, type);
    return newMount;
}

Vnode* vfsCreateVnode(Vnode* parent, const(char)* name, uint type)
{
    spinlockAcquire(&parent.lock);
    if (!parent || parent.type != VNODE_DIR)
    {
        kprintf("Invalid parent vnode or parent is not a directory: %s", vfsGetFullPath(parent));
        spinlockRelease(&parent.lock);
        return null;
    }

    if (parent.ops && parent.ops.create)
    {
        Vnode* ret = parent.ops.create(parent, name, type);
        spinlockRelease(&parent.lock);
        return ret;
    }

    kprintf("Create operation not implemented for parent vnode '%s'", vfsGetFullPath(parent));
    spinlockRelease(&parent.lock);
    return null;
}

int vfsRead(Vnode* vnode, void* buf, size_t size, size_t offset)
{
    spinlockAcquire(&vnode.lock);

    if (vnode is null || vnode.type == VNODE_DIR)
    {
        kprintf("Invalid vnode or unsupported type: %s", vfsTypeToStr(vnode ? vnode.type : 0));
        spinlockRelease(&vnode.lock);
        return -1;
    }

    if (vnode.ops && vnode.ops.read)
    {
        int ret = vnode.ops.read(vnode, buf, size, offset);
        spinlockRelease(&vnode.lock);
        return ret;
    }

    kprintf("Read operation not implemented for vnode '%s'", vnode.name);
    spinlockRelease(&vnode.lock);
    return -1;
}

int vfsWrite(Vnode* vnode, const(void)* buf, size_t size, size_t offset)
{
    spinlockAcquire(&vnode.lock);

    if (vnode is null || vnode.type == VNODE_DIR)
    {
        kprintf("Invalid vnode or unsupported type: %s", vfsTypeToStr(vnode ? vnode.type : 0));
        spinlockRelease(&vnode.lock);
        return -1;
    }

    if (vnode.ops && vnode.ops.write)
    {
        int ret = vnode.ops.write(vnode, buf, size, offset);
        spinlockRelease(&vnode.lock);

        vnode.mtime = 0; // todo: Actually update the modification date

        return ret;
    }

    kprintf("Write operation not implemented for vnode '%s'", vnode.name);
    spinlockRelease(&vnode.lock);
    return -1;
}

/* Utilities */
char* vfsGetFullPath(Vnode* node)
{
    return cast(char*) "unknown".ptr;
}

char* vfsTypeToStr(uint type)
{
    switch (type)
    {
    case VNODE_FILE:
        return cast(char*) "FILE".ptr;
    case VNODE_DIR:
        return cast(char*) "DIR".ptr;
    case VNODE_DEV:
        return cast(char*) "DEV".ptr;
    default:
        return cast(char*) "UNKNOWN".ptr;
    }
}
