module bind.root;

import bind.util;

extern(C++)
struct Symbol
{
}

extern(C++)
interface DmObject
{
    int equals(DmObject o);
    hash_t hashCode();
    int compare(DmObject obj);
    void print();
    char* toChars();
    dchar* toDchars();
    void toBuffer(OutBuffer buf);
    int dyncast();
    mixin CppMethods!(DmObject,
        "mark", void
    );
}
mixin(DmObject.cppMethods);

import std.stdio;
extern(C++)
interface Array : DmObject
{
    mixin CppFields!(Array,
        uint, "dim",
        void**, "data",
        uint, "allocdim",
        void*[1], "smallarray"
    );
    mixin CppMethods!(Array,
        "mark", void,
        "toChars", char*,

        "reserve", void, uint,
        "setDim", void, uint,
        "fixDim", void,
        "push", void, void*,
        "pop", void*,
        "shift", void, void*,
        "insert", void, uint, void*,
        "insert", void, uint, Array,
        "append", void, Array,
        "remove", void, uint,
        "zero", void,
        "tos", void*,
        "sort", void,
        "copy", Array
    );

    // Convinience method for iteration
    extern(D) final int opApply(T)(int delegate(ref T) dg)
    {
        //writefln("dim: %s", dim);
        for (uint i = 0; i < dim; i++)
        {
            //writefln("dim: %s", i);
            auto d = cast(T)data[i];
            if (auto result = dg(d))
            {
                return result;
            }
        }
        return 0;
    }
}
mixin(Array.cppMethods);

extern(C++)
interface OutBuffer : DmObject
{
    mixin CppFields!(OutBuffer,
        ubyte*, "data",
        uint, "offset",
        uint, "size"
    );
}
