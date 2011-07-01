module bind.dsymbol;

import bind.arraytypes;
import bind.declaration;
import bind.hdrgen;
import bind.identifier;
import bind.mars;
import bind.mtype;
import bind.root;
import bind.scope_;
import bind.util;

import duffer;

import std.conv;

extern(C++):

// Avoid forward reference errors
interface EnumMember{}
interface Package{}
interface Module{}
interface TemplateDeclaration{}
interface TemplateInstance{}
interface TemplateMixin{}
interface Declaration{}
interface ThisDeclaration{}
interface TupleDeclaration{}
interface TypedefDeclaration{}
interface AliasDeclaration{}
interface AggregateDeclaration{}
interface FuncAliasDeclaration{}
interface FuncLiteralDeclaration{}
interface CtorDeclaration{}
interface PostBlitDeclaration{}
interface DtorDeclaration{}
interface StaticCtorDeclaration{}
interface StaticDtorDeclaration{}
interface SharedStaticCtorDeclaration{}
interface SharedStaticDtorDeclaration{}
interface InvariantDeclaration{}
interface UnitTestDeclaration{}
interface NewDeclaration{}
interface ClassDeclaration{}
interface StructDeclaration{}
interface UnionDeclaration{}
interface InterfaceDeclaration{}
interface WithScopeSymbol{}
interface ArrayScopeSymbol{}
interface Import{}
interface EnumDeclaration{}
interface DeleteDeclaration{}
interface SymbolDeclaration{}
interface AttribDeclaration{}
interface LinkDeclaration{}
interface OverloadSet{}

LinkDeclaration isLinkDeclaration(Dsymbol d);

void declToJsBuffer(FuncDeclaration, Duffer);
void declToJsBuffer(VarDeclaration, Duffer);
void declToJsBuffer(LinkDeclaration, Duffer);
void declToJsBuffer(ClassDeclaration, Duffer);

enum PROT
{
    PROTundefined,
    PROTnone,           // no access
    PROTprivate,
    PROTpackage,
    PROTprotected,
    PROTpublic,
    PROTexport,
}

/* State of symbol in winding its way through the passes of the compiler
 */
enum PASS
{
    PASSinit,           // initial state
    PASSsemantic,       // semantic() started
    PASSsemanticdone,   // semantic() done
    PASSsemantic2,      // semantic2() run
    PASSsemantic3,      // semantic3() started
    PASSsemantic3done,  // semantic3() done
    PASSobj,            // toObjFile() run
}

interface Dsymbol : DmObject
{
    mixin CppFields!(Dsymbol,
        Identifier, "ident",
        Identifier, "c_ident",
        Dsymbol, "parent",
        Symbol*, "csym",
        Symbol*, "isym",
        ubyte*, "comment",
        Loc, "loc",
        Scope, "_scope"
    );
    mixin CppMethods!(Dsymbol,
        "toChars", char*
    );

    // These two should be something else. What? I dunno, maybe c/dtors?
    void foo();
    void bar();

    const char *toPrettyChars();
    const char *kind();
    Dsymbol toAlias();                 // resolve real symbol
    int addMember(Scope sc, ScopeDsymbol s, int memnum);
    void setScope(Scope sc);
    void importAll(Scope sc);
    void semantic0(Scope sc);
    void semantic(Scope sc);
    void semantic2(Scope sc);
    void semantic3(Scope sc);
    void inlineScan();
    Dsymbol search(Loc loc, Identifier ident, int flags);
    int overloadInsert(Dsymbol s);
    void toHBuffer(OutBuffer buf, HdrGenState hgs);
    void toCBuffer(OutBuffer buf, HdrGenState hgs);
    void toDocBuffer(OutBuffer buf);
    void toJsonBuffer(OutBuffer buf);
    uint size(Loc loc);
    int isforwardRef();
    void defineRef(Dsymbol s);
    AggregateDeclaration isThis();     // is a 'this' required to access the member
    ClassDeclaration isClassMember();  // are we a member of a class?
    int isExport();                     // is Dsymbol exported?
    int isImportedSymbol();             // is Dsymbol imported?
    int isDeprecated();                 // is Dsymbol deprecated?
    int isOverloadable();
    //LabelDsymbol isLabel();            // is this a LabelDsymbol?
    Dsymbol isLabel();            // is this a LabelDsymbol?
    AggregateDeclaration isMember();   // is this symbol a member of an AggregateDeclaration?
    Type *getType();                    // is this a type?
    char *mangle();
    int needThis();                     // need a 'this' pointer?
    PROT prot();
    Dsymbol syntaxCopy(Dsymbol s);    // copy only syntax trees
    int oneMember(Dsymbol *ps);
    int hasPointers();
    void addLocalClass(ClassDeclarations);
    void checkCtorConstInit();

    void addComment(ubyte *comment);
    void emitComment(Scope sc);

    // Backend

