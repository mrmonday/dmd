module bind.init;

import bind.arraytypes;
import bind.expression;
import bind.hdrgen;
import bind.mars;
import bind.mtype;
import bind.root;
import bind.scope_;
import bind.util;

import duffer;

import std.conv;
import std.stdio;

extern(C++):

interface Initializer : DmObject
{
    mixin CppFields!(Initializer,
        Loc, "loc"
    );
    void foo();
    void bar();

    Initializer syntaxCopy();
    // needInterpret is WANTinterpret if must be a manifest constant, 0 if not.
    Initializer semantic(Scope sc, Type t, int needInterpret);
    Type inferType(Scope sc);
    Expression toExpression();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);


    void* toDt();
    //dt_t *toDt();

    VoidInitializer isVoidInitializer();
    StructInitializer isStructInitializer();
    ArrayInitializer isArrayInitializer();
    ExpInitializer isExpInitializer();

    final void toJsBuffer(Duffer buf)
    {
        if (auto ei = isExpInitializer())
        {
            initToJsBuffer(ei, buf);
        }
        else
        {
            assert(0, "unhandled initializer " ~ to!string(toTypeString(this)));
        }
    }
}

const(char*) toTypeString(Initializer);
void initToJsBuffer(ExpInitializer, Duffer);

interface VoidInitializer : Initializer
{
    mixin CppFields!(VoidInitializer,
        Type, "type"         // type that this will initialize to
    );
}

interface StructInitializer : Initializer
{
}

interface ArrayInitializer : Initializer
{
}

interface ExpInitializer : Initializer
{
    mixin CppFields!(ExpInitializer,
        Expression, "exp"
    );
}
