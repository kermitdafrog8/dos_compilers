ntvdm -r:. -e:include=. lc -ms -v -g %1.c

ntvdm link s\c.obj %1.obj,%1,,s\lc.lib+lapi.lib



