module bind.enum_;

import bind.dsymbol;

extern(C++):
interface EnumDeclaration : ScopeDsymbol
{   /* enum ident : memtype { ... }
     */
/+    Type *type;                 // the TypeEnum
    Type *memtype;              // type of the members

#if DMDV1
    dinteger_t maxval;
    dinteger_t minval;
    dinteger_t defaultval;      // default initializer
#else
    Expression *maxval;
    Expression *minval;
    Expression *defaultval;     // default initializer
#endif
    int isdeprecated;
    int isdone;                 // 0: not done
                                // 1: semantic() successfully completed

    EnumDeclaration(Loc loc, Identifier *id, Type *memtype);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void semantic0(Scope *sc);
    void semantic(Scope *sc);
    int oneMember(Dsymbol **ps);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Type *getType();
    const char *kind();
#if DMDV2
    Dsymbol *search(Loc, Identifier *ident, int flags);
#endif
    int isDeprecated();                 // is Dsymbol deprecated?

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer *buf);
    void toDocBuffer(OutBuffer *buf);

    EnumDeclaration *isEnumDeclaration() { return this; }

    void toObjFile(int multiobj);                       // compile to .obj file
    void toDebug();
    int cvMember(unsigned char *p);

    Symbol *sinit;
    Symbol *toInitializer();+/
}

interface EnumMember : Dsymbol
{
/+    Expression *value;
    Type *type;

    EnumMember(Loc loc, Identifier *id, Expression *value, Type *type);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer *buf);
    void toDocBuffer(OutBuffer *buf);

    EnumMember *isEnumMember() { return this; }+/
}
