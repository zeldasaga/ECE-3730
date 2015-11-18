
        as12 - Cross-Assembler for the CPU12 family from Motorola

Original Date:  9 July 1996
Author:         Karl Lunt
Revisions:      version 1.2a April 1999 by Tom Almy
                version 1.2b January 2003 by Eric Engler
                version 1.2c January 2003 by Eric Engler
                version 1.2d March 2003 by Eric Engler

This distribution package contains the executable for as12, a PC-based
FREEWARE cross-assembler for the Motorola CPU12 family. I have also
included the C source code.


                                DISCLAIMER

   I am releasing the executable for the as12 assembler, all supporting
  library and include files, and this document as freeware.  Feel free to
   use as12 for whatever non-commercial application seems appropriate.

     I make no warranty, representation, or guarantee regarding the
   suitability of as12 for any particular purpose, nor do I assume any
 liability arising out of the application or use of as12, and I disclaim
   any and all liability, including without limitation consequential or
                           incidental damages.

          You, as the user, take all responsibility for direct
    and/or consequential damages of any kind that might arise from using
                           as12 in any fashion.

    I do not warrant that as12 is free of bugs.  If you find what you
     think is a bug, kindly let me know what it is IN DETAIL, and I'll
     certainly consider fixing it in a later release, if there ever is
                                   such.

   I ported as12 as a tool for working with the CPU12 MCUs.  If you use
   as12 for developing robotics (or other) application code and find it
     useful, fine.  If you don't find it suitable in some fashion, then
                               don't use it.


                                                        Karl Lunt


History

The as12 assembler was originally developed by Motorola engineers and
used internally on a Unix platform to create test software during CPU12
development.  Following release of sample silicon for the 68hc12a4 in
late June 1996, Motorola was kind enough to release the source files to
me for porting to the PC platform.

Since as12 uses a command-line interface (CLI), porting to DOS made the
most immediate sense.  Thus, this version of as12 runs from the DOS
prompt; I don't have any plans to create a Windows version.



UPDATES

Version 1.2a (by Tom Almy)

* A source file name with no extension defaults to the extension .asm
* The -L option, without a filename, uses the name of the first source file
* Error and Warning totals appear on the screen even if a listing file is specified
* The unary complement ("~") is implemented
* AS12 is compiled as a Win32 Console Application and allows long file names.
* The document file has been completed.

Version 1.2b (by Eric Engler)

* Fixed this bug: If you #include a file, and that file contains an error, the
  as12 error message incorrectly gives the input file name, not the included file
  name. This works fine now.
* Changed error reporting so error and warning text goes to BOTH the screen and
  the list file when you are using a list file. This lets you see the errors
  on the screen without making you look in the list file.
* Made a more compact format for errors and warnings so they each fit on one line.
* Limited the maximum number of Warnings and/or Errors to 300. This helps in
  cases where the Assembler has gotten into a bad state and it starts spewing
  out thousands of errors! This normally happens only after it has a found a
  real error. The first error it shows is normally the most important one. If 
  you fix that, the rest of the errors often go away.
* Added 2 makefiles for GNU C, and a makefile for the free Borland C++ compiler.
  See Compilers.txt for more information.
* Reformated the source code using the GNU "indent" formatter
* Created a freeware Windows Integrated Development Environment called AsmIDE.
  This is distributed separately because of it's size.

Version 1.2c (by Eric Engler)

* It was case sensitive for symbols, yet insensitive for directives and 
  mnemonics. I made it case insensitive for symbols also.
* Spaces in operands were taken as operand delimiters and anything after the
  last operand was taken as a comment. I fixed it so it now ignores spaces in
  operands.
     Example:  ldaa foo + 1 
* It now supports quoted filenames in #include. This lets you include a file 
  that has spaces in the filename, or it's directory. The old way of not using
  quotes still works, also.
     Example:  #include "c:\program files\as12\mydefs.h"
* Increase #include nesting to 10 levels (was 5)

Version 1.2d (by Eric Engler)

* fixed a bug in the way #include was working.



Invocation

To run the as12 assembler, type:

	as12

at the command prompt.  This will display a short help file describing
the command line arguments available to you.  To assemble a file, enter
a command such as:

	as12  foo.asm

Please note that as12 does not assume a default file extension for the
input file; you must specify the full file and extension.  Normally,
as12 writes its listing output to the console; you can use redirection
to save the listing output to a file.  For example:

	as12  foo.asm  >foo.lst

will create the listing file foo.lst.

Starting with version 1.1, as12 supports the -L option.  This option
allows you to specify a file path and name for holding the list output. 
By default, this listing output file uses an extension of .lst.  You
could accomplish the above example by:

	as12  foo.asm  -Lfoo               OR
	as12  foo.asm  -Lfoo.lst

Note that you must not use any spaces between the -L and the listing
output file name.

Starting with version 1.1, as12 supports the -o option.  This option
allows you to specify the output object file.  For example:

	as12  foo.asm  -ofoo.s19  >foo.lst

The object file carries a .s19 extension by default, so the above line
could have been:

	as12  foo.asm  -ofoo  >foo.lst

Note that you must not use any spaces between the -o and the object file
name.



Documentation

See the file "as12.htm" for full documentation.



Features

This is still an absolute (non-linking) assembler, it has a very strong 
feature set, and can carry you a long way with the CPU12 MCUs.

It supports #include files up to 10 deep, #ifdef statements,
command-line defines, and several cool pseudo-ops.  In particular, the
#ifp statement lets you test for the target processor in your source
code, so you can adjust your assembly depending on the CPU12 variant
that will ultimately execute the code.  For information on defining the
processor type on the command line, check the -p option in the as12.htm
file.



Known bugs and limitations

Sometimes errors are indicated for a line near the actual line that had
a problem. For example, line 22 might have an error, but the error message
might show line number 24. It's usually close enough to be useful.

This is an absolute assembler. It is not possible to create object files
and link them together, and it's not possible to link assembler modules
to C language modules with this tool.
