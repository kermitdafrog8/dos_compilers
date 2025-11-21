str=$(tr '[a-z]' '[A-Z]' <<< $1)

rm $str.EXE 2>/dev/null

ntvdm /r:. -t -e:MCDIR=. cc $str m=S -q
echo

