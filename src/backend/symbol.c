// Copyright (C) 1984-1998 by Symantec
// Copyright (C) 2000-2009 by Digital Mars
// All Rights Reserved
// http://www.digitalmars.com
// Written by Walter Bright
/*
 * This source file is made available for personal use
 * only. The license is in /dmd/src/dmd/backendlicense.txt
 * or /dm/src/dmd/backendlicense.txt
 * For any other uses, please contact Digital Mars.
 */

#if !SPP

#include        <stdio.h>
#include        <string.h>
#include        <stdlib.h>
#include        <time.h>

#include        "cc.h"
#include        "parser.h"
#include        "global.h"
#include        "type.h"
#include        "dt.h"
#if TX86
#include        "cgcv.h"
#endif

#include        "el.h"
#include        "cpp.h"
#include        "oper.h"                /* for OPMAX            */
#include        "token.h"

#if TARGET_MAC
#include        "TG.h"
#endif

static char __file__[] = __FILE__;      /* for tassert.h                */
#include        "tassert.h"

//STATIC void symbol_undef(symbol *s);
STATIC void symbol_freemember(symbol *s);
STATIC void mptr_hydrate(mptr_t **);
STATIC void mptr_dehydrate(mptr_t **);
STATIC void baseclass_hydrate(baseclass_t **);
STATIC void baseclass_dehydrate(baseclass_t **);

/*********************************
 * Allocate/free symbol table.
 */

symbol **symtab_realloc(symbol **tab, size_t symmax)
{   symbol **newtab;

    if (config.flags2 & (CFG2phgen | CFG2phuse | CFG2phauto | CFG2phautoy))
    {
        newtab = (symbol **) MEM_PH_REALLOC(tab, symmax * sizeof(symbol *));
    }
    else
    {
        newtab = (symbol **) realloc(tab, symmax * sizeof(symbol *));
        if (!newtab)
            err_nomem();
    }
    return newtab;
}

symbol **symtab_malloc(size_t symmax)
{   symbol **newtab;

    if (config.flags2 & (CFG2phgen | CFG2phuse | CFG2phauto | CFG2phautoy))
    {
        newtab = (symbol **) MEM_PH_MALLOC(symmax * sizeof(symbol *));
    }
    else
    {
        newtab = (symbol **) malloc(symmax * sizeof(symbol *));
        if (!newtab)
            err_nomem();
    }
    return newtab;
}

symbol **symtab_calloc(size_t symmax)
{   symbol **newtab;

    if (config.flags2 & (CFG2phgen | CFG2phuse | CFG2phauto | CFG2phautoy))
    {
        newtab = (symbol **) MEM_PH_CALLOC(symmax * sizeof(symbol *));
    }
    else
    {
        newtab = (symbol **) calloc(symmax, sizeof(symbol *));
        if (!newtab)
            err_nomem();
    }
    return newtab;
}

void symtab_free(symbol **tab)
{
    if (config.flags2 & (CFG2phgen | CFG2phuse | CFG2phauto | CFG2phautoy))
        MEM_PH_FREE(tab);
    else if (tab)
        free(tab);
}

/*******************************
 * Type out symbol information.
 */

#ifdef DEBUG

void symbol_print(symbol *s)
{
#if !SPP
    if (!s) return;
    dbg_printf("symbol %p '%s'\n ",s,s->Sident);
    dbg_printf(" Sclass = "); WRclass((enum SC) s->Sclass);
    dbg_printf(" Ssymnum = %d",s->Ssymnum);
    dbg_printf(" Sfl = "); WRFL((enum FL) s->Sfl);
    dbg_printf(" Sseg = %d\n",s->Sseg);
//  dbg_printf(" Ssize   = x%02x\n",s->Ssize);
    dbg_printf(" Soffset = x%04lx",s->Soffset);
    dbg_printf(" Sweight = %d",s->Sweight);
    dbg_printf(" Sflags = x%04lx",s->Sflags);
    dbg_printf(" Sxtrnnum = %d\n",s->Sxtrnnum);
    dbg_printf("  Stype   = %p",s->Stype);
#if SCPP
    dbg_printf(" Ssequence = %x", s->Ssequence);
    dbg_printf(" Scover  = %p", s->Scover);
#endif
    dbg_printf(" Sl      = %p",s->Sl);
    dbg_printf(" Sr      = %p\n",s->Sr);
#if SCPP
    if (s->Sscope)
        dbg_printf(" Sscope = '%s'\n",s->Sscope->Sident);
#endif
    if (s->Stype)
        type_print(s->Stype);
    if (s->Sclass == SCmember || s->Sclass == SCfield)
    {
        dbg_printf("  Smemoff =%5ld",s->Smemoff);
        dbg_printf("  Sbit    =%3d",s->Sbit);
        dbg_printf("  Swidth  =%3d\n",s->Swidth);
    }
#if SCPP
    if (s->Sclass == SCstruct)
    {
#if VBTABLES
        dbg_printf("  Svbptr = %p, Svptr = %p\n",s->Sstruct->Svbptr,s->Sstruct->Svptr);
#endif
    }
#endif
#endif
}

#endif

/*********************************
 * Terminate use of symbol table.
 */

static symbol *keep;

void symbol_term()
{
    symbol_free(keep);
}

/****************************************
 * Keep symbol around until symbol_term().
 */

#if TERMCODE

void symbol_keep(symbol *s)
{
    symbol_debug(s);
    s->Sr = keep;       // use Sr so symbol_free() doesn't nest
    keep = s;
}

#endif

/***********************************
 * Get user name of symbol.
 */

char *symbol_ident(symbol *s)
{
#if SCPP
    static char noname[] = "__unnamed";
    switch (s->Sclass)
    {   case SCstruct:
            if (s->Sstruct->Salias)
                s = s->Sstruct->Salias;
            else if (s->Sstruct->Sflags & STRnotagname)
                return noname;
            break;
        case SCenum:
            if (CPP)
            {   if (s->Senum->SEalias)
                    s = s->Senum->SEalias;
                else if (s->Senum->SEflags & SENnotagname)
                    return noname;
            }
            break;

        case SCnamespace:
            if (s->Sident[0] == '?' && s->Sident[1] == '%')
                return "unique";        // an unnamed namespace
            break;
    }
#endif
    return s->Sident;
}

/****************************************
 * Create a new symbol.
 */

symbol * symbol_calloc(const char *id)
{   symbol *s;
    int len;

    len = strlen(id);
    //printf("sizeof(symbol)=%d, sizeof(s->Sident)=%d, len=%d\n",sizeof(symbol),sizeof(s->Sident),len);
#if TX86
    s = (symbol *) mem_fmalloc(sizeof(symbol) - sizeof(s->Sident) + len + 1 + 5);
#else
    s = (symbol *) MEM_PH_MALLOC(sizeof(symbol) - sizeof(s->Sident) + len + 1);
#endif
    memset(s,0,sizeof(symbol) - sizeof(s->Sident));
#if SCPP
    s->Ssequence = pstate.STsequence;
    pstate.STsequence += 1;
    //if (s->Ssequence == 0x21) *(char*)0=0;
#endif
#ifdef DEBUG
    if (debugy)
        dbg_printf("symbol_calloc('%s') = %p\n",id,s);
    s->id = IDsymbol;
#endif
    memcpy(s->Sident,id,len + 1);
    s->Ssymnum = -1;
    return s;
}

/****************************************
 * Create a symbol, given a name and type.
 */

symbol * symbol_name(const char *name,int sclass,type *t)
{
    type_debug(t);
    symbol *s = symbol_calloc(name);
    s->Sclass = (enum SC) sclass;
    s->Stype = t;
    s->Stype->Tcount++;
#if ELFOBJ || MACHOBJ // Burton
    s->Sseg = CDATA;
#endif

    if (tyfunc(t->Tty))
        symbol_func(s);
    return s;
}

/****************************************
 * Create a symbol that is an alias to another function symbol.
 */

Funcsym *symbol_funcalias(Funcsym *sf)
{
    Funcsym *s;

    symbol_debug(sf);
    assert(tyfunc(sf->Stype->Tty));
    if (sf->Sclass == SCfuncalias)
        sf = sf->Sfunc->Falias;
    s = (Funcsym *)symbol_name(sf->Sident,SCfuncalias,sf->Stype);
    s->Sfunc->Falias = sf;
#if SCPP
    s->Scover = sf->Scover;
#endif
    return s;
}

/****************************************
 * Create a symbol, give it a name, storage class and type.
 */

symbol * symbol_generate(int sclass,type *t)
{   char name[10];
    static int tmpnum;

    sprintf(name,"_TMP%d",tmpnum++);
#ifdef DEBUG
    symbol *s = symbol_name(name,sclass,t);
    //symbol_print(s);
    return s;
#else
    return symbol_name(name,sclass,t);
#endif
}

