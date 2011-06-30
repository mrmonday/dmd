module javascript;

import bind.attrib;
import bind.declaration;
import bind.dsymbol : Dsymbol;
import bind.expression;
import bind.mars;
import bind.module_;
import bind.root;
import bind.statement;

import core.memory;
import core.runtime;

import duffer;

import std.conv;
import std.stdio;

extern(C++):
void js_generate(Array modules)
{
    Runtime.initialize();
    //GC.disable();
    scope(exit) Runtime.terminate();

    try
    {
        foreach (Module m; modules)
        {   
            auto buf = Duffer();
            if (global.params.verbose)
            {
                writefln("js gen %s", to!string(m.toChars()));
            }
            m.toJsBuffer(buf);
            buf.print((string str) { writefln(str); });
        }
    }
    catch(Throwable e)
    {
        stderr.writeln(e.toString());
        throw e;
    }
}

/**********************************************************
 * Declarations
 */

bool isMain = false;

// BUG in/out contracts
void declToJsBuffer(FuncDeclaration func, Duffer buf)
{
    if (!func.fbody)
        return;

    if (!func.isMain())
    {
        buf.writef("function %s(", to!string(func.toChars()));
    }
    if (func.parameters)
    {
        uint i;
        foreach (Dsymbol d; func.parameters)
        {
            i++;
            //writefln("parameter: %s", d.toChars());
            d.toJsBuffer(buf);
            if (i < func.parameters.dim)
            {
                buf.write(", ");
            }
        }
    }
    if (!func.isMain())
    {
        buf.writeln(") {");
        func.fbody.toJsBuffer(buf);
        buf.writeln("}");
    }
    else
    {
        isMain = true;
        func.fbody.toJsBuffer(buf);
        isMain = false;
    }

    buf.writeln();
}

void declToJsBuffer(VarDeclaration vd, Duffer buf)
{
    if (vd.parent && vd.parent.isFuncDeclaration())
    {
        buf.write(to!string(vd.toChars()));
    }
    else
    {
        assert(0);
    }
}

void declToJsBuffer(LinkDeclaration ld, Duffer buf)
{
    if (ld.linkage != LINK.LINKjs)
    {
        error(ld.loc, "Unsupported linkage attribute when outputting JavaScript");
        fatal();
    }
   // Ignore everything, it's just so it can be used.
   /* foreach (Dsymbol d; ld.decl)
    {

    }*/
}

/**********************************************************
 * Statements
 */

bool forInit = false;

void statementToJsBuffer(ExpStatement ss, Duffer buf)
{
    ss.exp.toJsBuffer(buf);
    if (!forInit)
        buf.writeln(";");
}

void statementToJsBuffer(IfStatement ifs, Duffer buf)
{
    buf.write("if (");
    ifs.condition.toJsBuffer(buf);
    buf.write(") ");
    ifs.ifbody.toJsBuffer(buf);
    if (ifs.elsebody)
    {
        buf.write("else ");
        ifs.elsebody.toJsBuffer(buf);
    }
}

void statementToJsBuffer(ScopeStatement ss, Duffer buf)
{
    buf.writeln("{");
    ss.statement.toJsBuffer(buf);
    buf.writeln("}");
}

void statementToJsBuffer(ReturnStatement rs, Duffer buf)
{
    if (isMain)
        return;
    buf.write("return ");
    rs.exp.toJsBuffer(buf);
    buf.writeln(";");
}

void statementToJsBuffer(ForStatement fs, Duffer buf)
{
    buf.write("for (");
    forInit = true;
    fs.init.toJsBuffer(buf);
    forInit = false;
    buf.write("; ");
    fs.condition.toJsBuffer(buf);
    buf.write("; ");
    fs.increment.toJsBuffer(buf);
    buf.write(") ");
    fs.body_.toJsBuffer(buf);
}

/**********************************************************
 * Expressions
 */

void unaExpToJsBuffer(string str, T : UnaExp)(T be, Duffer buf, bool post=false)
{
    if (post)
    {
        be.e1.toJsBuffer(buf);
        buf.write(str);
    }
    else
    {
        buf.write(str);
        be.e1.toJsBuffer(buf);
    }
}

void binExpToJsBuffer(string str, T : BinExp)(T be, Duffer buf)
{
    be.e1.toJsBuffer(buf);
    buf.write(' ' ~ str ~ ' ');
    be.e2.toJsBuffer(buf);
}

void expToJsBuffer(CallExp ce, Duffer buf)
{
    ce.e1.toJsBuffer(buf);
    buf.write("(");
    uint i;
    foreach (Expression e; ce.arguments)
    {
        i++;
        e.toJsBuffer(buf);
        if (i < ce.arguments.dim)
        {
            buf.write(", ");
        }
    }
    buf.write(")");
}

void expToJsBuffer(ArrayLengthExp ale, Duffer buf)
{
    ale.e1.toJsBuffer(buf);
    buf.write(".length");
}

void expToJsBuffer(StringExp se, Duffer buf)
{
    buf.writef(`%s`, to!string(se.toChars()));
}

void expToJsBuffer(DotVarExp dve, Duffer buf)
{
    dve.e1.toJsBuffer(buf);
    buf.writef(".%s", to!string(dve.var.toChars()));
    //dve.var.toJsBuffer(buf);
}

