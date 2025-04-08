module fs.ramfs;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 7, 2025
 */

import util.string;
import dev.vfs;
import lib.log;
import mm.kmalloc;
import lib.lock;

/* Defines */
enum RAMFS_TYPE_USTAR = 0x1;

/* Structs */
struct RAMFSData
{
    void* data;
    size_t size;
}

struct USTAR
{
    char[100] name;
    char[8] mode;
    char[8] uid;
    char[8] gid;
    char[12] size;
    char[12] mtime;
    char[8] checksum;
    char typeflag;
    char[100] linkname;
    char[6] magic;
    char[2] _version;
    char[32] uname;
    char[32] gname;
    char[8] devmajor;
    char[8] devminor;
    char[155] prefix;
    char[12] padding;
}

VnodeOps ramfsOps = VnodeOps(
    &ramfsRead,
    &ramfsWrite,
    &ramfsCreate
);

/* Ramfs vnode ops */
int ramfsRead(Vnode* node, void* buf, size_t size, size_t offset)
{
    if (!node || node.type != VNODE_FILE)
    {
        kprintf(cast(char*) "Invalid vnode or not a file");
        return -1;
    }
    RAMFSData* data = cast(RAMFSData*) node.data;
    if (!data || offset >= data.size)
    {
        kprintf(cast(char*) "Invalid offset for read operation");
        return 0;
    }

    size_t toRead = size > (data.size - offset) ? (data.size - offset) : size;
    if (!buf)
    {
        kprintf(cast(char*) "Buffer is NULL");
        return -1;
    }

    memcpy(buf, data.data + offset, toRead);
    return cast(int) toRead;
}

int ramfsWrite(Vnode* node, const void* buf, size_t size, size_t offset)
{
    if (!node || node.type != VNODE_FILE)
    {
        kprintf(cast(char*) "Invalid vnode or not a file");
        return -1;
    }

    auto data = cast(RAMFSData*) node.data;
    if (!data)
    {
        kprintf(cast(char*) "Invalid data for write operation");
        return -1;
    }

    if (offset >= data.size)
    {
        size_t newSize = offset + size;
        if (newSize > data.size)
        {
            void* newData = kmalloc(newSize);
            if (!newData)
            {
                kprintf(cast(char*) "Failed to allocate memory for expanding the file data");
                return -1;
            }

            memcpy(newData, data.data, data.size);
            kfree(data.data);
            data.data = newData;
            data.size = newSize;
            node.size = newSize;
            kprintf(cast(char*) "Resized file data buffer to %lu bytes", newSize);
        }
    }

    if (!buf)
    {
        kprintf(cast(char*) "Buffer is NULL");
        return -1;
    }

    memcpy(data.data + offset, buf, size);
    node.size = (node.size > offset + size) ? node.size : (offset + size);
    data.size = node.size;
    return cast(int) size;
}

Vnode* ramfsCreate(Vnode* self, const char* name, uint type)
{
    if (!name || vfsLookup(self, name) !is null)
    {
        kprintf(cast(char*) "Could not create vnode '%s' as it already exists or invalid name", name);
        return null;
    }

    Vnode* newNode = cast(Vnode*) kmalloc(Vnode.sizeof);
    if (!newNode)
    {
        kprintf(cast(char*) "Failed to allocate memory for new vnode");
        return null;
    }

    memset(newNode, 0, Vnode.sizeof);
    newNode.name = strdup(name);
    newNode.type = type;

    newNode.child = null;
    newNode.next = null;
    newNode.parent = self;
    newNode.mount = self.mount;
    newNode.flags = 0;
    newNode.size = 0;
    newNode.uid = 0;
    newNode.gid = 0;
    newNode.ctime = 0;
    newNode.atime = 0;
    newNode.mtime = 0;

    newNode.mode = (type != VNODE_DEV)
        ? (VNODE_MODE_RUSR | VNODE_MODE_WUSR | VNODE_MODE_RGRP | VNODE_MODE_ROTH) : (
            VNODE_MODE_RUSR | VNODE_MODE_WUSR | VNODE_MODE_RGRP);

    RAMFSData* data = cast(RAMFSData*) kmalloc(RAMFSData.sizeof);
    if (!data)
    {
        kprintf(cast(char*) "Failed to allocate memory for ramfs data");
        kfree(newNode);
        return null;
    }

    memset(data, 0, RAMFSData.sizeof);
    newNode.data = data;
    newNode.ops = cast(VnodeOps*) kmalloc(VnodeOps.sizeof);
    newNode.ops.write = &ramfsWrite;
    newNode.ops.read = &ramfsRead;
    newNode.ops.create = &ramfsCreate;

    if (self.child is null)
    {
        self.child = newNode;
    }
    else
    {
        Vnode* current = self.child;
        while (current.next !is null)
            current = current.next;
        current.next = newNode;
    }

    return newNode;
}