/****************************************
 * Generate an auto symbol, and add it to the symbol table.
 */

symbol * symbol_genauto(type *t)
{   symbol *s;

    s = symbol_generate(SCauto,t);
#if SCPP
    //printf("symbol_genauto(t) '%s'\n", s->Sident);
    if (pstate.STdefertemps)
    {   symbol_keep(s);
        s->Ssymnum = -1;
    }
    else
    {   s->Sflags |= SFLfree;
        if (init_staticctor)
        {   // variable goes into _STI_xxxx
            s->Ssymnum = -1;            // deferred allocation
//printf("test2\n");
//if (s->Sident[4] == '2') *(char*)0=0;
        }
        else
        {
            symbol_add(s);
        }
    }
#else
    s->Sflags |= SFLfree;
    symbol_add(s);
#endif
    return s;
}

/******************************************
 * Generate symbol into which we can copy the contents of expression e.
 */

Symbol *symbol_genauto(elem *e)
{
    return symbol_genauto(type_fake(e->Ety));
}

/******************************************
 * Generate symbol into which we can copy the contents of expression e.
 */

Symbol *symbol_genauto(tym_t ty)
{
    return symbol_genauto(type_fake(ty));
}

/****************************************
 * Add in the variants for a function symbol.
 */

void symbol_func(symbol *s)
{
    //printf("symbol_func(%s, x%x)\n", s->Sident, fregsaved);
    symbol_debug(s);
    s->Sfl = FLfunc;
    // Interrupt functions modify all registers
#if TX86
    // BUG: do interrupt functions really save BP?
    #define mBP 0x20
    // Note that fregsaved may not be set yet
    s->Sregsaved = (s->Stype && tybasic(s->Stype->Tty) == TYifunc) ? mBP : fregsaved;
    s->Sseg = UNKNOWN;          // don't know what segment it is in
#endif
    if (!s->Sfunc)
        s->Sfunc = func_calloc();
}

/********************************
 * Define symbol in specified symbol table.
 * Returns:
 *      pointer to symbol
 */

#if SCPP

symbol * defsy(const char *p,symbol **parent)
{
   symbol *s = symbol_calloc(p);
   symbol_addtotree(parent,s);
   return s;
}

#endif

/********************************
 * Check integrity of symbol data structure.
 */

#ifdef DEBUG

void symbol_check(symbol *s)
{
    //dbg_printf("symbol_check('%s',%p)\n",s->Sident,s);
    symbol_debug(s);
    if (s->Stype) type_debug(s->Stype);
    assert((unsigned)s->Sclass < (unsigned)SCMAX);
#if SCPP
    if (s->Sscope)
        symbol_check(s->Sscope);
    if (s->Scover)
        symbol_check(s->Scover);
#endif
}

void symbol_tree_check(symbol *s)
{
    while (s)
    {   symbol_check(s);
        symbol_tree_check(s->Sl);
        s = s->Sr;
    }
}

#endif

/********************************
 * Insert symbol in specified symbol table.
 */

#if SCPP

void symbol_addtotree(symbol **parent,symbol *s)
{  symbol *rover;
   signed char cmp;
   size_t len;
   const char *p;
   char c;

   //dbg_printf("symbol_addtotree('%s',%p)\n",s->Sident,*parent);
#ifdef DEBUG
   symbol_tree_check(*parent);
   assert(!s->Sl && !s->Sr);
#endif
   symbol_debug(s);
   p = s->Sident;
   c = *p;
   len = strlen(p);
   p++;
   rover = *parent;
   while (rover != NULL)                // while we haven't run out of tree
   {    symbol_debug(rover);
        if ((cmp = c - rover->Sident[0]) == 0)
        {   cmp = memcmp(p,rover->Sident + 1,len); // compare identifier strings
            if (cmp == 0)               // found it if strings match
            {
                if (CPP)
                {   symbol *s2;

                    switch (rover->Sclass)
                    {   case SCstruct:
                            s2 = rover;
                            goto case_struct;

                        case_struct:
                            if (s2->Sstruct->Sctor &&
                                !(s2->Sstruct->Sctor->Sfunc->Fflags & Fgen))
                                cpperr(EM_ctor_disallowed,p);   // no ctor allowed for class rover
                            s2->Sstruct->Sflags |= STRnoctor;
                            goto case_cover;

                        case_cover:
                            // Replace rover with the new symbol s, and
                            // have s 'cover' the tag symbol s2.
                            // BUG: memory leak on rover if s2!=rover
                            assert(!s2->Scover);
                            s->Sl = rover->Sl;
                            s->Sr = rover->Sr;
                            s->Scover = s2;
                            *parent = s;
                            rover->Sl = rover->Sr = NULL;
                            return;

                        case SCenum:
                            s2 = rover;
                            goto case_cover;

                        case SCtemplate:
                            s2 = rover;
                            s2->Stemplate->TMflags |= STRnoctor;
                            goto case_cover;

                        case SCalias:
                            s2 = rover->Smemalias;
                            if (s2->Sclass == SCstruct)
                                goto case_struct;
                            if (s2->Sclass == SCenum)
                                goto case_cover;
                            break;
                    }
                }
                synerr(EM_multiple_def,p - 1);  // symbol is already defined
                //symbol_undef(s);              // undefine the symbol
                return;
            }
        }
        parent = (cmp < 0) ?            /* if we go down left side      */
            &(rover->Sl) :              /* then get left child          */
            &(rover->Sr);               /* else get right child         */
        rover = *parent;                /* get child                    */
   }
   /* not in table, so insert into table        */
   *parent = s;                         /* link new symbol into tree    */
L1:
   ;
}

#endif

/*************************************
 * Search for symbol in multiple symbol tables,
 * starting with most recently nested one.
 * Input:
 *      p ->    identifier string
 * Returns:
 *      pointer to symbol
 *      NULL if couldn't find it
 */

#if 0
symbol * lookupsym(const char *p)
{
    return scope_search(p,SCTglobal | SCTlocal);
}
#endif

/*************************************
 * Search for symbol in symbol table.
 * Input:
 *      p ->    identifier string
 *      rover -> where to start looking
 * Returns:
 *      pointer to symbol (NULL if not found)
 */

#if SCPP

symbol * findsy(const char *p,symbol *rover)
{
#if __INTSIZE == 2 && TX86 && !defined(_MSC_VER)
    volatile int len;
    __asm
    {
        push    DS
        mov     DS,word ptr p+2
        les     DI,p
        mov     DX,word ptr p
        mov     BX,ES:[DI]
        xor     AL,AL
        mov     CX,0FFFFh
        repne   scasb
        not     CX
        sub     CX,2
        mov     len,CX
        add     DX,2
        mov     AX,BX
        les     BX,rover
        jmp     short L1

L38C:           les     BX,ES:symbol.Sl[BX]
L1:             test    BX,BX
                je      L3A5
                cmp     AL,ES:symbol.Sident[BX]
                js      L38C
                je      L2
                les     BX,ES:symbol.Sr[BX]
                jmp     L1

L2:             cmp     AH,ES:symbol.Sident+1[BX]
                js      L38C
                je      L3
                les     BX,ES:symbol.Sr[BX]
                jmp     L1

L3:             mov     SI,DX
                lea     DI,symbol.Sident+2[BX]
                mov     CX,len
                rep     cmpsb
                js      L38C
                je      L3A5
                les     BX,ES:symbol.Sr[BX]
                jmp     L1

L3A5:   mov     DX,ES
        mov     AX,BX
        pop     DS
    }
#elif __INTSIZE == 4 && TX86 && !defined(_MSC_VER) && !M_UNIX
    volatile int len;
    __asm
    {
#if !_WIN32
        push    DS
        pop     ES
#endif
        mov     EDI,p
        xor     AL,AL

        mov     BL,[EDI]
        mov     ECX,-1

        repne   scasb

        not     ECX
        mov     EDX,p

        dec     ECX
        inc     EDX

        mov     len,ECX
        mov     AL,BL

        mov     EBX,rover
        mov     ESI,EDX

        test    EBX,EBX
        je      L6

        cmp     AL,symbol.Sident[EBX]
        js      L2

        lea     EDI,symbol.Sident+1[EBX]
        je      L5

        mov     EBX,symbol.Sr[EBX]
        jmp     L3

L1:             mov     ECX,len
L2:             mov     EBX,symbol.Sl[EBX]

L3:             test    EBX,EBX
                je      L6

L4:             cmp     AL,symbol.Sident[EBX]
                js      L2

                lea     EDI,symbol.Sident+1[EBX]
                je      L5

                mov     EBX,symbol.Sr[EBX]
                jmp     L3

L5:             rep     cmpsb

                mov     ESI,EDX
                js      L1

                je      L6

                mov     EBX,symbol.Sr[EBX]
                mov     ECX,len

                test    EBX,EBX
                jne     L4

L6:     mov     EAX,EBX
    }
#else
    size_t len;
    signed char cmp;                    /* set to value of strcmp       */
    char c = *p;

    len = strlen(p);
    p++;                                // will pick up 0 on memcmp
    while (rover != NULL)               // while we haven't run out of tree
    {   symbol_debug(rover);
        if ((cmp = c - rover->Sident[0]) == 0)
        {   cmp = memcmp(p,rover->Sident + 1,len); /* compare identifier strings */
            if (cmp == 0)
                return rover;           /* found it if strings match    */
        }
        rover = (cmp < 0) ? rover->Sl : rover->Sr;
    }
    return rover;                       // failed to find it
#endif
}

