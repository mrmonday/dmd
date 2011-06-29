module bind.identifier;

import bind.root;
import bind.util;

extern(C++)
interface Identifier : DmObject
{
    mixin CppFields!(Identifier,
        int, "value",
        const char*, "string_",
        uint, "len"
    );

    mixin CppMethods!(Identifier,
        "equals", int, DmObject,
        "hashCode", hash_t,
        "compare", int, DmObject,
        "print", void,
        "toChars", char*,
        "toHChars", char*,
        "toHChars2", const char*,
        "dyncast", int
    );
    static Identifier *generateId(const char *prefix);
    static Identifier *generateId(const char *prefix, size_t i);
}
mixin(Identifier.cppMethods);
