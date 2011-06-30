module bind.expression;

import bind.arraytypes;
import bind.declaration;
import bind.hdrgen;
import bind.identifier;
import bind.interpret;
import bind.irstate;
import bind.lexer;
import bind.mars;
import bind.mtype;
import bind.root;
import bind.scope_;
import bind.util;

import duffer;
import javascript : unaExpToJsBuffer, binExpToJsBuffer;

import std.conv;
import std.stdio;

extern(C++):

struct InlineCostState;
struct InlineDoState;
struct InlineScanState;

/* Interpreter: what form of return value expression is required?
 */
enum CtfeGoal
{   ctfeNeedRvalue,   // Must return an Rvalue
    ctfeNeedLvalue,   // Must return an Lvalue
    ctfeNeedAnyValue, // Can return either an Rvalue or an Lvalue
    ctfeNeedLvalueRef,// Must return a reference to an Lvalue (for ref types)
    ctfeNeedNothing   // The return value is not required
}

interface Expression : DmObject
{
    mixin CppFields!(Expression,
        Loc, "loc",                    // file location
        TOK, "op",                // handy to minimize use of dynamic_cast
        Type, "type",                 // !=NULL means that semantic() has been run
        ubyte, "size",         // # of bytes in Expression so we can copy() it
        ubyte, "parens"       // if this is a parenthesized expression 
    );
    mixin CppMethods!(Expression,
        "toChars", char*
    );

    void foo();
    void bar();
    Expression syntaxCopy();
    Expression semantic(Scope*sc);
    void dump(int indent);
    void rvalue();
    ulong toInteger();
    ulong toUInteger();
    real toReal();
    real toImaginary();
    creal toComplex();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    int isLvalue();
    Expression toLvalue(Scope sc, Expression e);
    Expression modifiableLvalue(Scope sc, Expression e);
    Expression implicitCastTo(Scope sc, Type t);
    MATCH implicitConvTo(Type t);
    //IntRange getIntRange();
    void getIntRange(); // FIXME
    Expression castTo(Scope sc, Type t);
    void checkEscape();
    void checkEscapeRef();
    Expression resolveLoc(Loc loc, Scope sc);
    Expression checkToBoolean(Scope sc);
    Expression addDtorHook(Scope sc);
    void scanForNestedRef(Scope sc);
    Expression optimize(int result);
    Expression interpret(InterState istate, CtfeGoal goal = CtfeGoal.ctfeNeedRvalue);
    int isConst();
    int isBool(int result);
    int isBit();
    int checkSideEffect(int flag);
    int canThrow(bool mustNotThrow);
    int inlineCost(InlineCostState ics);
    Expression doInline(InlineDoState ids);
    Expression inlineScan(InlineScanState iss);
    int isCommutative();
    Identifier opId();
    Identifier opId_r();
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    //elem toElem(IRState irs);
    //dt_t *toDt(dt_t *pdt);

    final void toJsBuffer(Duffer buf)
    {
        //writefln("expression: %s", to!string(toChars()));
        if (auto ie = isIntegerExp(this))
        {
            buf.write(to!string(ie.toChars()));
        }
        else if (auto aae = isAndAndExp(this))
        {
            binExpToJsBuffer!"&&"(aae, buf);
            //andAndExpToJsBuffer(aae, buf);
        }
        else if (auto ooe = isOrOrExp(this))
        {
            binExpToJsBuffer!"||"(ooe, buf);
            //orOrExpToJsBuffer(ooe, buf);
        }
        else if (auto ve = isVarExp(this))
        {
            buf.write(to!string(toChars()));
        }
        else if (auto ne = isNotExp(this))
        {
            unaExpToJsBuffer!"!"(ne, buf);
        }
        else if (auto ce = isCallExp(this))
        {
            expToJsBuffer(ce, buf);
        }
        else if (auto ce = isCastExp(this))
        {
            // BUG Can this always be discarded?
            ce.e1.toJsBuffer(buf);
        }
        else if (auto ale = isArrayLengthExp(this))
        {
            expToJsBuffer(ale, buf);
        }
        else if (auto se = isStringExp(this))
        {
            expToJsBuffer(se, buf);
        }
        else if (auto dve = isDotVarExp(this))
        {
            expToJsBuffer(dve, buf);
        }
        else if (auto de = isDeclarationExp(this))
        {
            de.declaration.toJsBuffer(buf);
        }
        else if (auto ce = isCmpExp(this))
        {
            switch (ce.op)
            {
                case TOK.TOKlt:
                    binExpToJsBuffer!"<"(ce, buf);
                    break;
                case TOK.TOKgt:
                    binExpToJsBuffer!">"(ce, buf);
                    break;
                case TOK.TOKle:
                    binExpToJsBuffer!"<="(ce, buf);
                    break;
                case TOK.TOKge:
                    binExpToJsBuffer!">="(ce, buf);
                    break;
                default:
                    assert(0, "Unimplemented comparison");
            }
        }
        else if (auto pe = isPostExp(this))
        {
            if (pe.op == TOK.TOKplusplus)
                unaExpToJsBuffer!"++"(pe, buf, true);
            else
                unaExpToJsBuffer!"--"(pe, buf, true);
        }
        else
        {
            assert(0, "unhandled expression: " ~ to!string(toTypeString(this)));
        }
    }
}
mixin(Expression.cppMethods);

