module bind.util;

import std.traits;

template CppMethod(I, string name, R, P...) if (is(I == interface))
{
    //pragma(msg, CppMethodImpl!(I, R, name, I, P));
    alias CppMethodImpl!(I, R, name, I, P) CppMethod;
}

template CppMethodImpl(I, R, string name, P...)
{
    static if (P.length == 1)
    {
        alias TypeTuple!(`final ` ~ R.stringof ~ ` ` ~ name ~ `()
                          {
                              static assert(is(typeof(` ~ CppMangle!(I, name, P[1..$]) ~`)),
                                            "Method ` ~ name ~ ` not found, did you forget to place "
                                            "mixin(` ~ I.stringof ~ `.cppMethods) outside the interface?");
                              return ` ~ CppMangle!(I, name, P[1..$]) ~ `(this);
                          }`,
                        `extern(C) ` ~ R.stringof ~ ` ` ~ CppMangle!(I, name, P[1..$]) ~ P.stringof ~ `;`)
                CppMethodImpl;
    }
    else
    {
        alias TypeTuple!(`final ` ~ R.stringof ~ ` ` ~ name ~ `(T...)(T params)
                          {
                              static assert(is(typeof(` ~ CppMangle!(I, name, P[1..$]) ~`)),
                                            "Method ` ~ name ~ ` not found, did you forget to place "
                                            "mixin(` ~ I.stringof ~ `.cppMethods) outside the interface?");
                              return ` ~ CppMangle!(I, name, P[1..$]) ~ `(this, params);
                          }`,
                        `extern(C) ` ~ R.stringof ~ ` ` ~ CppMangle!(I, name, P[1..$]) ~ P.stringof ~ `;`)
                CppMethodImpl;
    }
}

template CppMangle(I, string name, P...)
{
    enum CppMangle = "_ZN" ~ I.stringof.length.stringof[0..$-1] ~ I.stringof
                           ~ name.length.stringof[0..$-1] ~ name
                           ~ 'E' ~ CppMangleParams!P;
}

template CppMangleParams(P...)
{
    static if (P.length == 0)
    {
        enum CppMangleParams = "v";
    }
    else static if (P.length == 1)
    {
        static if (is(P[0] == const))
        {
            enum CppMangleParams = "K" ~ CppMangleType!(P[0]);
        }
        else
        {
            enum CppMangleParams = CppMangleType!(P[0]);
        }
    }
    else
    {
        enum CppMangleParams = CppMangleParams!(P[0]) ~ CppMangleParams!(P[1..$]);
    }
}

template CppMangleType(T : T*)
{
    enum CppMangleType = "P" ~ CppMangleType!T;
}

template CppMangleType(T)
{
    static if (is(T == void))
    {
        enum CppMangleType = "v";
    }
    else static if (is(T == int))
    {
        enum CppMangleType = "i";
    }
    else static if (is(T == uint))
    {
        enum CppMangleType = "j";
    }
    else static if (is(T == ubyte))
    {
        enum CppMangleType = "h";
    }
    else static if (is(T == struct))
    {
        enum CppMangleType = "S_";
    } 
    else static if (is(T == interface))
    {
        enum CppMangleType = "PS_";
    }
    else
    {
        static assert(0, "Unimplemented mangle for type: " ~ T.stringof);
    }
}

mixin template CppMethods(I, T...)
{
    mixin(CppMethodsImpl!(I, 1, T)[0] ~ `enum cppMethods = q{` ~ CppMethodsImpl!(I, 1, T)[1] ~ `};`);
}
template TypeTuple(T...)
{
    alias T TypeTuple;
}
template CppMethodsImpl(I, size_t i, T...)
{
    static if (is(PopAtString!(i, 0, 0, 0, T) == TypeTuple!()))
    {
        alias TypeTuple!("", "") CppMethodsImpl;
    }
    else
    {
        alias TypeTuple!(CppMethod!(I, PopAtString!(i, 0, 0, 0, T))[0] ~ CppMethodsImpl!(I, i + 1, T)[0],
                         CppMethod!(I, PopAtString!(i, 0, 0, 0, T))[1] ~ CppMethodsImpl!(I, i + 1, T)[1])
              CppMethodsImpl;
    }
}



