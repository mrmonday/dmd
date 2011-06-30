module bind.statement;

import bind.arraytypes;
import bind.declaration;
import bind.dsymbol;
import bind.expression;
import bind.hdrgen;
import bind.interpret;
import bind.irstate;
import bind.mars;
import bind.mtype;
import bind.root;
import bind.scope_;
import bind.util;

import duffer;

import std.conv;
import std.stdio;

extern(C++):

void statementToJsBuffer(ExpStatement, Duffer);
void statementToJsBuffer(IfStatement, Duffer);
void statementToJsBuffer(ReturnStatement, Duffer);
void statementToJsBuffer(ScopeStatement, Duffer);
void statementToJsBuffer(ForStatement, Duffer);

struct InlineDoState;
struct InlineCostState;
struct InlineScanState;

interface Statement : DmObject
{
    mixin CppFields!(Statement,
        Loc, "loc",
        int, "incontract"
    );
    mixin CppMethods!(Statement,
        "toChars", char*
    );
    
    void foo();
    void bar();

    Statement syntaxCopy();

    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    ScopeStatement isScopeStatement();
    Statement semantic(Scope sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    int isEmpty();
    Statement scopeCode(Scope sc, Statement *sentry, Statement *sexit, Statement *sfinally);
    Statements flatten(Scope sc);
    Expression interpret(InterState *istate);
    Statement last();

    int inlineCost(InlineCostState ics);
    Expression doInline(InlineDoState ids);
    Statement inlineScan(InlineScanState iss);

    // Back end
    void toIR(IRState irs);

    // Avoid dynamic_cast
    ExpStatement isExpStatement();
    CompoundStatement isCompoundStatement();
    ReturnStatement isReturnStatement();
    IfStatement isIfStatement();
    CaseStatement isCaseStatement();
    DefaultStatement isDefaultStatement();
    LabelStatement isLabelStatement();

    final void toJsBuffer(Duffer buf)
    {
        //writefln("statement to buf: %s", to!string(toChars()));
        /*writefln("statement to buf: %s", !!isCompoundStatement());
        writefln("statement to buf: %s", !!isIfStatement());
        writefln("statement to buf: %s", !!isScopeStatement());
        writefln("statement to buf: %s", !!isReturnStatement());*/
        if (auto cs = isCompoundStatement())
        {
            if (cs.statements)
            {
                foreach (Statement s; cs.statements)
                {
                    s.toJsBuffer(buf);
                }
            }
        }
        else if (auto ifs = isIfStatement())
        {
            statementToJsBuffer(ifs, buf);
        }
        else if (auto ss = isScopeStatement())
        {
            statementToJsBuffer(ss, buf);
        }
        else if (auto rs = isReturnStatement())
        {
            statementToJsBuffer(rs, buf);
        }
        else if (auto es = isExpStatement())
        {
            //writefln("expstatement: %s", to!string(toChars()));
            statementToJsBuffer(es, buf);
        }
        else if (auto fs = isForStatement(this))
        {
            statementToJsBuffer(fs, buf);
        }
        else
        {
            assert(0, "unhandled statement: " ~ to!string(toTypeString(this)));
        }
    }
}
mixin(Statement.cppMethods);

const(char*) toTypeString(Statement);
ForStatement isForStatement(Statement);

interface PeelStatement : Statement
{
}

interface ExpStatement : Statement
{
    mixin CppFields!(ExpStatement,
        Expression, "exp"
    );
}

interface CompileStatement : Statement
{
}

interface CompoundStatement : Statement
{
    mixin CppFields!(CompoundStatement,
        Statements, "statements"
    );
}

interface CompoundDeclarationStatement : CompoundStatement
{
}

interface UnrolledLoopStatement : Statement
{
}

interface ScopeStatement : Statement
{
    mixin CppFields!(ScopeStatement,
        Statement, "statement"
    );
}

interface WhileStatement : Statement
{
}

interface DoStatement : Statement
{
}

interface ForStatement : Statement
{
    mixin CppFields!(ForStatement,
        Statement, "init",
        Expression, "condition",
        Expression, "increment",
        Statement, "body_"
    );
}

interface ForeachStatement : Statement
{
}

interface ForeachRangeStatement : Statement
{
}

interface IfStatement : Statement
{
    mixin CppFields!(IfStatement,
        Parameter, "arg",
        Expression, "condition",
        Statement, "ifbody",
        Statement, "elsebody",
        VarDeclaration, "match"
    );
}

interface ConditionalStatement : Statement
{
}

interface PragmaStatement : Statement
{
}

interface StaticAssertStatement : Statement
{
}

interface SwitchStatement : Statement
{
}

interface CaseStatement : Statement
{
}

interface CaseRangeStatement : Statement
{
}

interface DefaultStatement : Statement
{
}

interface GotoDefaultStatement : Statement
{
}

interface GotoCaseStatement : Statement
{
}

interface SwitchErrorStatement : Statement
{
}

interface ReturnStatement : Statement
{
    mixin CppFields!(ReturnStatement,
        Expression, "exp"
    );
}

interface BreakStatement : Statement
{
}

interface ContinueStatement : Statement
{
}

interface SynchronizedStatement : Statement
{
}

interface WithStatement : Statement
{
}

interface TryCatchStatement : Statement
{
}

interface Catch : DmObject
{
}

interface TryFinallyStatement : Statement
{
}

interface OnScopeStatement : Statement
{
}

interface ThrowStatement : Statement
{
}

interface VolatileStatement : Statement
{
}

interface DebugStatement : Statement
{
}

interface GotoStatement : Statement
{
}

interface LabelStatement : Statement
{
}

interface LabelDsymbol : Dsymbol
{
}

interface AsmStatement : Statement
{
}

interface ImportStatement : Statement
{
}