const(char*) toTypeString(Expression);

void expToJsBuffer(ArrayLengthExp ale, Duffer buf);
void expToJsBuffer(CallExp ce, Duffer buf);
void expToJsBuffer(StringExp se, Duffer buf);
void expToJsBuffer(DotVarExp dve, Duffer buf);

interface IntegerExp : Expression
{
}

interface ErrorExp : IntegerExp
{
}

interface RealExp : Expression
{
}

interface ComplexExp : Expression
{
}

interface IdentifierExp : Expression
{
}

interface DollarExp : IdentifierExp
{
}

interface DsymbolExp : Expression
{
}

interface ThisExp : Expression
{
}

interface SuperExp : ThisExp
{
}

interface NullExp : Expression
{
}

interface StringExp : Expression
{
}

interface TupleExp : Expression
{
}

interface ArrayLiteralExp : Expression
{
}

interface AssocArrayLiteralExp : Expression
{
}

interface StructLiteralExp : Expression
{
}

interface TypeExp : Expression
{
}

interface ScopeExp : Expression
{
}

interface TemplateExp : Expression
{
}

interface NewExp : Expression
{
}

interface NewAnonClassExp : Expression
{
}

interface SymbolExp : Expression
{
}

interface SymOffExp : SymbolExp
{
}

interface VarExp : SymbolExp
{
}

interface OverExp : Expression
{
}

interface FuncExp : Expression
{
}

interface DeclarationExp : Expression
{
    mixin CppFields!(DeclarationExp,
        Declaration, "declaration" // Bug should be Dsymbol
    );
}

interface TypeidExp : Expression
{
}

interface TraitsExp : Expression
{
}

interface HaltExp : Expression
{
}

interface IsExp : Expression
{
}

interface UnaExp : Expression
{
    mixin CppFields!(UnaExp,
        Expression, "e1"
    );
}

interface BinExp : Expression
{
    mixin CppFields!(BinExp,
        Expression, "e1",
        Expression, "e2"
    );
}

interface BinAssignExp : BinExp
{
}

interface CompileExp : UnaExp
{
}

interface FileExp : UnaExp
{
}

interface AssertExp : UnaExp
{
}

interface DotIdExp : UnaExp
{
}

interface DotTemplateExp : UnaExp
{
}

interface DotVarExp : UnaExp
{
    mixin CppFields!(DotVarExp,
        Declaration, "var",
        int, "hasOverloads"
    );
}

interface DotTemplateInstanceExp : UnaExp
{
}

interface DelegateExp : UnaExp
{
}

interface DotTypeExp : UnaExp
{
}

interface CallExp : UnaExp
{
    mixin CppFields!(CallExp,
        Expressions, "arguments"
    );
}

interface AddrExp : UnaExp
{
}

interface PtrExp : UnaExp
{
}

interface NegExp : UnaExp
{
}

interface UAddExp : UnaExp
{
}

interface ComExp : UnaExp
{
}

interface NotExp : UnaExp
{
}

interface BoolExp : UnaExp
{
}

interface DeleteExp : UnaExp
{
}

interface CastExp : UnaExp
{
}

interface SliceExp : UnaExp
{
}

interface ArrayLengthExp : UnaExp
{
}

interface ArrayExp : UnaExp
{
}

interface DotExp : BinExp
{
}

interface CommaExp : BinExp
{
}

interface IndexExp : BinExp
{
}

/* For both i++ and i--
 */
// BUG interface PostExp : BinExp
interface PostExp : UnaExp
{
}

/* For both ++i and --i
 */
interface PreExp : UnaExp
{
}

interface AssignExp : BinExp
{ 
}

interface ConstructExp : AssignExp
{
}

string ASSIGNEXP(string str)
{
    return `
interface op` ~ str ~ `AssignExp : BinAssignExp
{
}
    `;
}

mixin(ASSIGNEXP("Add"));
mixin(ASSIGNEXP("Min"));
mixin(ASSIGNEXP("Mul"));
mixin(ASSIGNEXP("Div"));
mixin(ASSIGNEXP("Mod"));
mixin(ASSIGNEXP("And"));
mixin(ASSIGNEXP("Or"));
mixin(ASSIGNEXP("Xor"));
mixin(ASSIGNEXP("Shl"));
mixin(ASSIGNEXP("Shr"));
mixin(ASSIGNEXP("Ushr"));
mixin(ASSIGNEXP("Cat"));

interface PowAssignExp : BinAssignExp
{
}

interface AddExp : BinExp
{
}

interface MinExp : BinExp
{
}

interface CatExp : BinExp
{
}

interface MulExp : BinExp
{
}

interface DivExp : BinExp
{
}

