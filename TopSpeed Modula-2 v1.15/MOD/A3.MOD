MODULE a3;

 CONST y = "BONJOUR$";

 TYPE  x = ARRAY[0..9] OF SHORTCARD;


(*# call (reg_param =>(),
          reg_saved => (ax,bx,cx,dx,si,di,es,ds,st1,st2),
          inline    => on) *)


PROCEDURE init() = x (0EH,1FH,0BAH,BYTE(Ofs(ADR(y))),BYTE(Ofs(ADR(y))),0B4H,09H,0CDH,21H,0CBH);


BEGIN
 init();
END a3.