#endif

/***********************************
 * Create a new symbol table.
 */

#if SCPP

void createglobalsymtab()
{
    assert(!scope_end);
    if (CPP)
        scope_push(NULL,(scope_fp)findsy, SCTcglobal);
    else
        scope_push(NULL,(scope_fp)findsy, SCTglobaltag);
    scope_push(NULL,(scope_fp)findsy, SCTglobal);
}


void createlocalsymtab()
{
    assert(scope_end);
    if (!CPP)
        scope_push(NULL,(scope_fp)findsy, SCTtag);
    scope_push(NULL,(scope_fp)findsy, SCTlocal);
}


/***********************************
 * Delete current symbol table and back up one.
 */

void deletesymtab()
{   symbol *root;

    root = (symbol *)scope_pop();
    if (root)
    {
        if (funcsym_p)
            list_prepend(&funcsym_p->Sfunc->Fsymtree,root);
        else
            symbol_free(root);  // free symbol table
    }

    if (!CPP)
    {
        root = (symbol *)scope_pop();
        if (root)
        {
            if (funcsym_p)
                list_prepend(&funcsym_p->Sfunc->Fsymtree,root);
            else
                symbol_free(root);      // free symbol table
        }
    }
}

#endif

/*********************************
 * Delete symbol from symbol table, taking care to delete
 * all children of a symbol.
 * Make sure there are no more forward references (labels, tags).
 * Input:
 *      pointer to a symbol
 */

void meminit_free(meminit_t *m)         /* helper for symbol_free()     */
{
    list_free(&m->MIelemlist,(list_free_fp)el_free);
    MEM_PARF_FREE(m);
}

void symbol_free(symbol *s)
{
    while (s)                           /* if symbol exists             */
    {   symbol *sr;

#ifdef DEBUG
        if (debugy)
            dbg_printf("symbol_free('%s',%p)\n",s->Sident,s);
        symbol_debug(s);
        assert(/*s->Sclass != SCunde &&*/ (int) s->Sclass < (int) SCMAX);
#endif
        {   type *t = s->Stype;

            if (t)
                type_debug(t);
            if (t && tyfunc(t->Tty) && s->Sfunc)
            {
                func_t *f = s->Sfunc;

                debug(assert(f));
                blocklist_free(&f->Fstartblock);
                freesymtab(f->Flocsym.tab,0,f->Flocsym.top);

                symtab_free(f->Flocsym.tab);
              if (CPP)
              {
                if (f->Fflags & Fnotparent)
                {   debug(debugy && dbg_printf("not parent, returning\n"));
                    return;
                }

                /* We could be freeing the symbol before it's class is  */
                /* freed, so remove it from the class's field list      */
#if 1
                if (f->Fclass)
                {   list_t tl;

                    symbol_debug(f->Fclass);
                    tl = list_inlist(f->Fclass->Sstruct->Sfldlst,s);
                    if (tl)
                        list_setsymbol(tl,0);
                }
#endif
                if (f->Foversym && f->Foversym->Sfunc)
                {   f->Foversym->Sfunc->Fflags &= ~Fnotparent;
                    f->Foversym->Sfunc->Fclass = NULL;
                    symbol_free(f->Foversym);
                }

                if (f->Fexplicitspec)
                    symbol_free(f->Fexplicitspec);

                /* If operator function, remove from list of such functions */
                if (f->Fflags & Foperator)
                {   assert(f->Foper && f->Foper < OPMAX);
                    //if (list_inlist(cpp_operfuncs[f->Foper],s))
                    //  list_subtract(&cpp_operfuncs[f->Foper],s);
                }

                list_free(&f->Fclassfriends,FPNULL);
                list_free(&f->Ffwdrefinstances,FPNULL);
                param_free(&f->Farglist);
                param_free(&f->Fptal);
                list_free(&f->Fexcspec,(list_free_fp)type_free);
#if SCPP
                token_free(f->Fbody);
#endif
                el_free(f->Fbaseinit);
                if (f->Fthunk && !(f->Fflags & Finstance))
                    MEM_PH_FREE(f->Fthunk);
                list_free(&f->Fthunks,(list_free_fp)symbol_free);
              }
                list_free(&f->Fsymtree,(list_free_fp)symbol_free);
                func_free(f);
            }
#if TARGET_MAC
            if (s->Sdirect && s->Sflags&SFLdirect && !(s->Sflags&SFLsmdir))
                MEM_PH_FREE(s->Sdirect);
#endif
            switch (s->Sclass)
            {
#if SCPP
                case SClabel:
                    if (!s->Slabel)
                        synerr(EM_unknown_label,s->Sident);
                    break;
#endif
                case SCstruct:
#if SCPP
                  if (CPP)
                  {
                    struct_t *st = s->Sstruct;
                    assert(st);
                    list_free(&st->Sclassfriends,FPNULL);
                    list_free(&st->Sfriendclass,FPNULL);
                    list_free(&st->Sfriendfuncs,FPNULL);
                    list_free(&st->Scastoverload,FPNULL);
                    list_free(&st->Sopoverload,FPNULL);
                    list_free(&st->Svirtual,MEM_PH_FREEFP);
                    list_free(&st->Sfldlst,FPNULL);
                    symbol_free(st->Sroot);
                    baseclass_t *b,*bn;

                    for (b = st->Sbase; b; b = bn)
                    {   bn = b->BCnext;
                        list_free(&b->BCpublics,FPNULL);
                        baseclass_free(b);
                    }
                    for (b = st->Svirtbase; b; b = bn)
                    {   bn = b->BCnext;
                        baseclass_free(b);
                    }
                    for (b = st->Smptrbase; b; b = bn)
                    {   bn = b->BCnext;
                        list_free(&b->BCmptrlist,MEM_PH_FREEFP);
                        baseclass_free(b);
                    }
#if VBTABLES
                    for (b = st->Svbptrbase; b; b = bn)
                    {   bn = b->BCnext;
                        baseclass_free(b);
                    }
#endif
                    param_free(&st->Sarglist);
                    param_free(&st->Spr_arglist);
                    struct_free(st);
                  }
                  else
#endif
                  {
#ifdef DEBUG
                    if (debugy)
                        dbg_printf("freeing members %p\n",s->Sstruct->Sfldlst);
#endif
                    list_free(&s->Sstruct->Sfldlst,FPNULL);
                    symbol_free(s->Sstruct->Sroot);
                    struct_free(s->Sstruct);
                  }
#if 0               /* Don't complain anymore about these, ANSI C says  */
                    /* it's ok                                          */
                    if (t && t->Tflags & TFsizeunknown)
                        synerr(EM_unknown_tag,s->Sident);
#endif
                    break;
                case SCenum:
                    /* The actual member symbols are either in a local  */
                    /* table or on the member list of a class, so we    */
                    /* don't free them here.                            */
                    assert(s->Senum);
                    list_free(&s->Senumlist,FPNULL);
                    MEM_PH_FREE(s->Senum);
                    s->Senum = NULL;
                    break;

#if SCPP
                case SCtemplate:
                {   template_t *tm = s->Stemplate;

                    list_free(&tm->TMinstances,FPNULL);
                    list_free(&tm->TMmemberfuncs,(list_free_fp)tmf_free);
                    list_free(&tm->TMexplicit,(list_free_fp)tme_free);
                    list_free(&tm->TMnestedexplicit,(list_free_fp)tmne_free);
                    list_free(&tm->TMnestedfriends,(list_free_fp)tmnf_free);
                    param_free(&tm->TMptpl);
                    param_free(&tm->TMptal);
                    token_free(tm->TMbody);
                    symbol_free(tm->TMpartial);
                    list_free(&tm->TMfriends,FPNULL);
                    MEM_PH_FREE(tm);
                    break;
                }
                case SCnamespace:
                    symbol_free(s->Snameroot);
                    list_free(&s->Susing,FPNULL);
                    break;

                case SCmemalias:
                case SCfuncalias:
                case SCadl:
                    list_free(&s->Spath,FPNULL);
                    break;
#endif
                case SCparameter:
                case SCregpar:
                case SCfastpar:
                case SCregister:
                case SCtmp:
                T80x86(case SCauto:)
                    vec_free(s->Srange);
                    /* FALL-THROUGH */
#if 0
                case SCconst:
                    if (s->Sflags & (SFLvalue | SFLdtorexp))
                        el_free(s->Svalue);
#endif
                    break;
                default:
                    break;
            }
            if (s->Sflags & (SFLvalue | SFLdtorexp))
                el_free(s->Svalue);
            if (s->Sdt)
                dt_free(s->Sdt);
            type_free(t);
            symbol_free(s->Sl);
#if SCPP
            if (s->Scover)
                symbol_free(s->Scover);
#endif
            sr = s->Sr;
#ifdef DEBUG
            s->id = 0;
#endif
#if TX86
            mem_ffree(s);
#else
            MEM_PH_FREE(s);
#endif
        }
        s = sr;
    }
}