/// i = # strings before done
/// j = # strings encountered
/// a = last non-string index
/// b = current index
template PopAtString(size_t i, size_t j, size_t a, size_t b, T...)
{
    static if (is(typeof(T[b] == string)) && is(typeof({ string _ = T[b]; }())))
    {
        static if (i == j)
        {
            alias TypeTuple!(T[a..b]) PopAtString;
        }
        else
        {
            static if (b + 1 < T.length)
            {
                alias PopAtString!(i, j + 1, b, b + 1, T) PopAtString;
            }
            else
            {
                static assert(0);
                alias TypeTuple!() PopAtString;
            }
        }
    }
    else
    {
        static if (b + 1 < T.length)
        {
            alias PopAtString!(i, j, a, b + 1, T) PopAtString;
        }
        else
        {
            static if (j < i)
            {
                alias TypeTuple!() PopAtString;
            }
            else
            {
                alias TypeTuple!(T[a..b+1]) PopAtString;
            }
        }
    }
}

//pragma(msg, "test: " ~ PopAtString!(1, 0, 0, 0, "bar", int).stringof);
//pragma(msg, "test: " ~ PopAtString!(1, 0, 0, 0, "foo", int, string).stringof);
//pragma(msg, "test: " ~ PopAtString!(2, 0, 0, 0, "foo", int, string, "bar", void).stringof);
//pragma(msg, "test: " ~ PopAtString!(1, 0, 0, 0, "foo", int, "bar", void*, void*).stringof);

// Also needs to check for no prior usage
mixin template CppFields(I, T...) if (T.length % 2 == 0 /* Needs to check linkage too */)
{
    mixin(CppFieldsImpl!(GetOffset!I, T));
}

template GetOffset(I) //if (is(I == interface))
{
    static if (is(I == interface))
    {
        static if (BaseTypeTuple!(I).length == 0)
        {
            enum GetOffset = (void*).sizeof;
        }
        else static if(BaseTypeTuple!(I).length > 1)
        {
            static assert(0);
        }
        else
        {
            enum GetOffset = ParentOffset!(I);
        }
    }
    else
    {
        enum GetOffset = I.sizeof;
    }
}

template ParentOffset(T) if (is(T == interface))
{
    static if (is(typeof({ enum _ = T._cpp_offset; }())))
    {
        enum ParentOffset = T._cpp_offset;
    }
    else static if (BaseTypeTuple!(T).length == 1)
    {
        enum ParentOffset = ParentOffset!(BaseTypeTuple!T);
    }
    else
    {
        enum ParentOffset = (void*).sizeof;
    }
}

template Align(size_t offset)
{
    static if (offset % (void*).sizeof == 0)
        enum Align = offset;
    else
        enum Align = offset + offset % (void*).sizeof;
}

template CppFieldsImpl(size_t offset, T...) if (T.length % 2 == 0)
{
    static if (T.length == 2)
    {
        enum CppFieldsImpl = CppField!(T[0..2], offset) ~ `
                             enum _cpp_offset = ` ~ Align!(offset + T[0].sizeof).stringof ~ `;`;
    }
    else
    {
        enum CppFieldsImpl = CppField!(T[0..2], offset) ~ CppFieldsImpl!(offset + T[0].sizeof/*GetOffset!(T[0])*/, T[2..$]);
    }
}

template CppField(T, string name, size_t offset)
{
    //pragma(msg, T.stringof ~ ": " ~ name ~ ": " ~ offset.stringof);
    //static if (name == "inuse")pragma(msg, name ~ " offset: " ~ offset.stringof ~ " sizeof: " ~ T.sizeof.stringof);
    enum CppField = `import std.stdio;extern(D)final ` ~ T.stringof ~ ` ` ~ name ~ `() @property
    {
        return *(cast(` ~ T.stringof ~ `*)(cast(void*)this + ` ~ offset.stringof ~ `));
    }
    /*
    final void ` ~ name ~ `(` ~ T.stringof ~ ` _) @property
    {
        // BUG This probably doesn't work.
        *cast(` ~ T.stringof ~ `*)(cast(void*)this + ` ~ offset.stringof ~ `) = _;
    }*/
    `;
}

