str=$(tr '[a-z]' '[A-Z]' <<< $1)

rm $str.EXE 2>/dev/null

ntvdm -u -r:. qpl $str.pas

ntvdm -r:. -u -p $str