/* Generic ramfs functions */
void ramfsInitUstar(Mount* mount, void* rawData, size_t size)
{
    assert(mount);
    assert(rawData);
    assert(size >= 512);

    size_t offset = 0;
    while (offset < size)
    {
        auto header = cast(USTAR*)(rawData + offset);
        assert(header);
        if (header.name[0] == '\0')
        {
            break;
        }

        uint fileSize = cast(uint) strtol(cast(char*) header.size.ptr, null, 8);
        bool isDir = header.typeflag == '5';
        char* name = cast(char*) header.name.ptr;

        if (strncmp(name, "./", 2) == 0)
            name += 2;

        if (strlen(name) == 0 || strcmp(name, ".") == 0)
        {
            kprintf(cast(char*) "Skipping entry with empty name or current directory '.'");
            offset += 512 + ((fileSize + 511) & ~511);
            continue;
        }

        kprintf(cast(char*) "Found entry: name=%s, size=%u, mode=%o, dir=%d",
            name, fileSize, strtol(cast(char*) header.mode.ptr, null, 8), isDir);

        auto tokens = stringSplit(name, '/');
        Vnode* curParent = mount.root;

        size_t tokLen = tokensLength(tokens);
        foreach (i, token; tokens[0 .. tokLen - 1])
        {
            auto sub = vfsLookup(curParent, token);
            if (!sub)
            {
                if (isDir)
                {
                    auto node = vfsCreateVnode(curParent, token, VNODE_DIR);
                    if (!node)
                    {
                        kprintf(cast(char*) "Failed to create directory '%s'", token);
                        return;
                    }
                    node.ops = cast(VnodeOps*) kmalloc(VnodeOps.sizeof);
                    node.ops.write = &ramfsWrite;
                    node.ops.read = &ramfsRead;
                    node.ops.create = &ramfsCreate;
                    node.mode = cast(uint) strtol(cast(char*) header.mode.ptr, null, 8);
                    node.ctime = cast(uint) strtol(cast(char*) header.mtime.ptr, null, 8);
                    sub = node;
                }
                else
                {
                    break;
                }
            }
            curParent = sub;
        }

        if (!isDir)
        {
            auto filename = tokens[tokLen - 1];
            if (strlen(filename) > 0)
            {
                auto file = vfsCreateVnode(curParent, filename, VNODE_FILE);
                if (!file)
                {
                    kprintf(cast(char*) "Failed to create file '%s'", filename);
                    return;
                }

                auto ramfsData = cast(RAMFSData*) kmalloc(RAMFSData.sizeof);
                if (!ramfsData)
                {
                    kprintf(cast(char*) "Failed to allocate memory for ramfs data");
                    return;
                }

                ramfsData.data = kmalloc(fileSize);
                if (!ramfsData.data)
                {
                    kprintf(cast(char*) "Failed to allocate memory for file data");
                    kfree(ramfsData);
                    return;
                }

                memcpy(ramfsData.data, cast(ubyte*) header + 512, fileSize);
                ramfsData.size = fileSize;

                file.ops = cast(VnodeOps*) kmalloc(VnodeOps.sizeof);
                file.ops.write = &ramfsWrite;
                file.ops.read = &ramfsRead;
                file.ops.create = &ramfsCreate;
                file.data = cast(void*) ramfsData;
                file.size = fileSize;
                file.mode = cast(uint) strtol(cast(char*) header.mode.ptr, null, 8);
                file.ctime = cast(uint) strtol(cast(char*) header.mtime.ptr, null, 8);
            }
        }

        offset += 512 + ((fileSize + 511) & ~511);
    }
}

void ramfsInit(Mount* mount, int type, void* data, size_t size)
{
    assert(mount);
    mount.root.ops = cast(VnodeOps*) kmalloc(VnodeOps.sizeof);
    mount.root.ops.write = &ramfsWrite;
    mount.root.ops.read = &ramfsRead;
    mount.root.ops.create = &ramfsCreate;

    switch (type)
    {
    case RAMFS_TYPE_USTAR:
        ramfsInitUstar(mount, data, size);
        break;
    default:
        kprintf(cast(char*) "Unsupported ramfs type: %d", type);
        return;
    }

    assert(mount);
}
