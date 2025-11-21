                          * The DDS MICRO-C Compiler *

       Dunfield Development Services  (DDS)  MICRO-C is a compact,  portable
    compiler suitable for code development  targeting  small  8  or  16  bit
    systems.  At the time of this writing,  versions  of  the  compiler  are
    available which produce code  for  the  68HC08,  6809,  68HC11,  68HC12,
    68HC16, 8051/52, 8080/85/Z80, 8086, 8096 and AVR processor families,  as
    well as for a "virtual machine" called the C-FLEA.

       This version of MICRO-C,  runs on,  and produces code for the IBM  PC
    family of desktop computers.  Included in  the  package  is  a  complete
    implementation of MICRO-C, with a comprehensive library suitable for the
    PC.  This implementation of the compiler  requires  a  Microsoft  (MASM)
    compatible assembler and linker.

       Commercial versions of  the  compiler  are  designed  for  "embedded"
    systems.  This means that the code produced by the compiler is  ROMable,
    and does not require that it  be  run  under  any  particular  operating
    system.  These compilers are completely configurable so that you can run
    the  compiled  code  in   almost   any   hardware/software   environment
    imaginable.  The commercial packages also include their  own  assembler,
    linker and debugger.  No other software is required to develop code  for
    the target cpu. For more information, please contact:

    Dunfield  Development  Services  (DDS)  offers  software  and   firmware
    development services specializing in systems and embedded  applications.
    For more information, visit: http://www.dunfield.com

       This MICRO-C "package"  (software and documentation)  is copyrighted,
    and all rights to it are reserved.  Permission is granted to  distribute
    ORIGINAL UNMODIFIED copies ONLY of the MC???PC.ZIP archive via  BBS  and
    disk copying services.  MICRO-C is provided on an "as is" basis, with no
    warranty of any kind.  In no event shall the author be  liable  for  any
    damages arising from its use or distribution.

       For more information on the compiler,  see the file  MC.TXT.  If  you
    print it, be warned that the file is quite large.  The table of contents
    pages are printed last,  and should be inserted between the  title  page
    and page 1.  The "Browse"  function of the included DDSIDE editor can be
    used to view the documentation online.
                              * Getting Started *

       To install MICRO-C on a hard drive,  simply create  a  directory  and
    unpack this archive into it.  The directory  "\MC"  is preferred,  since
    some of the utilities assume this is the MICRO-C home  directory  unless
    told otherwise.  Note that the  archive  contains  subdirectories  (with
    PKUNZIP be sure to  specify  the  '-d'  option  to  enable  subdirectory
    creation).

        [Example: Installing MICRO-C to drive C from archive on drive A]
            C:\> md mc
            C:\> cd mc
            C:\MC> pkunzip -d a:mc???pc

       To use MICRO-C, you must have a Microsoft (MASM) compatible assembler
    and linker available on your system. The exact commands and options used
    with the assembler/linker differ with different versions of these tools.
    Run the program MCSETUP to select your particular assembler and linker.

       For those users who do not already  have  a  suitable  assembler  and
    linker,  I have located a freeware assembler and linker that  appear  to
    work quite well  with  MICRO-C.  I  take  no  responsibility  for  these
    programs, however they are available on my web site under the filenames:
    ARROWASM.ZIP and VAL.ZIP.  These archives should be  unpacked  into  the
    MICRO-C home directory AFTER the MICRO-C package, but BEFORE the MCSETUP
    program is run.

        [Example: Installing PD assembler and linker for MICRO-C]
            C:\MC> pkunzip a:arrowasm
            C:\MC> pkunzip a:val
            C:\MC> mcsetup

       Refer to the following document files for more information:

            MC.TXT      - General information about the compiler
            DDSIDE.TXT  - Information on the Integrated Development Editor
            LIBRARY.TXT - MICRO-C/PC library function reference
            CINTRO.TXT  - Beginners introduction to 'C'

       The MCDIR  and  TEMP  environment  variables  should  be  set  up  as
    described in the documents before attempting to use the compiler.
                            * MICRO-C under MS-DOS *
                            * Implementation notes *

       This 8086 MS-DOS implementation of the compiler produces code for the
    Microsoft MASM  (or compatible)  assembler in either the TINY  or  SMALL
    models.  The LINK utility is required to create an EXE file.  NOTE  that
    programs produced for the TINY  model  will  execute  as  ".EXE"  files,
    however, due to PSP being outside of the data/code segment, command line
    parameters are only available when the program is  converted  to  ".COM"
    format with the supplied EXE2BIN utility.

       The memory model to use is selected by  the  runtime  library,  which
    MUST BE FIRST in the list of object files  passed  to  the  linker.  The
    PC86RL_T.OBJ file distributed with MICRO-C is configured  for  the  TINY
    model, and the PC86RL_S.OBJ file is configured for the SMALL model.

       The startup code for the PC defines the following external  variables
    which can be used within your 'C' programs:

            ie:     extern int ARGC;        /* Count of arguments */
                    extern char *ARGV[];    /* Array of ptrs to args */
                    extern int PSP;         /* PSP segment */
                    extern int ENV;         /* Environment segment */

       The usual argc  and  argv  parameters  are  provided  to  the  main()
    function,  however the ARGC and ARGV variables make it  easy  for  other
    functions to access the programs command line arguments.

       If you are using a DOS version prior to  3.0,  the  argv[0]  (program
    name) argument will not work correctly.
                           * Files in this package *

            README.TXT      - This file
            MC.TXT          - MICRO-C/PC Technical Documentation
            LIBRARY.TXT     - MICRO-C/PC Library Reference
            DDSIDE.TXT      - Integrated Editor Documentation
            SPRITED.TXT     - Sprite Editor Documentation
            CINTRO.TXT      - Introduction to 'C'
            MCSETUP.COM     - Assembler/Linker setup utility
            MCP.EXE         - Preprocessor
            MCC.EXE         - PC/80x86 Compiler
            MCO.COM         - PC/80x86 Optimizer
            EXE2BIN.COM     - Executable to Binary convertor
            DDSIDE.COM      - Integrated Development Editor
            DDSIDE.HLP      - Help file for DDSIDE
            SPRITED.COM     - Sprite Editor
            PC86RL_T.OBJ    - Tiny model runtime library
            PC86RL_S.OBJ    - Small model runtime library
            MCLIB.LIB       - MICRO-C/PC Function Library
            *.H             - Header files as described in the documentation
            EXAMPLES\*.*    - Source code to LOTS of example programs (optional)

       All of the source and header files were written using tab stops every
    4 characters, which is much more convenient for 'C' development than the
    usual MS-DOS tab stops of every 8 characters. The included DDSIDE editor
    has default tab stops at 4 space intervals.  Also,  source for a program
    called  "type4.c"  is provided in the EXAMPLES\DOSUTIL directory,  which
    reads a file and displays it using spaces to  simulate  the  tabs  at  4
    character intervals. To compile this program, use:

                                  cc type4 -fp

       The resulting  "type4.com"  file may be used to view/print the source
    files with proper spacing.
                        * Limited Distribution License *

       Permission is granted to copy and distribute this "demo"  archive via
    electronic  "Bulletin Board Systems"  (BBS),  and disk copying services,
    subject to the following restrictions:

    - The archive must be presented in its original form, without modification.

    - The archive may not be distributed as part of or in assocation with any
      other product without my permission.

    - Only one version of this archive may be offered at any given time, IE:
      when you post a new version of one of my archives, any older versions of
      that archive must no longer be offered for distribution.

    - I reserve the right to request of anyone distributing this archive that
      they upgrade to the current release (which I will provide).





            Dave Dunfield   -   https://dunfield.themindfactory.com

      Download and see my product CATALOG!        Another way to find me:
      Search "Dave's Old Computers" and see my "personal" link at bottom.
