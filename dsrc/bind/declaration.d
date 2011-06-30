module bind.declaration;

import bind.arraytypes;
import bind.dsymbol;
import bind.expression;
import bind.hdrgen;
import bind.identifier;
import bind.init;
import bind.inline;
import bind.interpret;
import bind.irstate;
import bind.mars;
import bind.mtype;
import bind.root;
import bind.scope_;
import bind.statement;
import bind.util;

extern(C++):

enum Semantic
{
    SemanticStart,      // semantic has not been run
    SemanticIn,         // semantic() is in progress
    SemanticDone,       // semantic() has been run
    Semantic2Done,      // semantic2() has been run
}

enum BUILTIN
{
    BUILTINunknown = -1,        // not known if this is a builtin
    BUILTINnot,                 // this is not a builtin
    BUILTINsin,                 // std.math.sin
    BUILTINcos,                 // std.math.cos
    BUILTINtan,                 // std.math.tan
    BUILTINsqrt,                // std.math.sqrt
    BUILTINfabs,                // std.math.fabs
}

enum ILS
{
    ILSuninitialized,   // not computed yet
    ILSno,              // cannot inline
    ILSyes,             // can inline
}

interface Declaration : Dsymbol
{
    mixin CppFields!(Declaration,
        Type, "type",
        Type, "originalType",         // before semantic analysis
        StorageClass, "storage_class",
        PROT, "protection",
        LINK, "linkage",
        int, "inuse",                  // used to detect cycles
        Semantic, "sem"
    );
    /*Declaration(Identifier *id);
    void semantic(Scope *sc);
    const char *kind();
    unsigned size(Loc loc);
    void checkModify(Loc loc, Scope *sc, Type *t);

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer *buf);
    void toDocBuffer(OutBuffer *buf);

    char *mangle();
    int isStatic() { return storage_class & STCstatic; }*/
    int isDelete();
    int isDataseg();
    int isThreadlocal();
    int isCodeseg();
    /*
    int isCtorinit()     { return storage_class & STCctorinit; }
    int isFinal()        { return storage_class & STCfinal; }
    int isAbstract()     { return storage_class & STCabstract; }
    int isConst()        { return storage_class & STCconst; }
    int isImmutable()    { return storage_class & STCimmutable; }
    int isAuto()         { return storage_class & STCauto; }
    int isScope()        { return storage_class & STCscope; }
    int isSynchronized() { return storage_class & STCsynchronized; }
    int isParameter()    { return storage_class & STCparameter; }
    int isDeprecated()   { return storage_class & STCdeprecated; }
    int isOverride()     { return storage_class & STCoverride; }
    int isResult()       { return storage_class & STCresult; }

    int isIn()    { return storage_class & STCin; }
    int isOut()   { return storage_class & STCout; }
    int isRef()   { return storage_class & STCref; }

    enum PROT prot();

    Declaration *isDeclaration() { return this; }*/
}

