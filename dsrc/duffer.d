module duffer;

import std.array;
import std.format;
import std.string;

struct Duffer
{
    Appender!string buf;
    /// Number of tabs to indent by
    private uint tabs;
    /// Should we indent?
    private static bool tab = true;
    /// Has the current Duffer been written to yet?
    private bool hasWritten = false;

    static opCall()
    {
        Duffer d;
        d.buf = appender!string();
        return d;
    }

    this(this)
    {
        if (hasWritten && tab)
            tabs++;
        hasWritten = false;
    }

    private void insertTabs()
    {
        if (tab)
            buf.put(" ".replicate(tabs * 4));
    }

    void writeln(string str = "")
    {
        insertTabs();
        buf.put(str ~ newline);
        tab = true;
        hasWritten = true;
    }

    void write(string str)
    {
        insertTabs();
        tab = false;
        buf.put(str);
        tab = str.length && str[$-1] == '\n' ? true : false;
        hasWritten = true;
    }

    void writef(T...)(string str, T params)
    {
        insertTabs();
        formattedWrite(buf, str, params);
        tab = str.length && str[$-1] == '\n' ? true : false;
        hasWritten = true;
    }

    void writefln(T...)(string str, T params)
    {
        insertTabs();
        formattedWrite(buf, str, params);
        buf.put('\n');
        tab = true;
        hasWritten = true;
    }

    void print(void delegate(string) dg)
    {
        dg(buf.data);
    }
}
