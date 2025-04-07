module object;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

import mm.kmalloc;
import util.string;

alias size_t = typeof(int.sizeof);
alias string = immutable(char)[];

/* Classes */
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
