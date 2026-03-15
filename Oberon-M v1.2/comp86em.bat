REM This batch file recompiles everything in the
REM distribution package to use the 8086/8088
REM downward-compatibility option.
ntvdm -c oc DISK     DEF 8086
ntvdm -c oc SCREEN   DEF 8086
ntvdm -c oc IO       DEF 8086
ntvdm -c oc LINEIO   DEF 8086
ntvdm -c oc LIO      DEF 8086
ntvdm -c oc PARMS    DEF 8086
ntvdm -c oc TERM     DEF 8086
ntvdm -c oc ABU      DEF 8086
REM the following line will re-link the ABU
REM example for you.
ntvdm -c link abu+screen+disk+term+parms+sys ;
ntvdm -c oc OEIO     DEF 8086
ntvdm -c oc OETREE   DEF 8086
ntvdm -c oc OENAMES  DEF 8086
ntvdm -c oc OEPHONE  DEF 8086
ntvdm -c oc OE       DEF 8086
REM the line below will re-link the OE
REM example for you.
ntvdm -c link oe+oeio+oetree+oenames+oephone+term+sys ;