interface FuncDeclaration : Declaration
{
    mixin CppFields!(FuncDeclaration,
        Array, "fthrows",
        Statement, "frequire",
        Statement, "fensure",
        Statement, "fbody",
        FuncDeclarationsRaw, "foverrides",
        FuncDeclaration, "fdrequire",
        FuncDeclaration, "fdensure",
        Identifier, "outId",
        VarDeclaration, "vresult",
        LabelDsymbol, "returnLabel",
        DsymbolTable*, "localsymtab",
        VarDeclaration, "vthis",
        VarDeclaration, "v_arguments",
        VarDeclaration, "v_argsave",
        Dsymbols, "parameters",
        DsymbolTable*, "labtab",
        Declaration, "overnext",
        Loc, "endloc",
        int, "vtblIndex",
        int, "naked",
        int, "inlineAsm",
        ILS, "inlineStatus",
        int, "inlineNest",
        int, "cantInterpret",
        int, "isArrayOp",
        PASS, "semanticRun",
        ForeachStatement, "fes",
        int, "introducing",
        Type, "tintro",
        int, "inferRetType",
        int, "hasReturnExp",
        int, "nrvo_can",
        VarDeclaration, "nrvo_var",
        Symbol, "shidden",
        BUILTIN, "builtin",
        int, "tookAddressOf",
        Dsymbols, "closureVars"
    );
    mixin CppMethods!(FuncDeclaration,
            "isMain", int
    );
    /*mixin CppMethods!(FuncDeclaration,
            // FuncDeclaration(Loc loc, Loc endloc, Identifier *id, StorageClass storage_class, Type *type);
            "syntaxCopy", Dsymbol, Dsymbol,
            "semantic", void, Scope,
            "semantic2", void, Scope,
            "semantic3", void, Scope,
            "varArgs", void, Scope, TypeFunction, VarDeclaration*, VarDeclaration*,
            "equals", int, DmObject,
            "toCBuffer", void, OutBuffer, HdrGenState*,
            "bodyToCBuffer", void, OutBuffer, HdrGenState*,
            "overrides", int, FuncDeclaration,
            "findVtblIndex", int, Array, int,
            "overloadInsert", int, Dsymbol,
            "overloadExactMatch", FuncDeclaration, Type,
            "overloadResolve", FuncDeclaration, Loc, Expression, Expressions, int,
            "leastAsSpecialized", MATCH, FuncDeclaration,
            "searchLabel", LabelDsymbol, Identifier,
            "isThis", AggregateDeclaration,
            "isMember2", AggregateDeclaration,
            "getLevel", int, Loc, FuncDeclaration,
            "appendExp", void, Expression,
            "appendState", void, Statement,
            "mangle", char*,
            "toPrettyChars", const char*,
            "isMain", int,
            "isWinMain", int,
            "isDllMain", int,
            "isBuiltin", BUILTIN,
            "isExport", int,
            "isImportedSymbol", int,
            "isAbstract", int,
            "isCodeseg", int,
            "isOverloadable", int,
            "isPure", PURE,
            "isSafe", int,
            "isTrusted", int,
            "needThis", int,

            "interpret", Expression, InterState, Expressions, Expression,
            "inlineScan", void,
            "canInline", int, int, int, int,
            "doInline", Expression, InlineScanState, Expression, Array,
            "kind", const char*,
            "toDocBuffer", void, OutBuffer,
            "isUnique", FuncDeclaration,
            "needsClosure", int,
            "mergeFrequire", Statement, Statement,
            "mergeFensure", Statement, Statement,
            "getParameters", Parameters, int*,

            "toSymbol", Symbol,
            "toThunkSymbol", Symbol, int,
            "cvMember", int, ubyte*,
            "buildClosure", void, IRState*
    );*/
    static FuncDeclaration *genCfunc(Type treturn, const char *name);
    static FuncDeclaration *genCfunc(Type treturn, Identifier id);

    int isNested();
    int isVirtual();
    int isFinal();
    int addPreInvariant();
    int addPostInvariant();
}
mixin(FuncDeclaration.cppMethods);

interface VarDeclaration : Declaration
{
    mixin CppFields!(VarDeclaration,
        Initializer, "init",
        uint, "offset",
        int, "noscope",                 // no auto semantics
        FuncDeclarationsRaw, "nestedrefs", // referenced by these lexically nested functions
        bool, "isargptr",              // if parameter that _argptr points to
        int, "ctorinit",               // it has been initialized in a ctor
        int, "onstack",                // 1: it has been allocated on the stack
                                    // 2: on stack, run destructor anyway
        int, "canassign",              // it can be assigned to
        Dsymbol, "aliassym",          // if redone as alias to another symbol

        // When interpreting, these hold the value (NULL if value not determinable)
        // The various functions are used only to detect compiler CTFE bugs
        Expression, "literalvalue"
    );
}
