module bind.mtype;

import bind.root;

extern(C++):

interface Type : DmObject
{
}

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