interface ModExp : BinExp
{
}

interface PowExp : BinExp
{
}

interface ShlExp : BinExp
{
}

interface ShrExp : BinExp
{
}

interface UshrExp : BinExp
{
}

interface AndExp : BinExp
{
}

interface OrExp : BinExp
{
}

interface XorExp : BinExp
{
}

interface OrOrExp : BinExp
{
}

interface AndAndExp : BinExp
{
}

interface CmpExp : BinExp
{
}

interface InExp : BinExp
{
}

interface RemoveExp : BinExp
{
}

interface EqualExp : BinExp
{
}

interface IdentityExp : BinExp
{
}

interface CondExp : BinExp
{
}

interface DefaultInitExp : Expression
{
}

interface FileInitExp : DefaultInitExp
{
}

interface LineInitExp : DefaultInitExp
{
}

Expression isExpression(Expression e);
IntegerExp isIntegerExp(Expression e);
ErrorExp isErrorExp(Expression e);
RealExp isRealExp(Expression e);
ComplexExp isComplexExp(Expression e);
IdentifierExp isIdentifierExp(Expression e);
DollarExp isDollarExp(Expression e);
DsymbolExp isDsymbolExp(Expression e);
ThisExp isThisExp(Expression e);
SuperExp isSuperExp(Expression e);
NullExp isNullExp(Expression e);
StringExp isStringExp(Expression e);
TupleExp isTupleExp(Expression e);
ArrayLiteralExp isArrayLiteralExp(Expression e);
AssocArrayLiteralExp isAssocArrayLiteralExp(Expression e);
StructLiteralExp isStructLiteralExp(Expression e);
TypeExp isTypeExp(Expression e);
ScopeExp isScopeExp(Expression e);
TemplateExp isTemplateExp(Expression e);
NewExp isNewExp(Expression e);
NewAnonClassExp isNewAnonClassExp(Expression e);
SymbolExp isSymbolExp(Expression e);
SymOffExp isSymOffExp(Expression e);
VarExp isVarExp(Expression e);
OverExp isOverExp(Expression e);
FuncExp isFuncExp(Expression e);
DeclarationExp isDeclarationExp(Expression e);
TypeidExp isTypeidExp(Expression e);
TraitsExp isTraitsExp(Expression e);
HaltExp isHaltExp(Expression e);
IsExp isIsExp(Expression e);
UnaExp isUnaExp(Expression e);
BinExp isBinExp(Expression e);
BinAssignExp isBinAssignExp(Expression e);
CompileExp isCompileExp(Expression e);
FileExp isFileExp(Expression e);
AssertExp isAssertExp(Expression e);
DotIdExp isDotIdExp(Expression e);
DotTemplateExp isDotTemplateExp(Expression e);
DotVarExp isDotVarExp(Expression e);
DotTemplateInstanceExp isDotTemplateInstanceExp(Expression e);
DelegateExp isDelegateExp(Expression e);
DotTypeExp isDotTypeExp(Expression e);
CallExp isCallExp(Expression e);
AddrExp isAddrExp(Expression e);
PtrExp isPtrExp(Expression e);
NegExp isNegExp(Expression e);
UAddExp isUAddExp(Expression e);
ComExp isComExp(Expression e);
NotExp isNotExp(Expression e);
BoolExp isBoolExp(Expression e);
DeleteExp isDeleteExp(Expression e);
CastExp isCastExp(Expression e);
SliceExp isSliceExp(Expression e);
ArrayLengthExp isArrayLengthExp(Expression e);
ArrayExp isArrayExp(Expression e);
DotExp isDotExp(Expression e);
CommaExp isCommaExp(Expression e);
IndexExp isIndexExp(Expression e);
PostExp isPostExp(Expression e);
PreExp isPreExp(Expression e);
AssignExp isAssignExp(Expression e);
ConstructExp isConstructExp(Expression e);
// TODO Missing auto-generated
PowAssignExp isPowAssignExp(Expression e);
AddExp isAddExp(Expression e);
MinExp isMinExp(Expression e);
CatExp isCatExp(Expression e);
MulExp isMulExp(Expression e);
DivExp isDivExp(Expression e);
ModExp isModExp(Expression e);
PowExp isPowExp(Expression e);
ShlExp isShlExp(Expression e);
ShrExp isShrExp(Expression e);
UshrExp isUshrExp(Expression e);
AndExp isAndExp(Expression e);
OrExp isOrExp(Expression e);
XorExp isXorExp(Expression e);
OrOrExp isOrOrExp(Expression e);
AndAndExp isAndAndExp(Expression e);
CmpExp isCmpExp(Expression e);
InExp isInExp(Expression e);
RemoveExp isRemoveExp(Expression e);
EqualExp isEqualExp(Expression e);
IdentityExp isIdentityExp(Expression e);
CondExp isCondExp(Expression e);
DefaultInitExp isDefaultInitExp(Expression e);
FileInitExp isFileInitExp(Expression e);
LineInitExp isLineInitExp(Expression e);
