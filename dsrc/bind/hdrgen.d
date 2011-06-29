module bind.hdrgen;

extern(C++):

struct HdrGenState
{
    int hdrgen;         // 1 if generating header file
    int ddoc;           // 1 if generating Ddoc file
    int console;        // 1 if writing to console
    int tpltMember;
    int inCallExp;
    int inPtrExp;
    int inSlcExp;
    int inDotExp;
    int inBinExp;
    int inArrExp;
    int emitInst;
    struct FLinit
    {
        int init;
        int decl;
    }

    //HdrGenState() { memset(this, 0, sizeof(HdrGenState)); }
}
