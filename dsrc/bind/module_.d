module bind.module_;

import bind.dsymbol;

import duffer;

extern(C++):

interface Package : ScopeDsymbol
{
}

interface Module : Package
{
    final void toJsBuffer(Duffer buf)
    {
        foreach (Dsymbol d; members)
        {
            d.toJsBuffer(buf);
        }
    }
}