/********************************
 * Undefine a symbol.
 * Assume error msg was already printed.
 */

#if 0
STATIC void symbol_undef(symbol *s)
{
  s->Sclass = SCunde;
  s->Ssymnum = -1;
  type_free(s->Stype);                  /* free type data               */
  s->Stype = NULL;
}
#endif

/*****************************
 * Add symbol to current symbol array.
 */

SYMIDX symbol_add(symbol *s)
{   SYMIDX sitop;

    //printf("symbol_add('%s')\n", s->Sident);
#ifdef DEBUG
    if (!s || !s->Sident[0])
        dbg_printf("bad symbol\n");
#endif
    symbol_debug(s);
    if (pstate.STinsizeof)
    {   symbol_keep(s);
        return -1;
    }
    debug(assert(cstate.CSpsymtab));
    sitop = cstate.CSpsymtab->top;
    assert(sitop <= cstate.CSpsymtab->symmax);
    if (sitop == cstate.CSpsymtab->symmax)
    {
#if defined(DEBUG) && !HOST_MPW
#define SYMINC  1                       /* flush out reallocation bugs  */
#else
#define SYMINC  99
#endif
        cstate.CSpsymtab->symmax += (cstate.CSpsymtab == &globsym) ? SYMINC : 1;
        //assert(cstate.CSpsymtab->symmax * sizeof(symbol *) < 4096 * 4);
        cstate.CSpsymtab->tab = symtab_realloc(cstate.CSpsymtab->tab, cstate.CSpsymtab->symmax);
    }
    cstate.CSpsymtab->tab[sitop] = s;
#if AUTONEST
    if (pushcount)
    {   s->Spush = pushcount;
        pushcount = 0;
    }
#endif
#ifdef DEBUG
    if (debugy)
        dbg_printf("symbol_add(%p '%s') = %d\n",s,s->Sident,cstate.CSpsymtab->top);
#endif
    assert(s->Ssymnum == -1);
    return s->Ssymnum = cstate.CSpsymtab->top++;
}

/****************************
 * Free up the symbol table, from symbols n1 through n2, not
 * including n2.
 */

void freesymtab(symbol **stab,SYMIDX n1,SYMIDX n2)
{   SYMIDX si;

    if (!stab)
        return;
#ifdef DEBUG
    if (debugy)
        dbg_printf("freesymtab(from %d to %d)\n",n1,n2);
#endif
    assert(stab != globsym.tab || (n1 <= n2 && n2 <= globsym.top));
    for (si = n1; si < n2; si++)
    {   symbol *s;

        s = stab[si];
        if (s && s->Sflags & SFLfree)
        {   stab[si] = NULL;
#ifdef DEBUG
            if (debugy)
                dbg_printf("Freeing %p '%s' (%d)\n",s,s->Sident,si);
            symbol_debug(s);
#endif
            s->Sl = s->Sr = NULL;
            s->Ssymnum = -1;
            symbol_free(s);
        }
    }
}

/****************************
 * Create a copy of a symbol.
 */

symbol * symbol_copy(symbol *s)
{   symbol *scopy;
    type *t;

    symbol_debug(s);
    /*dbg_printf("symbol_copy(%s)\n",s->Sident);*/
    scopy = symbol_calloc(s->Sident);
    memcpy(scopy,s,sizeof(symbol) - sizeof(s->Sident));
    scopy->Sl = scopy->Sr = scopy->Snext = NULL;
    scopy->Ssymnum = -1;
    T68000(scopy->Sidnum = 0;)
    if (scopy->Sdt)
        dtsymsize(scopy);
    if (scopy->Sflags & (SFLvalue | SFLdtorexp))
        scopy->Svalue = el_copytree(s->Svalue);
    t = scopy->Stype;
    if (t)
    {   t->Tcount++;            /* one more parent of the type  */
        type_debug(t);
    }
    return scopy;
}

/*******************************
 * Search list for a symbol with an identifier that matches.
 * Returns:
 *      pointer to matching symbol
 *      NULL if not found
 */

#if SCPP

symbol * symbol_searchlist(symlist_t sl,const char *vident)
{   symbol *s;
#ifdef DEBUG
    int count = 0;
#endif

    //dbg_printf("searchlist(%s)\n",vident);
    for (; sl; sl = list_next(sl))
    {   s = list_symbol(sl);
        symbol_debug(s);
        /*dbg_printf("\tcomparing with %s\n",s->Sident);*/
        if (strcmp(vident,s->Sident) == 0)
            return s;
#ifdef DEBUG
        assert(++count < 300);          /* prevent infinite loops       */
#endif
    }
    return NULL;
}

/***************************************
 * Search for symbol in sequence of symbol tables.
 * Input:
 *      glbl    !=0 if global symbol table only
 */

symbol *symbol_search(const char *id)
{
    Scope *sc;
    if (CPP)
    {   unsigned sct;

        sct = pstate.STclasssym ? SCTclass : 0;
        sct |= SCTmfunc | SCTlocal | SCTwith | SCTglobal | SCTnspace | SCTtemparg | SCTtempsym;
        return scope_searchx(id,sct,&sc);
    }
    else
        return scope_searchx(id,SCTglobal | SCTlocal,&sc);
}

#endif

/*******************************************
 * Hydrate a symbol tree.
 */

#if HYDRATE
void symbol_tree_hydrate(symbol **ps)
{   symbol *s;

    while (isdehydrated(*ps))           /* if symbol is dehydrated      */
    {
        s = symbol_hydrate(ps);
        symbol_debug(s);
        if (s->Scover)
            symbol_hydrate(&s->Scover);
        symbol_tree_hydrate(&s->Sl);
        ps = &s->Sr;
    }

}
#endif

/*******************************************
 * Dehydrate a symbol tree.
 */

#if DEHYDRATE
void symbol_tree_dehydrate(symbol **ps)
{   symbol *s;

    while ((s = *ps) != NULL && !isdehydrated(s)) /* if symbol exists   */
    {
        symbol_debug(s);
        symbol_dehydrate(ps);
#if DEBUG_XSYMGEN
        if (xsym_gen && ph_in_head(s))
            return;
#endif
        symbol_dehydrate(&s->Scover);
        symbol_tree_dehydrate(&s->Sl);
        ps = &s->Sr;
    }
}
#endif

/*******************************************
 * Hydrate a symbol.
 */

