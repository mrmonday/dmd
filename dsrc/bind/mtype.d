module bind.mtype;

import bind.dsymbol;
import bind.hdrgen;
import bind.identifier;
import bind.mars;
import bind.root;
import bind.scope_;
import bind.util;

extern(C++):

struct CppMangleState;

interface Type : DmObject
{
    mixin CppMethods!(Type,
        "toChars", char*
    );
    void foo();
    void bar();
    
    Type syntaxCopy();
    ulong size(Loc loc);
    uint alignsize();
    Type semantic(Loc loc, Scope sc);
    void toDecoBuffer(OutBuffer buf, int flag = 0);
    void toCBuffer(OutBuffer buf, Identifier ident, HdrGenState *hgs);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    void toCppMangle(OutBuffer buf, CppMangleState cms);
    int isintegral();
    int isfloating();   // real, imaginary, or complex
    int isreal();
    int isimaginary();
    int iscomplex();
    int isscalar();
    int isunsigned();
    int isscope();
    int isString();
    int isAssignable();
    int checkBoolean(); // if can be converted to boolean value
    void checkDeprecated(Loc loc, Scope sc);
    Type makeConst();
    Type makeInvariant();
    Type makeShared();
    Type makeSharedConst();
    Type makeWild();
    Type makeSharedWild();
    Type makeMutable();
    // BUG Missing rest
}
mixin(Type.cppMethods);

interface TypeNext : Type
{
}

enum RET
{
    RETregs     = 1,    // returned in registers
    RETstack    = 2,    // returned on stack
}

enum TRUST
{
    TRUSTdefault = 0,
    TRUSTsystem = 1,    // @system (same as TRUSTdefault)
    TRUSTtrusted = 2,   // @trusted
    TRUSTsafe = 3,      // @safe
}

enum PURE
{
    PUREimpure = 0,     // not pure at all
    PUREweak = 1,       // no mutable globals are read or written
    PUREconst = 2,      // parameters are values or const
    PUREstrong = 3,     // parameters are values or immutable
    PUREfwdref = 4,     // it's pure, but not known which level yet
}

interface TypeFunction : TypeNext
{
}

interface Parameter : DmObject
{
}
