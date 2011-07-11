extern(JavaScript)
{
    /* // Use something like this for binding
    class JsObject
    {
        void opDispatch(string name, T...)(T)
        {
        }
    }*/
    struct __Document
    {
        void write(string);
        // TODO invalid
        void write(double);
        void writeln(string);
    }
    __Document document;
}

class Foobar
{
    string str;
    int a;
    double b;
    this(string _str, int _a, double _b)
    {
        str = _str;
        a = _a;
        b = _b;
    }

    void foo()
    {
        document.writeln("horrah!");
    }
}

class Foobar2 : Foobar
{
    this(string _str)
    {
        super(_str, 3, 4.0);
    }

    void foo(string str)
    {
        document.writeln(str);
    }
}

int foo(int a, bool b)
{
    if (b && a)
    {
        return bar().length;
    }
    else if (b || !a)
    {
        return -4;
    }
    else
    {
        return 7;
    }
}

string bar()
{
    return "foobar";
}

void main()
{
    foo(1, true);
    document.writeln("test");
    for (int i = 0; i < 5; i++)
    {
        document.write(i);
    }

    auto arr = [1.2, 4.3, 6.8];
    foreach (v; arr)
        document.write(v);
    foreach (i, v; arr)
    {
        document.write(i);
        document.write(": ");
        document.write(v);
    }

    int i = 10;
    while (i > 1)
    {
        if (i == 2)
            document.write("2");
        if (i != 3)
            document.write("");
        --i;
    }
    auto f = new Foobar("a", 1, 2.0);
    f.foo();
    f = new Foobar2("b");
    f.foo();
}
