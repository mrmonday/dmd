#include "expression.h"
#include "statement.h"
#include <typeinfo>

const char *toTypeString(Dsymbol *s)
{
    return typeid(*s).name();
}

const char *toTypeString(Statement *s)
{
    return typeid(*s).name();
}

const char *toTypeString(Expression *e)
{
    return typeid(*e).name();
}

// Almost completely auto-generated with:
// cat dsrc/bind/expression.d | grep interface | cut -f2 -d' ' | \
// perl -pe 's/(.*)/\1 *is\1(Expression *e) { return dynamic_cast<\1*>(e); }/' >> src/jsbridge.cpp

Expression *isExpression(Expression *e) { return dynamic_cast<Expression*>(e); }
IntegerExp *isIntegerExp(Expression *e) { return dynamic_cast<IntegerExp*>(e); }
ErrorExp *isErrorExp(Expression *e) { return dynamic_cast<ErrorExp*>(e); }
RealExp *isRealExp(Expression *e) { return dynamic_cast<RealExp*>(e); }
ComplexExp *isComplexExp(Expression *e) { return dynamic_cast<ComplexExp*>(e); }
IdentifierExp *isIdentifierExp(Expression *e) { return dynamic_cast<IdentifierExp*>(e); }
DollarExp *isDollarExp(Expression *e) { return dynamic_cast<DollarExp*>(e); }
DsymbolExp *isDsymbolExp(Expression *e) { return dynamic_cast<DsymbolExp*>(e); }
ThisExp *isThisExp(Expression *e) { return dynamic_cast<ThisExp*>(e); }
SuperExp *isSuperExp(Expression *e) { return dynamic_cast<SuperExp*>(e); }
NullExp *isNullExp(Expression *e) { return dynamic_cast<NullExp*>(e); }
StringExp *isStringExp(Expression *e) { return dynamic_cast<StringExp*>(e); }
TupleExp *isTupleExp(Expression *e) { return dynamic_cast<TupleExp*>(e); }
ArrayLiteralExp *isArrayLiteralExp(Expression *e) { return dynamic_cast<ArrayLiteralExp*>(e); }
AssocArrayLiteralExp *isAssocArrayLiteralExp(Expression *e) { return dynamic_cast<AssocArrayLiteralExp*>(e); }
StructLiteralExp *isStructLiteralExp(Expression *e) { return dynamic_cast<StructLiteralExp*>(e); }
TypeExp *isTypeExp(Expression *e) { return dynamic_cast<TypeExp*>(e); }
ScopeExp *isScopeExp(Expression *e) { return dynamic_cast<ScopeExp*>(e); }
TemplateExp *isTemplateExp(Expression *e) { return dynamic_cast<TemplateExp*>(e); }
NewExp *isNewExp(Expression *e) { return dynamic_cast<NewExp*>(e); }
NewAnonClassExp *isNewAnonClassExp(Expression *e) { return dynamic_cast<NewAnonClassExp*>(e); }
SymbolExp *isSymbolExp(Expression *e) { return dynamic_cast<SymbolExp*>(e); }
SymOffExp *isSymOffExp(Expression *e) { return dynamic_cast<SymOffExp*>(e); }
VarExp *isVarExp(Expression *e) { return dynamic_cast<VarExp*>(e); }
OverExp *isOverExp(Expression *e) { return dynamic_cast<OverExp*>(e); }
FuncExp *isFuncExp(Expression *e) { return dynamic_cast<FuncExp*>(e); }
DeclarationExp *isDeclarationExp(Expression *e) { return dynamic_cast<DeclarationExp*>(e); }
TypeidExp *isTypeidExp(Expression *e) { return dynamic_cast<TypeidExp*>(e); }
TraitsExp *isTraitsExp(Expression *e) { return dynamic_cast<TraitsExp*>(e); }
HaltExp *isHaltExp(Expression *e) { return dynamic_cast<HaltExp*>(e); }
IsExp *isIsExp(Expression *e) { return dynamic_cast<IsExp*>(e); }
BinExp *isBinExp(Expression *e) { return dynamic_cast<BinExp*>(e); }
BinAssignExp *isBinAssignExp(Expression *e) { return dynamic_cast<BinAssignExp*>(e); }
CompileExp *isCompileExp(Expression *e) { return dynamic_cast<CompileExp*>(e); }
FileExp *isFileExp(Expression *e) { return dynamic_cast<FileExp*>(e); }
AssertExp *isAssertExp(Expression *e) { return dynamic_cast<AssertExp*>(e); }
DotIdExp *isDotIdExp(Expression *e) { return dynamic_cast<DotIdExp*>(e); }
DotTemplateExp *isDotTemplateExp(Expression *e) { return dynamic_cast<DotTemplateExp*>(e); }
DotVarExp *isDotVarExp(Expression *e) { return dynamic_cast<DotVarExp*>(e); }
DotTemplateInstanceExp *isDotTemplateInstanceExp(Expression *e) { return dynamic_cast<DotTemplateInstanceExp*>(e); }
DelegateExp *isDelegateExp(Expression *e) { return dynamic_cast<DelegateExp*>(e); }
DotTypeExp *isDotTypeExp(Expression *e) { return dynamic_cast<DotTypeExp*>(e); }
CallExp *isCallExp(Expression *e) { return dynamic_cast<CallExp*>(e); }
AddrExp *isAddrExp(Expression *e) { return dynamic_cast<AddrExp*>(e); }
PtrExp *isPtrExp(Expression *e) { return dynamic_cast<PtrExp*>(e); }
NegExp *isNegExp(Expression *e) { return dynamic_cast<NegExp*>(e); }
UAddExp *isUAddExp(Expression *e) { return dynamic_cast<UAddExp*>(e); }
ComExp *isComExp(Expression *e) { return dynamic_cast<ComExp*>(e); }
NotExp *isNotExp(Expression *e) { return dynamic_cast<NotExp*>(e); }
BoolExp *isBoolExp(Expression *e) { return dynamic_cast<BoolExp*>(e); }
DeleteExp *isDeleteExp(Expression *e) { return dynamic_cast<DeleteExp*>(e); }
CastExp *isCastExp(Expression *e) { return dynamic_cast<CastExp*>(e); }
SliceExp *isSliceExp(Expression *e) { return dynamic_cast<SliceExp*>(e); }
ArrayLengthExp *isArrayLengthExp(Expression *e) { return dynamic_cast<ArrayLengthExp*>(e); }
ArrayExp *isArrayExp(Expression *e) { return dynamic_cast<ArrayExp*>(e); }
DotExp *isDotExp(Expression *e) { return dynamic_cast<DotExp*>(e); }
CommaExp *isCommaExp(Expression *e) { return dynamic_cast<CommaExp*>(e); }
IndexExp *isIndexExp(Expression *e) { return dynamic_cast<IndexExp*>(e); }
PostExp *isPostExp(Expression *e) { return dynamic_cast<PostExp*>(e); }
PreExp *isPreExp(Expression *e) { return dynamic_cast<PreExp*>(e); }
AssignExp *isAssignExp(Expression *e) { return dynamic_cast<AssignExp*>(e); }
ConstructExp *isConstructExp(Expression *e) { return dynamic_cast<ConstructExp*>(e); }
// Missing mixin-generated
PowAssignExp *isPowAssignExp(Expression *e) { return dynamic_cast<PowAssignExp*>(e); }
AddExp *isAddExp(Expression *e) { return dynamic_cast<AddExp*>(e); }
MinExp *isMinExp(Expression *e) { return dynamic_cast<MinExp*>(e); }
CatExp *isCatExp(Expression *e) { return dynamic_cast<CatExp*>(e); }
MulExp *isMulExp(Expression *e) { return dynamic_cast<MulExp*>(e); }
DivExp *isDivExp(Expression *e) { return dynamic_cast<DivExp*>(e); }
ModExp *isModExp(Expression *e) { return dynamic_cast<ModExp*>(e); }
PowExp *isPowExp(Expression *e) { return dynamic_cast<PowExp*>(e); }
ShlExp *isShlExp(Expression *e) { return dynamic_cast<ShlExp*>(e); }
ShrExp *isShrExp(Expression *e) { return dynamic_cast<ShrExp*>(e); }
UshrExp *isUshrExp(Expression *e) { return dynamic_cast<UshrExp*>(e); }
AndExp *isAndExp(Expression *e) { return dynamic_cast<AndExp*>(e); }
OrExp *isOrExp(Expression *e) { return dynamic_cast<OrExp*>(e); }
XorExp *isXorExp(Expression *e) { return dynamic_cast<XorExp*>(e); }
OrOrExp *isOrOrExp(Expression *e) { return dynamic_cast<OrOrExp*>(e); }
AndAndExp *isAndAndExp(Expression *e) { return dynamic_cast<AndAndExp*>(e); }
CmpExp *isCmpExp(Expression *e) { return dynamic_cast<CmpExp*>(e); }
InExp *isInExp(Expression *e) { return dynamic_cast<InExp*>(e); }
RemoveExp *isRemoveExp(Expression *e) { return dynamic_cast<RemoveExp*>(e); }
EqualExp *isEqualExp(Expression *e) { return dynamic_cast<EqualExp*>(e); }
IdentityExp *isIdentityExp(Expression *e) { return dynamic_cast<IdentityExp*>(e); }
CondExp *isCondExp(Expression *e) { return dynamic_cast<CondExp*>(e); }
DefaultInitExp *isDefaultInitExp(Expression *e) { return dynamic_cast<DefaultInitExp*>(e); }
FileInitExp *isFileInitExp(Expression *e) { return dynamic_cast<FileInitExp*>(e); }
LineInitExp *isLineInitExp(Expression *e) { return dynamic_cast<LineInitExp*>(e); }