#if HYDRATE
symbol *symbol_hydrate(symbol **ps)
{   symbol *s;

    s = *ps;
    if (isdehydrated(s))                /* if symbol is dehydrated      */
    {   type *t;
        struct_t *st;

        s = (symbol *) ph_hydrate(ps);
#ifdef DEBUG
        debugy && dbg_printf("symbol_hydrate('%s')\n",s->Sident);
#endif
        symbol_debug(s);
        if (!isdehydrated(s->Stype))    // if this symbol is already dehydrated
            return s;                   // no need to do it again
#if SOURCE_4SYMS
        s->Ssrcpos.Sfilnum += File_Hydrate_Num; /* file number relative header build */
#endif
        T68000(file_progress();)
        if (pstate.SThflag != FLAG_INPLACE && s->Sfl != FLreg)
            s->Sxtrnnum = 0;            // not written to .OBJ file yet
        type_hydrate(&s->Stype);
        //dbg_printf("symbol_hydrate(%p, '%s', t = %p)\n",s,s->Sident,s->Stype);
        t = s->Stype;
        if (t)
            type_debug(t);

        if (t && tyfunc(t->Tty) && ph_hydrate(&s->Sfunc))
        {
            func_t *f = s->Sfunc;
            SYMIDX si;

            debug(assert(f));

            list_hydrate(&f->Fsymtree,(list_free_fp)symbol_tree_hydrate);
            blocklist_hydrate(&f->Fstartblock);

            ph_hydrate(&f->Flocsym.tab);
            for (si = 0; si < f->Flocsym.top; si++)
                symbol_hydrate(&f->Flocsym.tab[si]);

            srcpos_hydrate(&f->Fstartline);
            srcpos_hydrate(&f->Fendline);

            symbol_hydrate(&f->F__func__);

            if (CPP)
            {
                symbol_hydrate(&f->Fparsescope);
                Classsym_hydrate(&f->Fclass);
                symbol_hydrate(&f->Foversym);
                symbol_hydrate(&f->Fexplicitspec);
                symbol_hydrate(&f->Fsurrogatesym);

                list_hydrate(&f->Fclassfriends,(list_free_fp)symbol_hydrate);
                el_hydrate(&f->Fbaseinit);
                token_hydrate(&f->Fbody);
                symbol_hydrate(&f->Falias);
                list_hydrate(&f->Fthunks,(list_free_fp)symbol_hydrate);
                if (f->Fflags & Finstance)
                    symbol_hydrate(&f->Ftempl);
                else
                    thunk_hydrate(&f->Fthunk);
                param_hydrate(&f->Farglist);
                param_hydrate(&f->Fptal);
                list_hydrate(&f->Ffwdrefinstances,(list_free_fp)symbol_hydrate);
                list_hydrate(&f->Fexcspec,(list_free_fp)type_hydrate);
            }
#if TARGET_MAC
            if (s->Sdirect && s->Sflags&SFLdirect && !(s->Sflags&SFLsmdir))
                ph_hydrate(&s->Sdirect);
#endif
        }
#if (TARGET_MAC)
        if(s->Sflags & SFLpasmeth)
            {
            symbol_hydrate(&s->Smethod);
            //dbg_printf("SFLpasmeth symbol %s\n",s->Sident);
            }
#endif
        if (CPP)
            symbol_hydrate(&s->Sscope);
        switch (s->Sclass)
        {
            case SCstruct:
              if (CPP)
              {
                st = (struct_t *) ph_hydrate(&s->Sstruct);
                assert(st);
                symbol_tree_hydrate(&st->Sroot);
                ph_hydrate(&st->Spvirtder);
                list_hydrate(&st->Sfldlst,(list_free_fp)symbol_hydrate);
                list_hydrate(&st->Svirtual,(list_free_fp)mptr_hydrate);
                list_hydrate(&st->Sopoverload,(list_free_fp)symbol_hydrate);
                list_hydrate(&st->Scastoverload,(list_free_fp)symbol_hydrate);
                list_hydrate(&st->Sclassfriends,(list_free_fp)symbol_hydrate);
                list_hydrate(&st->Sfriendclass,(list_free_fp)symbol_hydrate);
                list_hydrate(&st->Sfriendfuncs,(list_free_fp)symbol_hydrate);
                assert(!st->Sinlinefuncs);

                baseclass_hydrate(&st->Sbase);
                baseclass_hydrate(&st->Svirtbase);
                baseclass_hydrate(&st->Smptrbase);
                baseclass_hydrate(&st->Sprimary);
#if VBTABLES
                baseclass_hydrate(&st->Svbptrbase);
#endif

                ph_hydrate(&st->Svecctor);
                ph_hydrate(&st->Sctor);
                ph_hydrate(&st->Sdtor);
#if VBTABLES
                ph_hydrate(&st->Sprimdtor);
                ph_hydrate(&st->Spriminv);
                ph_hydrate(&st->Sscaldeldtor);
#endif
                ph_hydrate(&st->Sinvariant);
                ph_hydrate(&st->Svptr);
                ph_hydrate(&st->Svtbl);
                ph_hydrate(&st->Sopeq);
                ph_hydrate(&st->Sopeq2);
                ph_hydrate(&st->Scpct);
                ph_hydrate(&st->Sveccpct);
                ph_hydrate(&st->Salias);
                ph_hydrate(&st->Stempsym);
                param_hydrate(&st->Sarglist);
                param_hydrate(&st->Spr_arglist);
#if VBTABLES
                ph_hydrate(&st->Svbptr);
                ph_hydrate(&st->Svbptr_parent);
                ph_hydrate(&st->Svbtbl);
#endif
              }
              else
              {
                ph_hydrate(&s->Sstruct);
                symbol_tree_hydrate(&s->Sstruct->Sroot);
                list_hydrate(&s->Sstruct->Sfldlst,(list_free_fp)symbol_hydrate);
              }
                break;

            case SCenum:
                assert(s->Senum);
                ph_hydrate(&s->Senum);
                if (CPP)
                {   ph_hydrate(&s->Senum->SEalias);
                    list_hydrate(&s->Senumlist,(list_free_fp)symbol_hydrate);
                }
                break;

            case SCtemplate:
            {   template_t *tm;

                tm = (template_t *) ph_hydrate(&s->Stemplate);
                list_hydrate(&tm->TMinstances,(list_free_fp)symbol_hydrate);
                list_hydrate(&tm->TMfriends,(list_free_fp)symbol_hydrate);
                param_hydrate(&tm->TMptpl);
                param_hydrate(&tm->TMptal);
                token_hydrate(&tm->TMbody);
                list_hydrate(&tm->TMmemberfuncs,(list_free_fp)tmf_hydrate);
                list_hydrate(&tm->TMexplicit,(list_free_fp)tme_hydrate);
                list_hydrate(&tm->TMnestedexplicit,(list_free_fp)tmne_hydrate);
                list_hydrate(&tm->TMnestedfriends,(list_free_fp)tmnf_hydrate);
                ph_hydrate(&tm->TMnext);
                symbol_hydrate(&tm->TMpartial);
                symbol_hydrate(&tm->TMprimary);
                break;
            }

            case SCnamespace:
                symbol_tree_hydrate(&s->Snameroot);
                list_hydrate(&s->Susing,(list_free_fp)symbol_hydrate);
                break;

            case SCmemalias:
            case SCfuncalias:
            case SCadl:
                list_hydrate(&s->Spath,(list_free_fp)symbol_hydrate);
            case SCalias:
                ph_hydrate(&s->Smemalias);
                break;

            default:
                if (s->Sflags & (SFLvalue | SFLdtorexp))
                    el_hydrate(&s->Svalue);
                break;
        }
        {   dt_t **pdt,*dt;

            for (pdt = &s->Sdt; isdehydrated(*pdt); pdt = &dt->DTnext)
            {
                dt = (dt_t *) ph_hydrate(pdt);
                switch (dt->dt)
                {   case DT_abytes:
                    case DT_nbytes:
                        ph_hydrate(&dt->DTpbytes);
                        break;
                    case DT_xoff:
                        symbol_hydrate(&dt->DTsym);
                        break;
                }
            }
        }
        if (s->Scover)
            symbol_hydrate(&s->Scover);
    }
    return s;
}
#endif

/*******************************************
 * Dehydrate a symbol.
 */

