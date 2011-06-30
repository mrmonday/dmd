module bind.init;

import bind.arraytypes;
import bind.expression;
import bind.mars;
import bind.mtype;
import bind.root;
import bind.util;

interface Initializer : DmObject
{
    mixin CppFields!(Initializer,
        Loc, "loc"
    );
}

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
