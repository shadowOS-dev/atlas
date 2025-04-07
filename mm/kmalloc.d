module mm.kmalloc;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 6, 2025
 */

import util.string;

extern (C) extern void* kmalloc(size_t size);
extern (C) extern void* krealloc(void* ptr, size_t size);
extern (C) extern void* kcalloc(size_t num, size_t size);
extern (C) extern void kfree(void* ptr);

/* For classes */
T alloc(T, Args...)(auto ref Args args)
{
    enum tsize = __traits(classInstanceSize, T);
    T t = () @trusted {
        auto _t = cast(T) kmalloc(tsize);
        if (!_t)
            return null;

        memcpy(cast(void*) _t, __traits(initSymbol, T).ptr, tsize);
        return _t;
    }();
    if (!t)
        return null;

    import core.lifetime : forward;

    t.__ctor(forward!args);

    return t;
}

void destroy(T)(ref T t)
{
    static if (__traits(hasMember, T, "__xdtor"))
        t.__xdtor();

    kfree(cast(void*) t);
    static if (__traits(compiles, { t = null; }))
        t = null;
}