#if DEHYDRATE
void symbol_dehydrate(symbol **ps)
{
    symbol *s;

    if ((s = *ps) != NULL && !isdehydrated(s)) /* if symbol exists      */
    {   type *t;
        struct_t *st;

#ifdef DEBUG
        if (debugy)
            dbg_printf("symbol_dehydrate('%s')\n",s->Sident);
#endif
        ph_dehydrate(ps);
#if DEBUG_XSYMGEN
        if (xsym_gen && ph_in_head(s))
            return;
#endif
        T68000(file_progress();)
        symbol_debug(s);
        t = s->Stype;
        if (isdehydrated(t))
            return;
        type_dehydrate(&s->Stype);

        if (tyfunc(t->Tty) && !isdehydrated(s->Sfunc))
        {
            func_t *f = s->Sfunc;
            SYMIDX si;

            debug(assert(f));
            ph_dehydrate(&s->Sfunc);

            list_dehydrate(&f->Fsymtree,(list_free_fp)symbol_tree_dehydrate);
            blocklist_dehydrate(&f->Fstartblock);
            assert(!isdehydrated(&f->Flocsym.tab));

#if DEBUG_XSYMGEN
            if (!xsym_gen || !ph_in_head(f->Flocsym.tab))

#endif
            for (si = 0; si < f->Flocsym.top; si++)
                symbol_dehydrate(&f->Flocsym.tab[si]);
            ph_dehydrate(&f->Flocsym.tab);

            srcpos_dehydrate(&f->Fstartline);
            srcpos_dehydrate(&f->Fendline);
            symbol_dehydrate(&f->F__func__);
            if (CPP)
            {
            symbol_dehydrate(&f->Fparsescope);
            ph_dehydrate(&f->Fclass);
            symbol_dehydrate(&f->Foversym);
            symbol_dehydrate(&f->Fexplicitspec);
            symbol_dehydrate(&f->Fsurrogatesym);

            list_dehydrate(&f->Fclassfriends,FPNULL);
            el_dehydrate(&f->Fbaseinit);
#if DEBUG_XSYMGEN
            if (xsym_gen && s->Sclass == SCfunctempl)
                ph_dehydrate(&f->Fbody);
            else
#endif
            token_dehydrate(&f->Fbody);
            symbol_dehydrate(&f->Falias);
            list_dehydrate(&f->Fthunks,(list_free_fp)symbol_dehydrate);
            if (f->Fflags & Finstance)
                symbol_dehydrate(&f->Ftempl);
            else
                thunk_dehydrate(&f->Fthunk);
#if !TX86 && DEBUG_XSYMGEN
            if (xsym_gen && s->Sclass == SCfunctempl)
                ph_dehydrate(&f->Farglist);
            else
#endif
            param_dehydrate(&f->Farglist);
            param_dehydrate(&f->Fptal);
            list_dehydrate(&f->Ffwdrefinstances,(list_free_fp)symbol_dehydrate);
            list_dehydrate(&f->Fexcspec,(list_free_fp)type_dehydrate);
            }
#if TARGET_MAC
            if (s->Sdirect && s->Sflags&SFLdirect && !(s->Sflags&SFLsmdir))
                ph_dehydrate(&s->Sdirect);
#endif
        }
#if (TARGET_MAC)
        if(s->Sflags & SFLpasmeth)
            {
            symbol_dehydrate(&s->Smethod);
            //dbg_printf("SFLpasmeth %s\n",s->Sident);
            }
#endif
        if (CPP)
            ph_dehydrate(&s->Sscope);
        switch (s->Sclass)
        {
            case SCstruct:
              if (CPP)
              {
                st = s->Sstruct;
                if (isdehydrated(st))
                    break;
                ph_dehydrate(&s->Sstruct);
                assert(st);
                symbol_tree_dehydrate(&st->Sroot);
                ph_dehydrate(&st->Spvirtder);
                list_dehydrate(&st->Sfldlst,(list_free_fp)symbol_dehydrate);
                list_dehydrate(&st->Svirtual,(list_free_fp)mptr_dehydrate);
                list_dehydrate(&st->Sopoverload,(list_free_fp)symbol_dehydrate);
                list_dehydrate(&st->Scastoverload,(list_free_fp)symbol_dehydrate);
                list_dehydrate(&st->Sclassfriends,(list_free_fp)symbol_dehydrate);
                list_dehydrate(&st->Sfriendclass,(list_free_fp)ph_dehydrate);
                list_dehydrate(&st->Sfriendfuncs,(list_free_fp)ph_dehydrate);
                assert(!st->Sinlinefuncs);

                baseclass_dehydrate(&st->Sbase);
                baseclass_dehydrate(&st->Svirtbase);
                baseclass_dehydrate(&st->Smptrbase);
                baseclass_dehydrate(&st->Sprimary);
#if VBTABLES
                baseclass_dehydrate(&st->Svbptrbase);
#endif

                ph_dehydrate(&st->Svecctor);
                ph_dehydrate(&st->Sctor);
                ph_dehydrate(&st->Sdtor);
#if VBTABLES
                ph_dehydrate(&st->Sprimdtor);
                ph_dehydrate(&st->Spriminv);
                ph_dehydrate(&st->Sscaldeldtor);
#endif
                ph_dehydrate(&st->Sinvariant);
                ph_dehydrate(&st->Svptr);
                ph_dehydrate(&st->Svtbl);
                ph_dehydrate(&st->Sopeq);
                ph_dehydrate(&st->Sopeq2);
                ph_dehydrate(&st->Scpct);
                ph_dehydrate(&st->Sveccpct);
                ph_dehydrate(&st->Salias);
                ph_dehydrate(&st->Stempsym);
                param_dehydrate(&st->Sarglist);
                param_dehydrate(&st->Spr_arglist);
#if VBTABLES
                ph_dehydrate(&st->Svbptr);
                ph_dehydrate(&st->Svbptr_parent);
                ph_dehydrate(&st->Svbtbl);
#endif
              }
              else
              {
                symbol_tree_dehydrate(&s->Sstruct->Sroot);
                list_dehydrate(&s->Sstruct->Sfldlst,(list_free_fp)symbol_dehydrate);
                ph_dehydrate(&s->Sstruct);
              }
                break;

            case SCenum:
                assert(s->Senum);
                if (!isdehydrated(s->Senum))
                {
                    if (CPP)
                    {   ph_dehydrate(&s->Senum->SEalias);
                        list_dehydrate(&s->Senumlist,(list_free_fp)ph_dehydrate);
                    }
                    ph_dehydrate(&s->Senum);
                }
                break;

            case SCtemplate:
            {   template_t *tm;

                tm = s->Stemplate;
                if (!isdehydrated(tm))
                {
                    ph_dehydrate(&s->Stemplate);
                    list_dehydrate(&tm->TMinstances,(list_free_fp)symbol_dehydrate);
                    list_dehydrate(&tm->TMfriends,(list_free_fp)symbol_dehydrate);
                    list_dehydrate(&tm->TMnestedfriends,(list_free_fp)tmnf_dehydrate);
                    param_dehydrate(&tm->TMptpl);
                    param_dehydrate(&tm->TMptal);
                    token_dehydrate(&tm->TMbody);
                    list_dehydrate(&tm->TMmemberfuncs,(list_free_fp)tmf_dehydrate);
                    list_dehydrate(&tm->TMexplicit,(list_free_fp)tme_dehydrate);
                    list_dehydrate(&tm->TMnestedexplicit,(list_free_fp)tmne_dehydrate);
                    ph_dehydrate(&tm->TMnext);
                    symbol_dehydrate(&tm->TMpartial);
                    symbol_dehydrate(&tm->TMprimary);
                }
                break;
            }

            case SCnamespace:
                symbol_tree_dehydrate(&s->Snameroot);
                list_dehydrate(&s->Susing,(list_free_fp)symbol_dehydrate);
                break;

            case SCmemalias:
            case SCfuncalias:
            case SCadl:
                list_dehydrate(&s->Spath,(list_free_fp)symbol_dehydrate);
            case SCalias:
                ph_dehydrate(&s->Smemalias);
                break;

            default:
                if (s->Sflags & (SFLvalue | SFLdtorexp))
                    el_dehydrate(&s->Svalue);
                break;
        }
        {   dt_t **pdt,*dt;

            for (pdt = &s->Sdt;
                 (dt = *pdt) != NULL && !isdehydrated(dt);
                 pdt = &dt->DTnext)
            {
                ph_dehydrate(pdt);
                switch (dt->dt)
                {   case DT_abytes:
                    case DT_nbytes:
                        ph_dehydrate(&dt->DTpbytes);
                        break;
                    case DT_xoff:
                        symbol_dehydrate(&dt->DTsym);
                        break;
                }
            }
        }
        if (s->Scover)
            symbol_dehydrate(&s->Scover);
    }
}
#endif

/***************************
 * Dehydrate threaded list of symbols.
 */

#if DEHYDRATE
void symbol_symdefs_dehydrate(symbol **ps)
{
    symbol *s;

    for (; *ps; ps = &s->Snext)
    {
        s = *ps;
        symbol_debug(s);
        //dbg_printf("symbol_symdefs_dehydrate(%p, '%s')\n",s,s->Sident);
        symbol_dehydrate(ps);
    }
}
#endif

/***************************
 * Hydrate threaded list of symbols.
 * Input:
 *      *ps     start of threaded list
 *      *parent root of symbol table to add symbol into
 *      flag    !=0 means add onto existing stuff
 *              0 means hydrate in place
 */

#if SCPP

