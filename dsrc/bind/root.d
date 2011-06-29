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
/*
    void *extractData();
    void mark();

    void reserve(unsigned nbytes);
    void setsize(unsigned size);
    void reset();
    void write(const void *data, unsigned nbytes);
    void writebstring(unsigned char *string);
    void writestring(const char *string);
    void writedstring(const char *string);
    void writedstring(const wchar_t *string);
    void prependstring(const char *string);
    void writenl();                     // write newline
    void writeByte(unsigned b);
    void writebyte(unsigned b) { writeByte(b); }
    void writeUTF8(unsigned b);
    void writedchar(unsigned b);
    void prependbyte(unsigned b);
    void writeword(unsigned w);
    void writeUTF16(unsigned w);
    void write4(unsigned w);
    void write(OutBuffer *buf);
    void write(Object *obj);
    void fill0(unsigned nbytes);
    void align(unsigned size);
    void vprintf(const char *format, va_list args);
    void printf(const char *format, ...);
#if M_UNICODE
    void vprintf(const unsigned short *format, va_list args);
    void printf(const unsigned short *format, ...);
#endif
    void bracket(char left, char right);
    unsigned bracket(unsigned i, const char *left, unsigned j, const char *right);
    void spread(unsigned offset, unsigned nbytes);
    unsigned insert(unsigned offset, const void *data, unsigned nbytes);
    void remove(unsigned offset, unsigned nbytes);
    char *toChars();
    char *extractString();
    */
}
