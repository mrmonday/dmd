module bind.mars;

import bind.root;

extern(C++):

enum LINK
{
    LINKdefault,
    LINKd,
    LINKc,
    LINKcpp,
    LINKwindows,
    LINKpascal,
    LINKjs
}

enum MATCH
{
    MATCHnomatch,       // no match
    MATCHconvert,       // match with conversions
    MATCHconst,         // match with conversion to const
    MATCHexact          // exact match
}

alias ulong StorageClass;

struct Loc
{
    const char* filename;
    uint linnum;
}

void warning(Loc loc, const char *format, ...);
void error(Loc loc, const char *format, ...);
void fatal();

struct Param
{
    char obj;           // write object file
    char link;          // perform link
    char dll;           // generate shared dynamic library
    char lib;           // write library file instead of object file(s)
    char multiobj;      // break one object file into multiple ones
    char oneobj;        // write one object file instead of multiple ones
    char trace;         // insert profiling hooks
    char quiet;         // suppress non-error messages
    char verbose;       // verbose compile
    char vtls;          // identify thread local variables
    char symdebug;      // insert debug symbolic information
    char optimize;      // run optimizer
    char map;           // generate linker .map file
    char cpu;           // target CPU
    char isX86_64;      // generate X86_64 bit code
    char isLinux;       // generate code for linux
    char isOSX;         // generate code for Mac OSX
    char isWindows;     // generate code for Windows
    char isFreeBSD;     // generate code for FreeBSD
    char isOPenBSD;     // generate code for OpenBSD
    char isSolaris;     // generate code for Solaris
    char scheduler;     // which scheduler to use
    char useDeprecated; // allow use of deprecated features
    char useAssert;     // generate runtime code for assert()'s
    char useInvariants; // generate class invariant checks
    char useIn;         // generate precondition checks
    char useOut;        // generate postcondition checks
    char useArrayBounds; // 0: no array bounds checks
                         // 1: array bounds checks for safe functions only
                         // 2: array bounds checks for all functions
    char noboundscheck; // no array bounds checking at all
    char useSwitchError; // check for switches without a default
    char useUnitTests;  // generate unittest code
    char useInline;     // inline expand functions
    char release;       // build release version
    char preservePaths; // !=0 means don't strip path from source file
    char warnings;      // 0: enable warnings
                        // 1: warnings as errors
                        // 2: informational warnings (no errors)
    char pic;           // generate position-independent-code for shared libs
    char cov;           // generate code coverage data
    char nofloat;       // code should not pull in floating point support
    char Dversion;      // D version number
    char ignoreUnsupportedPragmas;      // rather than error on them

    char *argv0;        // program name
    Array imppath;     // array of char*'s of where to look for import modules
    Array fileImppath; // array of char*'s of where to look for file import modules
    char *objdir;       // .obj/.lib file output directory
    char *objname;      // .obj file output name
    char *libname;      // .lib file output name

    char doDocComments; // process embedded documentation comments
    char *docdir;       // write documentation file to docdir directory
    char *docname;      // write documentation file to docname
    Array ddocfiles;   // macro include files for Ddoc

    char doHdrGeneration;       // process embedded documentation comments
    char *hdrdir;               // write 'header' file to docdir directory
    char *hdrname;              // write 'header' file to docname

    char doXGeneration;         // write JSON file
    char *xfilename;            // write JSON file to xfilename
    
    char doJsGeneration;         // write Javascript file

    uint debuglevel;        // debug level
    Array debugids;            // debug identifiers

    uint versionlevel;      // version level
    Array versionids;          // version identifiers

    bool dump_source;

    const char *defaultlibname; // default library for non-debug builds
    const char *debuglibname;   // default library for debug builds

    char *moduleDepsFile;       // filename for deps output
    OutBuffer moduleDeps;      // contents to be written to deps file

    // Hidden debug switches
    char debuga;
    char debugb;
    char debugc;
    char debugf;
    char debugr;
    char debugw;
    char debugx;
    char debugy;

    char run;           // run resulting executable
    size_t runargs_length;
    char** runargs;     // arguments for executable

    // Linker stuff
    Array objfiles;
    Array linkswitches;
    Array libfiles;
    char *deffile;
    char *resfile;
    char *exefile;
    char *mapfile;
}

struct Global
{
    const char *mars_ext;
    const char *sym_ext;
    const char *obj_ext;
    const char *lib_ext;
    const char *dll_ext;
    const char *doc_ext;        // for Ddoc generated files
    const char *ddoc_ext;       // for Ddoc macro include files
    const char *hdr_ext;        // for D 'header' import files
    const char *json_ext;       // for JSON files
    const char *map_ext;        // for .map files
    const char *copyright;
    const char *written;
    Array path;        // Array of char*'s which form the import lookup path
    Array filePath;    // Array of char*'s which form the file import lookup path
    int structalign;
    const char *_version;

    Param params;
    uint errors;    // number of errors reported so far
    uint warnings;  // number of warnings reported so far
    uint gag;       // !=0 means gag reporting of errors & warnings
}

extern(C) extern __gshared Global global;

