module bind.arraytypes;

import bind.root;

extern(C++):

interface TemplateParameters : Array {}
interface Expressions : Array {}
interface Statements : Array {}
interface BaseClasses : Array {}
interface ClassDeclarations : Array {}
interface Dsymbols : Array {}
interface Objects : Array {}
interface FuncDeclarations : Array {}
interface Parameters : Array {}
interface Identifiers : Array {}
interface Initializers : Array {}

struct FuncDeclarationsRaw
{
        uint dim;
        void** data;
        uint allocdim;
        void*[1] smallarray;
        byte fixme;
}
