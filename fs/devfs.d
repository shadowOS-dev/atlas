module fs.devfs;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 8, 2025
 */

import util.string;
import dev.vfs;
import lib.log;
import mm.kmalloc;
import lib.lock;

/* Globals */
__gshared Mount* devfsRoot;

/* Structs */
struct Device
{
    int function(void* buf, size_t size, size_t offset) read;
    int function(const(void)* buf, size_t size, size_t offset) write;
}

__gshared VnodeOps devfsOps = VnodeOps(
    &devfsRead,
    &devfsWrite,
    &devfsCreate
);

/* DevFS vnode ops */
int devfsRead(Vnode* node, void* buf, size_t size, size_t offset)
{
    if (!node || node.data is null)
        return -1;
    return (cast(Device*) node.data).read(buf, size, offset);
}

int devfsWrite(Vnode* node, const(void)* buf, size_t size, size_t offset)
{
    if (!node || node.data is null)
        return -1;
    return (cast(Device*) node.data).write(buf, size, offset);
}

Vnode* devfsCreate(Vnode* self, const(char)* name, uint type)
{
    if (vfsLookup(self, name) !is null)
    {
        kprintf(cast(char*) "Could not create vnode '%s' as it already exists", name);
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
    newNode.parent = self;
    newNode.mount = self.mount;
    newNode.flags = 0;
    newNode.size = 0;
    newNode.uid = 0;
    newNode.gid = 0;
    newNode.ctime = 0;
    newNode.atime = 0;
    newNode.mtime = 0;
    newNode.mode = VNODE_MODE_RUSR | VNODE_MODE_WUSR | VNODE_MODE_RGRP | VNODE_MODE_WGRP;
    newNode.data = null;
    newNode.ops = &devfsOps;

    if (self.child is null)
        self.child = newNode;
    else
    {
        Vnode* current = self.child;
        while (current.next !is null)
            current = current.next;
        current.next = newNode;
    }

    return newNode;
}

/* Main logic */
int devfsAddDevice(const char* name, int function(void*, size_t, size_t) readFn, int function(
        const void*, size_t, size_t) writeFn)
{
    if (!name || !readFn || !writeFn)
    {
        kprintf(cast(char*) "Invalid arguments to devfsAddDevice");
        return -1;
    }

    Vnode* node = vfsCreateVnode(devfsRoot.root, name, VNODE_DEV);
    if (!node)
    {
        kprintf(cast(char*) "Failed to create device vnode for '%s'", name);
        return -1;
    }

    node.ops = &devfsOps;

    Device* device = cast(Device*) kmalloc(Device.sizeof);
    if (!device)
    {
        kprintf(cast(char*) "Failed to allocate memory for device '%s'", name);
        vfsDeleteNode(node);
        return -1;
    }

    device.read = readFn;
    device.write = writeFn;
    node.data = device;

    kprintf(cast(char*) "Device '%s' successfully added to devfs", name);
    return 0;
}

void devfsInit()
{
    Vnode* devDir = vfsCreateVnode(rootMount.root, "dev", VNODE_DIR);
    assert(devDir);
    devDir.flags = VNODE_FLAG_MOUNTPOINT;

    Mount* mount = vfsMount("/dev", "devfs");
    if (!mount)
    {
        kprintf(cast(char*) "Failed to mount devfs at /dev");
        return;
    }

    devfsRoot = mount;
    devfsRoot.root = devDir;
    devDir.mount = mount;

    kprintf(cast(char*) "devfs initialized at /dev");
}
