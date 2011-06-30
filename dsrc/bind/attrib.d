module bind.attrib;

import bind.arraytypes;
import bind.dsymbol;
import bind.mars;
import bind.util;

interface Statement {}
interface LabelDsymbol {}
interface Initializer {}
interface Condition {}
interface HdrGenState {}

interface AttribDeclaration : Dsymbol
{
    mixin CppFields!(AttribDeclaration,
        Dsymbols, "decl"     // array of Dsymbol's
    );
}

interface StorageClassDeclaration: AttribDeclaration
{
}

interface LinkDeclaration : AttribDeclaration
{
    mixin CppFields!(LinkDeclaration,
        LINK, "linkage"
    );
}

interface ProtDeclaration : AttribDeclaration
{
}

interface AlignDeclaration : AttribDeclaration
{
}

interface AnonDeclaration : AttribDeclaration
{
}

interface PragmaDeclaration : AttribDeclaration
{
}

interface ConditionalDeclaration : AttribDeclaration
{
}

interface StaticIfDeclaration : ConditionalDeclaration
{
}

interface CompileDeclaration : AttribDeclaration
{
}

