= DMD JavaScript Backend =

Requires dmd pull request 131.

To build:

    $ cd dsrc; dmd -lib -oflibdmdjsbe.a javascript.d duffer.d bind/*.d
    $ cd ../src; make -f posix.mak

Usage:

    $ dmd -js someFile.d -ofsomeFile.js

Bugs:

 * No way to inject javascript
 * No support for javascript builtins
   + No validation for either of the above
 * No checking for name conflicts with js keywords
 * No optimizer - closure?
 * One-to-one translation, not semantically equivilant to D
 * Missing a lot of basic constructs
 * No support for templates yet
 * Missing pre-defined version identifiers
 * Some semantic error checking is done when creating object files in dmd, this checking is not done