void symbol_symdefs_hydrate(symbol **ps,symbol **parent,int flag)
{   symbol *s;

    //printf("symbol_symdefs_hydrate(flag = %d)\n",flag);
#ifdef DEBUG
    int count = 0;

    if (flag) symbol_tree_check(*parent);
#endif
    for (; *ps; ps = &s->Snext)
    {
        //dbg_printf("%p ",*ps);
#ifdef DEBUG
        count++;
#endif
        s = dohydrate ? symbol_hydrate(ps) : *ps;

        //if (s->Sclass == SCstruct)
        //dbg_printf("symbol_symdefs_hydrate(%p, '%s')\n",s,s->Sident);
        symbol_debug(s);
#if 0
        if (tyfunc(s->Stype->Tty))
        {   Outbuffer buf;
            char *p1;

            p1 = param_tostring(&buf,s->Stype);
            dbg_printf("'%s%s'\n",cpp_prettyident(s),p1);
        }
#endif
        type_debug(s->Stype);
        if (flag)
        {   char *p;
            symbol **ps;
            symbol *rover;
            char c;
            size_t len;

            p = s->Sident;
            c = *p;
            if (CPP)
            {
#if HOST_MPW
            if (c == '_' &&  (strcmp(p,"__pasmeth") == 0))
                continue;               // predefined struct, can't define twice
#endif
#if TARGET_MAC
            if (c == '_' &&  ((strcmp(p,"__pasmeth") == 0)
                || (strcmp(p, cpp_name_pasnew) == 0)))
                continue;               // predefined names, can't define twice
#endif
            }
            // Put symbol s into symbol table

#if MMFIO
            if (s->Sl || s->Sr)         // avoid writing to page if possible
#endif
                s->Sl = s->Sr = NULL;
            len = strlen(p);
            p++;
            ps = parent;
            while ((rover = *ps) != NULL)
            {   signed char cmp;

                if ((cmp = c - rover->Sident[0]) == 0)
                {   cmp = memcmp(p,rover->Sident + 1,len); // compare identifier strings
                    if (cmp == 0)
                    {
                        if (CPP && tyfunc(s->Stype->Tty) && tyfunc(rover->Stype->Tty))
                        {   symbol **ps;
                            symbol *sn;
                            symbol *so;

                            so = s;
                            do
                            {
                                // Tack onto end of overloaded function list
                                for (ps = &rover; *ps; ps = &(*ps)->Sfunc->Foversym)
                                {   if (cpp_funccmp(so, *ps))
                                    {   //printf("function '%s' already in list\n",so->Sident);
                                        goto L2;
                                    }
                                }
                                //printf("appending '%s' to rover\n",so->Sident);
                                *ps = so;
                            L2:
                                sn = so->Sfunc->Foversym;
                                so->Sfunc->Foversym = NULL;
                                so = sn;
                            } while (so);
                            //printf("overloading...\n");
                        }
                        else if (s->Sclass == SCstruct)
                        {
                            if (CPP && rover->Scover)
                            {   ps = &rover->Scover;
                                rover = *ps;
                            }
                            else
                            if (rover->Sclass == SCstruct)
                            {
                                if (!(s->Stype->Tflags & TFforward))
                                {   // Replace rover with s in symbol table
                                    //printf("Replacing '%s'\n",s->Sident);
                                    *ps = s;
                                    s->Sl = rover->Sl;
                                    s->Sr = rover->Sr;
                                    rover->Sl = rover->Sr = NULL;
                                    rover->Stype->Ttag = (Classsym *)s;
                                    symbol_keep(rover);
                                }
                                else
                                    s->Stype->Ttag = (Classsym *)rover;
                            }
                        }
                        goto L1;
                    }
                }
                ps = (cmp < 0) ?        /* if we go down left side      */
                    &rover->Sl :
                    &rover->Sr;
            }
            *ps = s;
            if (s->Sclass == SCcomdef)
            {   s->Sclass = SCglobal;
                outcommon(s,type_size(s->Stype));
            }
        }
  L1:   ;
    } // for
#ifdef DEBUG
    if (flag) symbol_tree_check(*parent);
    printf("%d symbols hydrated\n",count);
#endif
}

#endif

#if 0

/*************************************
 * Put symbol table s into parent symbol table.
 */

#if TARGET_MAC
extern char cpp_name_pasnew[];
#endif

void symboltable_hydrate(symbol *s,symbol **parent)
{
    while (s)
    {   symbol *sl,*sr;
        char *p;

        symbol_debug(s);

        sl = s->Sl;
        sr = s->Sr;
        p = s->Sident;

        //dbg_printf("symboltable_hydrate('%s')\n",p);

#if HOST_MPW
        if(p[0] == '_' &&  (strcmp(p,"__pasmeth") == 0))
            goto L1;            /* predefined struct, can't define twice */
#endif
#if (TARGET_MAC)
        if (p[0] == '_' &&  ((strcmp(p,"__pasmeth") == 0)
            || (strcmp(p, cpp_name_pasnew) == 0)))
            goto L1;            /* predefined names, can't define twice */
#endif

        /* Put symbol s into symbol table       */
        {   symbol **ps;
            symbol *rover;
            int c = *p;

            ps = parent;
            while ((rover = *ps) != NULL)
            {   int cmp;

                if ((cmp = c - rover->Sident[0]) == 0)
                {   cmp = strcmp(p,rover->Sident); /* compare identifier strings */
                    if (cmp == 0)
                    {
                        if (CPP && tyfunc(s->Stype->Tty) && tyfunc(rover->Stype->Tty))
                        {   symbol **ps;
                            symbol *sn;

                            do
                            {
                                // Tack onto end of overloaded function list
                                for (ps = &rover; *ps; ps = &(*ps)->Sfunc->Foversym)
                                {   if (cpp_funccmp(s, *ps))
                                        goto L2;
                                }
                                s->Sl = s->Sr = NULL;
                                *ps = s;
                            L2:
                                sn = s->Sfunc->Foversym;
                                s->Sfunc->Foversym = NULL;
                                s = sn;
                            } while (s);
                        }
                        else
                        {
                            if (!typematch(s->Stype,rover->Stype,0))
                            {
                                // cpp_predefine() will define this again
                                if (type_struct(rover->Stype) &&
                                    rover->Sstruct->Sflags & STRpredef)
                                {   s->Sl = s->Sr = NULL;
                                    symbol_keep(s);
                                }
                                else
                                    synerr(EM_multiple_def,p);  // already defined
                            }
                        }
                        goto L1;
                    }
                }
                ps = (cmp < 0) ?        /* if we go down left side      */
                    &rover->Sl :
                    &rover->Sr;
            }
            {
                s->Sl = s->Sr = NULL;
                *ps = s;
            }
        }
    L1:
        symboltable_hydrate(sl,parent);
        s = sr;
    }
}

#endif


/************************************
 * Hydrate/dehydrate an mptr_t.
 */

#if HYDRATE
STATIC void mptr_hydrate(mptr_t **pm)
{   mptr_t *m;

    m = (mptr_t *) ph_hydrate(pm);
    symbol_hydrate(&m->MPf);
    symbol_hydrate(&m->MPparent);
}
#endif

#if DEHYDRATE
STATIC void mptr_dehydrate(mptr_t **pm)
{   mptr_t *m;

    m = *pm;
    if (m && !isdehydrated(m))
    {
        ph_dehydrate(pm);
#if DEBUG_XSYMGEN
        if (xsym_gen && ph_in_head(m->MPf))
            ph_dehydrate(&m->MPf);
        else
#endif
        symbol_dehydrate(&m->MPf);
        symbol_dehydrate(&m->MPparent);
    }
}
#endif

/************************************
 * Hydrate/dehydrate a baseclass_t.
 */

#if HYDRATE
STATIC void baseclass_hydrate(baseclass_t **pb)
{   baseclass_t *b;

    assert(pb);
    while (isdehydrated(*pb))
    {
        b = (baseclass_t *) ph_hydrate(pb);

        ph_hydrate(&b->BCbase);
        ph_hydrate(&b->BCpbase);
        list_hydrate(&b->BCpublics,(list_free_fp)symbol_hydrate);
#if VBTABLES
#else
        symbol_hydrate(&b->param);
#endif
        list_hydrate(&b->BCmptrlist,(list_free_fp)mptr_hydrate);
        symbol_hydrate(&b->BCvtbl);
        Classsym_hydrate(&b->BCparent);

        pb = &b->BCnext;
    }
}
#endif

/**********************************
 * Dehydrate a baseclass_t.
 */

#if DEHYDRATE
STATIC void baseclass_dehydrate(baseclass_t **pb)
{   baseclass_t *b;

    while ((b = *pb) != NULL && !isdehydrated(b))
    {
        ph_dehydrate(pb);

#if DEBUG_XSYMGEN
        if (xsym_gen && ph_in_head(b))
            return;
#endif

        ph_dehydrate(&b->BCbase);
        ph_dehydrate(&b->BCpbase);
        list_dehydrate(&b->BCpublics,(list_free_fp)symbol_dehydrate);
#if VBTABLES
#else
        symbol_dehydrate(&b->param);
#endif
        list_dehydrate(&b->BCmptrlist,(list_free_fp)mptr_dehydrate);
        symbol_dehydrate(&b->BCvtbl);
        Classsym_dehydrate(&b->BCparent);

        pb = &b->BCnext;
    }
}
#endif

/***************************
 * Look down baseclass list to find sbase.
 * Returns:
 *      NULL    not found
 *      pointer to baseclass
 */

baseclass_t *baseclass_find(baseclass_t *bm,Classsym *sbase)
{
    symbol_debug(sbase);
    for (; bm; bm = bm->BCnext)
        if (bm->BCbase == sbase)
            break;
    return bm;
}

baseclass_t *baseclass_find_nest(baseclass_t *bm,Classsym *sbase)
{
    symbol_debug(sbase);
    for (; bm; bm = bm->BCnext)
    {
        if (bm->BCbase == sbase ||
            baseclass_find_nest(bm->BCbase->Sstruct->Sbase, sbase))
            break;
    }
    return bm;
}

