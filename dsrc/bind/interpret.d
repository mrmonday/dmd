module bind.interpret;

import bind.arraytypes;
import bind.declaration;
import bind.expression;
import bind.statement;

extern(C++):

struct InterState
{
    InterState* caller;         // calling function's InterState
    FuncDeclaration fd;        // function being interpreted
    Dsymbols vars;              // variables used in this function
    Statement* start;           // if !=NULL, start execution at this statement
    Statement* gotoTarget;      // target of EXP_GOTO_INTERPRET result
    Expression* localThis;      // value of 'this', or NULL if none
    bool awaitingLvalueReturn;  // Support for ref return values:
           // Any return to this function should return an lvalue.
//    InterState();
}
