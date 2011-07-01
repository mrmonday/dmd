module bind.aggregate;

import bind.arraytypes;
import bind.declaration;
import bind.dsymbol;
import bind.mars;
import bind.mtype;
import bind.root;
import bind.util;

extern(C++):

interface Identifier {}
interface TypeFunction {}
interface CtorDeclaration {}
interface DtorDeclaration {}
interface InvariantDeclaration {}
interface NewDeclaration {}
interface DeleteDeclaration {}
interface TypeInfoClassDeclaration {}
interface dt_t {}


interface AggregateDeclaration : ScopeDsymbol
{
    mixin CppFields!(AggregateDeclaration,
        Type, "type",
        StorageClass, "storage_class",
        PROT, "protection",
        Type, "handle",               // 'this' type
        uint, "interfacesize",        // size of struct
        uint, "alignsize",         // size of interface for alignment purposes
        uint, "interfacealign",       // struct member alignment in effect
        int, "hasUnions",              // set if aggregate has overlapping fields
        ArrayRaw, "fields",               // VarDeclaration fields
        uint, "sizeok",            // set when interfacesize contains valid data
                                    // 0: no size
                                    // 1: size is correct
                                    // 2: cannot determine size, fwd referenced
        Dsymbol, "deferred",          // any deferred semantic2() or semantic3() symbol
        int, "isdeprecated",           // !=0 if deprecated

        int, "isnested",               // !=0 if is nested
        VarDeclaration, "vthis",      // 'this' parameter if this aggregate is nested
        // Special member functions
        InvariantDeclaration, "inv",          // invariant
        NewDeclaration, "aggNew",             // allocator
        DeleteDeclaration, "aggDelete",       // deallocator

        Dsymbol, "ctor",                      // CtorDeclaration or TemplateDeclaration
        CtorDeclaration, "defaultCtor",       // default coninterfaceor
        Dsymbol, "aliasthis",                 // forward unresolved lookups to aliasthis

        FuncDeclarationsRaw, "dtors",     // Array of deinterfaceors
        FuncDeclaration, "dtor"      // aggregate deinterfaceor
    );
}

interface AnonymousAggregateDeclaration : AggregateDeclaration
{
}

interface StructDeclaration : AggregateDeclaration
{
}

interface UnionDeclaration : StructDeclaration
{
}

struct BaseClass
{
    Type type;                         // (before semantic processing)
    PROT protection;               // protection for the base interface

    ClassDeclaration base;
    int offset;                         // 'this' pointer offset
    ArrayRaw vtbl;                         // for interfaces: Array of FuncDeclaration's
                                        // making up the vtbl[]

    int baseInterfaces_dim;
    BaseClass* baseInterfaces;          // if BaseClass is an interface, these
                                        // are a copy of the InterfaceDeclaration::interfaces
}

enum CLASSINFO_SIZE_64 = 0x98;         // value of ClassInfo.size
enum CLASSINFO_SIZE    = 0x3C+12+4;   // value of ClassInfo.size

interface ClassDeclaration : AggregateDeclaration
{
    /*static ClassDeclaration *object;
    static ClassDeclaration *classinfo;
    static ClassDeclaration *throwable;
    static ClassDeclaration *exception;*/

    mixin CppFields!(ClassDeclaration,
        ClassDeclaration, "BUG",
        ClassDeclaration, "BUG2",
        ClassDeclaration, "baseClass",        // NULL only if this is Object
        FuncDeclaration, "staticCtor",
        FuncDeclaration, "staticDtor",
        ArrayRaw, "vtbl",                         // Array of FuncDeclaration's making up the vtbl[]
        ArrayRaw, "vtblFinal",                    // More FuncDeclaration's that aren't in vtbl[]

        BaseClasses, "baseclasses",           // Array of BaseClass's; first is super,
                                            // rest are Interface's

        int, "interfaces_dim",
        BaseClass**, "interfaces",             // interfaces[interfaces_dim] for this class
                                            // (does not include baseClass)

        BaseClasses, "vtblInterfaces",        // array of base interfaces that have
                                            // their own vtbl[]

        TypeInfoClassDeclaration, "vclassinfo",       // the ClassInfo object for this ClassDeclaration
        int, "com",                            // !=0 if this is a COM class (meaning
                                            // it derives from IUnknown)
        int, "isscope",                         // !=0 if this is an auto class
        int, "isabstract",                     // !=0 if abstract class
        int, "inuse"                          // to prevent recursive attempts
    );
}

interface InterfaceDeclaration : ClassDeclaration
{
}

