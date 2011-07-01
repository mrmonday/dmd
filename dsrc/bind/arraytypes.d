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

struct ArrayRaw
{
    // BUG
    byte fixme;
    uint dim;
    void** data;
    uint allocdim;
    void*[1] smallarray;

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

alias ArrayRaw TemplateParametersRaw;
alias ArrayRaw ExpressionsRaw;
alias ArrayRaw StatementsRaw;
alias ArrayRaw BaseClassesRaw;
alias ArrayRaw ClassDeclarationsRaw;
alias ArrayRaw DsymbolsRaw;
alias ArrayRaw ObjectsRaw;
alias ArrayRaw FuncDeclarationsRaw;
alias ArrayRaw ParametersRaw;
alias ArrayRaw IdentifiersRaw;
alias ArrayRaw InitializersRaw;
