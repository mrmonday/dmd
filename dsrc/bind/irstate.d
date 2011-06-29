module bind.irstate;

extern(C++):

struct IRState
{
/*    IRState *prev;
    Statement *statement;
    Module *m;                  // module
    Dsymbol *symbol;
    Identifier *ident;
    Symbol *shidden;            // hidden parameter to function
    Symbol *sthis;              // 'this' parameter to function (member and nested)
    Symbol *sclosure;           // pointer to closure instance
    Blockx *blx;
    Array *deferToObj;          // array of Dsymbol's to run toObjFile(int multiobj) on later
    elem *ehidden;              // transmit hidden pointer to CallExp::toElem()
    Symbol *startaddress;
    Array *varsInScope;         // variables that are in scope that will need destruction later

    block *breakBlock;
    block *contBlock;
    block *switchBlock;
    block *defaultBlock;

    IRState(IRState *irs, Statement *s);
    IRState(IRState *irs, Dsymbol *s);
    IRState(Module *m, Dsymbol *s);

    block *getBreakBlock(Identifier *ident);
    block *getContBlock(Identifier *ident);
    block *getSwitchBlock();
    block *getDefaultBlock();
    FuncDeclaration *getFunc();
    int arrayBoundsCheck();*/
}
