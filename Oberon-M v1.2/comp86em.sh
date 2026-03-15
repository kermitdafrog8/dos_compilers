# This batch file recompiles everything in the
# distribution package to use the 8086/8088
# downward-compatibility option.
ntvdm -c -r:. -u OC DISK     DEF 8086
ntvdm -c -r:. -u OC SCREEN   DEF 8086
ntvdm -c -r:. -u OC IO       DEF 8086
ntvdm -c -r:. -u OC LINEIO   DEF 8086
ntvdm -c -r:. -u OC LIO      DEF 8086
ntvdm -c -r:. -u OC PARMS    DEF 8086
ntvdm -c -r:. -u OC TERM     DEF 8086
ntvdm -c -r:. -u OC ABU      DEF 8086
# the following line will re-link the ABU
# example for you.
ntvdm -c -r:. -u link abu+screen+disk+term+parms+sys \;
ntvdm -c -r:. -u OC OEIO     DEF 8086
ntvdm -c -r:. -u OC OETREE   DEF 8086
ntvdm -c -r:. -u OC OENAMES  DEF 8086
ntvdm -c -r:. -u OC OEPHONE  DEF 8086
ntvdm -c -r:. -u OC OE       DEF 8086
# the line below will re-link the OE
# example for you.
ntvdm -c -r:. -u LINK oe+oeio+oetree+oenames+oephone+term+sys \;