    Symbol toSymbol();                 // to backend symbol
    void toObjFile(int multiobj);                       // compile to .obj file
    int cvMember(ubyte *p);     // emit cv debug info for member

    Package isPackage();
    Module isModule();
    EnumMember isEnumMember();
    TemplateDeclaration isTemplateDeclaration();
    TemplateInstance isTemplateInstance();
    TemplateMixin isTemplateMixin();
    Declaration isDeclaration();
    ThisDeclaration isThisDeclaration();
    TupleDeclaration isTupleDeclaration();
    TypedefDeclaration isTypedefDeclaration();
    AliasDeclaration isAliasDeclaration();
    AggregateDeclaration isAggregateDeclaration();
    FuncDeclaration isFuncDeclaration();
    FuncAliasDeclaration isFuncAliasDeclaration();
    FuncLiteralDeclaration isFuncLiteralDeclaration();
    CtorDeclaration isCtorDeclaration();
    PostBlitDeclaration isPostBlitDeclaration();
    DtorDeclaration isDtorDeclaration();
    StaticCtorDeclaration isStaticCtorDeclaration();
    StaticDtorDeclaration isStaticDtorDeclaration();
    SharedStaticCtorDeclaration isSharedStaticCtorDeclaration();
    SharedStaticDtorDeclaration isSharedStaticDtorDeclaration();
    InvariantDeclaration isInvariantDeclaration();
    UnitTestDeclaration isUnitTestDeclaration();
    NewDeclaration isNewDeclaration();
    VarDeclaration isVarDeclaration();
    ClassDeclaration isClassDeclaration();
    StructDeclaration isStructDeclaration();
    UnionDeclaration isUnionDeclaration();
    InterfaceDeclaration isInterfaceDeclaration();
    ScopeDsymbol isScopeDsymbol();
    WithScopeSymbol isWithScopeSymbol();
    ArrayScopeSymbol isArrayScopeSymbol();
    Import isImport();
    EnumDeclaration isEnumDeclaration();
    DeleteDeclaration isDeleteDeclaration();
    SymbolDeclaration isSymbolDeclaration();
    AttribDeclaration isAttribDeclaration();
    OverloadSet isOverloadSet();
    final void toJsBuffer(Duffer buf)
    {
        /*writefln("funcdecl: %s", to!string(cast(char*)toPrettyChars()));
        writefln("isPackage: %s", !!isPackage());
        writefln("isModule: %s", !!isModule());
        writefln("isEnumMember: %s", !!isEnumMember());
        writefln("isTemplDecl: %s", !!isTemplateDeclaration());
        writefln("isTemplInst: %s", !!isTemplateInstance());
        writefln("isTemplMixin: %s", !!isTemplateMixin());
        writefln("isDecl: %s", !!isDeclaration());
        writefln("isThisDecl: %s", !!isThisDeclaration());
        writefln("isTupleDecl: %s", !!isTupleDeclaration());
        writefln("isDeclTypedef: %s", !!isTypedefDeclaration());
        writefln("isAliasDecl: %s", !!isAliasDeclaration());
        writefln("isAggr: %s", !!isAggregateDeclaration());
        writefln("isFunc: %s", !!isFuncDeclaration());
        writefln("isFuncAlias: %s", !!isFuncAliasDeclaration());
        writefln("isImport: %s", !!isImport());
        writefln("isOverloadSet: %s", !!isOverloadSet());*/
        //writefln("sym:  %s", to!string(toChars()));
        if (auto fd = isFuncDeclaration())
        {
           // writefln("func:  %s", to!string(toChars()));
            declToJsBuffer(fd, buf);
        }
        else if (auto cd = isClassDeclaration())
        {
            writefln("class:   %s", to!string(toChars()));
            declToJsBuffer(cd, buf);
        }
        else if (auto vd = isVarDeclaration())
        {
           // writefln("var:    %s", to!string(toChars()));
            //writefln("varpar: %s", !!vd.parent.isFuncDeclaration());
            declToJsBuffer(vd, buf);
        }
        else if (auto i = isImport())
        {
            stderr.writefln("ignoring import %s", to!string(toChars()));
        }
        else if (auto ld = isLinkDeclaration(this))
        {
            declToJsBuffer(ld, buf);
        }
        else
        {
            //writefln("sym:  %s", to!string(toChars()));
            assert(0, "Unhandled symbol type: " ~ to!string(toTypeString(this)));
        }
    }
}
mixin(Dsymbol.cppMethods);

const(char*) toTypeString(Dsymbol);

// Port these at some point
// Note that they shouldn't be pointers
alias void DsymbolTable;

interface ScopeDsymbol : Dsymbol
{
    mixin CppFields!(ScopeDsymbol,
        Dsymbols, "members",          // all Dsymbol's in this scope
        DsymbolTable*, "symtab",       // members[] sorted into table

        Array, "imports",            // imported ScopeDsymbol's
        ubyte*, "prots"       // array of PROT, one for each import
    );
}