/******************************
 * Calculate number of baseclasses in list.
 */

#if VBTABLES

int baseclass_nitems(baseclass_t *b)
{   int i;

    for (i = 0; b; b = b->BCnext)
        i++;
    return i;
}

#endif


/*****************************
 * Go through symbol table preparing it to be written to a precompiled
 * header. That means removing references to things in the .OBJ file.
 */

#if SCPP

void symboltable_clean(symbol *s)
{
    while (s)
    {
        struct_t *st;

        //printf("clean('%s')\n",s->Sident);
        if (config.fulltypes != CVTDB && s->Sxtrnnum && s->Sfl != FLreg)
            s->Sxtrnnum = 0;    // eliminate debug info type index
        switch (s->Sclass)
        {
            case SCstruct:
                s->Stypidx = 0;
                st = s->Sstruct;
                assert(st);
                symboltable_clean(st->Sroot);
                //list_apply(&st->Sfldlst,(list_free_fp)symboltable_clean);
                break;

            case SCtypedef:
            case SCenum:
                s->Stypidx = 0;
                break;
#if 1
            case SCtemplate:
            {   template_t *tm = s->Stemplate;

                list_apply(&tm->TMinstances,(list_free_fp)symboltable_clean);
                break;
            }
#endif
            case SCnamespace:
                symboltable_clean(s->Snameroot);
                break;

            default:
                if (s->Sxtrnnum && s->Sfl != FLreg)
                    s->Sxtrnnum = 0;    // eliminate external symbol index
                if (tyfunc(s->Stype->Tty))
                {
                    func_t *f = s->Sfunc;
                    SYMIDX si;

                    debug(assert(f));

                    list_apply(&f->Fsymtree,(list_free_fp)symboltable_clean);
                    for (si = 0; si < f->Flocsym.top; si++)
                        symboltable_clean(f->Flocsym.tab[si]);
                    if (f->Foversym)
                        symboltable_clean(f->Foversym);
                    if (f->Fexplicitspec)
                        symboltable_clean(f->Fexplicitspec);
                }
                break;
        }
        if (s->Sl)
            symboltable_clean(s->Sl);
        if (s->Scover)
            symboltable_clean(s->Scover);
        s = s->Sr;
    }
}

#endif

#if SCPP

/*
 * Balance our symbol tree in place. This is nice for precompiled headers, since they
 * will typically be written out once, but read in many times. We balance the tree in
 * place by traversing the tree inorder and writing the pointers out to an ordered
 * list. Once we have a list of symbol pointers, we can create a tree by recursively
 * dividing the list, using the midpoint of each division as the new root for that
 * subtree.
 */

struct Balance
{
    unsigned nsyms;
    symbol **array;
    unsigned index;
};

static Balance balance;

STATIC void count_symbols(symbol *s)
{
    while (s)
    {
        balance.nsyms++;
        switch (s->Sclass)
        {
            case SCnamespace:
                symboltable_balance(&s->Snameroot);
                break;

            case SCstruct:
                symboltable_balance(&s->Sstruct->Sroot);
                break;
        }
        count_symbols(s->Sl);
        s = s->Sr;
    }
}

STATIC void place_in_array(symbol *s)
{
    while (s)
    {
        place_in_array(s->Sl);
        balance.array[balance.index++] = s;
        s = s->Sr;
    }
}

/*
 * Create a tree in place by subdividing between lo and hi inclusive, using i
 * as the root for the tree. When the lo-hi interval is one, we've either
 * reached a leaf or an empty node. We subdivide below i by halving the interval
 * between i and lo, and using i-1 as our new hi point. A similar subdivision
 * is created above i.
 */
STATIC symbol * create_tree(int i, int lo, int hi)
{
    symbol *s = balance.array[i];

    if (i < lo || i > hi)               /* empty node ? */
        return NULL;

    assert((unsigned) i < balance.nsyms);
    if (i == lo && i == hi) {           /* leaf node ? */
        s->Sl = NULL;
        s->Sr = NULL;
        return s;
    }

    s->Sl = create_tree((i + lo) / 2, lo, i - 1);
    s->Sr = create_tree((i + hi + 1) / 2, i + 1, hi);

    return s;
}

#define METRICS 0

#if METRICS
void symbol_table_metrics(void);
#if TARGET_MAC
pascal unsigned long TickCount(void)
    = 0xA975;
#endif
#endif

void symboltable_balance(symbol **ps)
{
    Balance balancesave;
#if METRICS
    long ticks;

    dbg_printf("symbol table before balance:\n");
    symbol_table_metrics();
    T68000(ticks = TickCount();)
    T80x86(ticks = clock();)
#endif
    balancesave = balance;              // so we can nest
    balance.nsyms = 0;
    count_symbols(*ps);
    //dbg_printf("Number of global symbols = %d\n",balance.nsyms);

#if __INTSIZE == 2
    // Don't balance tree if we get 16 bit overflow
    if (balance.nsyms >= (unsigned)(0x10000 / sizeof(symbol *)))
        goto Lret;
#endif

#if TARGET_MAC
    balance.array = (symbol **) MEM_PARF_MALLOC(balance.nsyms * sizeof(symbol *));
#else
    // Use malloc instead of mem because of pagesize limits
    balance.array = (symbol **) malloc(balance.nsyms * sizeof(symbol *));
#endif
    if (!balance.array)
        goto Lret;                      // no error, just don't balance

    balance.index = 0;
    place_in_array(*ps);

    *ps = create_tree(balance.nsyms / 2, 0, balance.nsyms - 1);

    T68000(release_temp_memory();)
    T80x86(free(balance.array);)
#if METRICS
#if TARGET_MAC
    dbg_printf("time to balance: %.2f\n", (TickCount() - ticks) / 60.0);
#else
    dbg_printf("time to balance: %ld\n", clock() - ticks);
#endif
    dbg_printf("symbol table after balance:\n");
    symbol_table_metrics();
#endif
Lret:
    balance = balancesave;
}

#endif

/*****************************************
 * Symbol table search routine for members of structs, given that
 * we don't know which struct it is in.
 * Give error message if it appears more than once.
 * Returns:
 *      NULL            member not found
 *      symbol*         symbol matching member
 */

#if SCPP

struct Paramblock       // to minimize stack usage in helper function
{   const char *id;     // identifier we are looking for
    symbol *sm;         // where to put result
    symbol *s;
};

STATIC void membersearchx(struct Paramblock *p,symbol *s)
{   symbol *sm;
    list_t sl;

    while (s)
    {   symbol_debug(s);

        switch (s->Sclass)
        {   case SCstruct:
                for (sl = s->Sstruct->Sfldlst; sl; sl = list_next(sl))
                {   sm = list_symbol(sl);
                    symbol_debug(sm);
                    if ((sm->Sclass == SCmember || sm->Sclass == SCfield) &&
                        strcmp(p->id,sm->Sident) == 0)
                    {
                        if (p->sm && p->sm->Smemoff != sm->Smemoff)
                            synerr(EM_ambig_member,p->id,s->Sident,p->s->Sident);       // ambiguous reference to id
                        p->s = s;
                        p->sm = sm;
                        break;
                    }
                }
                break;
        }

        if (s->Sl)
            membersearchx(p,s->Sl);
        s = s->Sr;
    }
}

symbol *symbol_membersearch(const char *id)
{
    list_t sl;
    struct Paramblock pb;
    Scope *sc;

    pb.id = id;
    pb.sm = NULL;
    for (sc = scope_end; sc; sc = sc->next)
    {
        if (sc->sctype & (CPP ? (SCTglobal | SCTlocal) : (SCTglobaltag | SCTtag)))
            membersearchx((struct Paramblock *)&pb,(symbol *)sc->root);
    }
    return pb.sm;
}

/*******************************************
 * Generate debug info for global struct tag symbols.
 */

STATIC void symbol_gendebuginfox(symbol *s)
{
    for (; s; s = s->Sr)
    {
        if (s->Sl)
            symbol_gendebuginfox(s->Sl);
        if (s->Scover)
            symbol_gendebuginfox(s->Scover);
        switch (s->Sclass)
        {
            case SCenum:
                if (CPP && s->Senum->SEflags & SENnotagname)
                    break;
                goto Lout;
            case SCstruct:
                if (s->Sstruct->Sflags & STRanonymous)
                    break;
                goto Lout;
            case SCtypedef:
            Lout:
                if (!s->Stypidx)
                    cv_outsym(s);
                break;
        }
    }
}

void symbol_gendebuginfo()
{   Scope *sc;

    for (sc = scope_end; sc; sc = sc->next)
    {
        if (sc->sctype & (SCTglobaltag | SCTglobal))
            symbol_gendebuginfox((symbol *)sc->root);
    }
}

#endif

#if TARGET_MAC
#include "TGsymbol.c"
#endif

#endif /* !SPP */
