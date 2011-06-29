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
        //static if (is(p t : t*))
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
    //pragma(msg, CppMethodsImpl!(I, 1, T));
    mixin(CppMethodsImpl!(I, 1, T)[0] ~ `enum cppMethods = q{` ~ CppMethodsImpl!(I, 1, T)[1] ~ `};`);
}
template TypeTuple(T...)
{
    alias T TypeTuple;
}
template CppMethodsImpl(I, size_t i, T...)
{
    //alias PopAtString!(i, 0, 0, 0, T) pas;
        //pragma(msg, "pas: " ~ PopAtString!(i, 0, 0, 0, T).stringof);
    static if (is(PopAtString!(i, 0, 0, 0, T) == TypeTuple!()))
    {
        /*pragma(msg, I.stringof);
        pragma(msg, i.stringof);
        pragma(msg, T.stringof);
        pragma(msg, "null: " ~ typeof(TypeTuple!("", "")).stringof);*/
        alias TypeTuple!("", "") CppMethodsImpl;
    }
    else
    {
        /*static if (is(typeof(CppMethodsImpl!(I, i + 1, T)) == void))
        {
            enum CppMethodsImpl = CppMethod!(I, pas);
            //pragma(msg, "moomin: " ~ CppMethodsImpl!(I, i + 1, T).stringof);
        }
        else
        {*/
            /*pragma(msg, "moo: " ~ CppMethodsImpl!(I, i + 1, T).stringof);
            pragma(msg, "moo: " ~ CppMethod!(I, pas)[1]);*/
            alias TypeTuple!(CppMethod!(I, PopAtString!(i, 0, 0, 0, T))[0] ~ CppMethodsImpl!(I, i + 1, T)[0],
                             CppMethod!(I, PopAtString!(i, 0, 0, 0, T))[1] ~ CppMethodsImpl!(I, i + 1, T)[1])
                  CppMethodsImpl;
        //}
    }
}



/// i = # strings before done
/// j = # strings encountered
/// a = last non-string index
/// b = current index
template PopAtString(size_t i, size_t j, size_t a, size_t b, T...)
{
    /*pragma(msg, "i: " ~ i.stringof);
    pragma(msg, "j: " ~ j.stringof);
    pragma(msg, "a: " ~ a.stringof);
    pragma(msg, "b: " ~ b.stringof);
   // pragma(msg, "T: " ~ T.stringof);
    pragma(msg, "T[b]: " ~ T[b].stringof);*/
    static if (is(typeof(T[b] == string)) && is(typeof({ string _ = T[b]; }())))
    {
       /* pragma(msg, "we has a string");
        pragma(msg, "i: " ~ i.stringof);
        pragma(msg, "j: " ~ j.stringof);
        pragma(msg, "i == j: " ~ (i == j).stringof);*/
        static if (i == j)
        {
        //pragma(msg, "all our i's and j's are belong to us");
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
                //pragma(msg, "fail2");
                alias TypeTuple!() PopAtString;
            }
            else
            {
                //pragma(msg, "beans");
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
    //pragma(msg, "Getting offset: "  ~ I.stringof);
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
            enum GetOffset = (void*).sizeof + ParentOffset!(I);
        }
    }
    else
    {
        enum GetOffset = I.sizeof;
    }
}

template ParentOffset(T) if (is(T == interface))
{
    //pragma(msg, "GETTING OFFSET: "~T.stringof);
    static if (is(typeof({ enum _ = T._cpp_offset; }())))
    {
        //pragma(msg, "cpp offs: " ~ T._cpp_offset.stringof);
        enum ParentOffset = T._cpp_offset;
    }
    else static if (BaseTypeTuple!(T).length == 1)
    {
        //pragma(msg, "base offs: " ~ ParentOffset!(BaseTypeTuple!T).stringof);
        enum ParentOffset = ParentOffset!(BaseTypeTuple!T);
    }
    else
    {
        //pragma(msg, "ZERO OFFSET: "~T.stringof);
        enum ParentOffset = 0;
    }
}

template CppFieldsImpl(size_t offset, T...) if (T.length % 2 == 0)
{
    static if (T.length == 2)
    {
        //pragma(msg, "offset: " ~ offset.stringof);
        enum CppFieldsImpl = CppField!(T[0..2], offset) ~ `
        enum _cpp_offset = ` ~ offset.stringof ~ `;`;
    }
    else
    {
        //enum CppFieldsImpl = CppField!(T[0..2], offset) ~ CppFieldsImpl!(offset + CppSizeOf!(T[0]), T[2..$]);
        //pragma(msg, T[1] ~ ": " ~ offset.stringof);
        enum CppFieldsImpl = CppField!(T[0..2], offset) ~ CppFieldsImpl!(offset + T[0].sizeof/*GetOffset!(T[0])*/, T[2..$]);
    }
}

// This is required to get the correct offset
/*template hasCppOffset(T)
{
    static if (is(typeof({ enum _ = T._cpp_offset; }())))
    {
        enum hasCppOffset = true;
    }
    else
    {
        enum hasCppOffset = false;
    }
    //enum hasCppOffset = hasCppOffsetImpl!(__traits(derivedMembers, T));
}*/
/*
template hasCppOffsetImpl(T...)
{
    static if (T.length == 1)
    {
        static if (T[0] == "_cpp_offset")
        {
            enum hasCppOffsetImpl = true;
        }
        else
        {
            enum hasCppOffsetImpl = false;
        }
    }
    else static if (T.length == 0)
    {
        enum hasCppOffsetImpl = 0;
    }
    else
    {
        enum hasCppOffsetImpl = hasCppOffsetImpl!(T[0]) && hasCppOffsetImpl!(T[1..$]);
    }
}*/

template CppField(T, string name, size_t offset)
{
    //pragma(msg, T.stringof ~ ": " ~ name ~ ": " ~ offset.stringof);
    //static assert(name != "frequire");
    enum CppField = `import std.stdio;extern(D)final ` ~ T.stringof ~ ` ` ~ name ~ `() @property
    {
        //asm { int 3; }
        //auto t = cast(typeof(this))this;
        //writefln("`~name~` cast &this: %x", cast(void*)&t);
        //writefln("`~name~` &this: %x", cast(void*)&this);
        //writefln("`~name~` this: %x", cast(void*)this);
        return *(cast(` ~ T.stringof ~ `*)(cast(void*)this + ` ~ offset.stringof ~ `));
    }
    /*
    final void ` ~ name ~ `(` ~ T.stringof ~ ` _) @property
    {
        // BUG This probably doesn't work.
        *cast(` ~ T.stringof ~ `*)(cast(void*)this + ` ~ offset.stringof ~ `) = _;
    }*/
    `;
    /*static if (name == "loc") pragma(msg, name ~ " offset: " ~ offset.stringof ~ " sizeof: " ~ T.sizeof.stringof);
    static if (name == "op") pragma(msg, name ~ " offset: " ~ offset.stringof~ " sizeof: " ~ T.sizeof.stringof);
    static if (name == "type") pragma(msg, name ~ " offset: " ~ offset.stringof~ " sizeof: " ~ T.sizeof.stringof);
    static if (name == "size") pragma(msg, name ~ " offset: " ~ offset.stringof~ " sizeof: " ~ T.sizeof.stringof);
    static if (name == "parens") pragma(msg, name ~ " offset: " ~ offset.stringof~ " sizeof: " ~ T.sizeof.stringof);
    static if (name == "e1") pragma(msg, name ~ " offset: " ~ offset.stringof~ " sizeof: " ~ T.sizeof.stringof);*/
}

