ntvdm -c plm86 %1.plm optimize(3)

ntvdm -c asm86 doslibs.asm

ntvdm -r:. link86 %1.obj,doslibs.obj,plm86.lib TO %1.exe exe



