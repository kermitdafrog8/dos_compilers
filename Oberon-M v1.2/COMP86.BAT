REM This batch file recompiles everything in the
REM distribution package to use the 8086/8088
REM downward-compatibility option.
oc DISK     DEF 8086
oc SCREEN   DEF 8086
oc IO       DEF 8086
oc LINEIO   DEF 8086
oc LIO      DEF 8086
oc PARMS    DEF 8086
oc TERM     DEF 8086
oc ABU      DEF 8086
REM the following line will re-link the ABU
REM example for you.
link abu+screen+disk+term+parms+sys ;
oc OEIO     DEF 8086
oc OETREE   DEF 8086
oc OENAMES  DEF 8086
oc OEPHONE  DEF 8086
oc OE       DEF 8086
REM the line below will re-link the OE
REM example for you.
link oe+oeio+oetree+oenames+oephone+term+sys ;
