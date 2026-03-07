ROUTINE compilertn [Type=MAC]
compilertn ; Compile all MAC routines in current namespace
 ;
 ; Iterates ^rMAC and compiles each routine via %Routine.Compile()
 ; Errors are expected for platform-specific code (e.g. VMS $&ZLIB calls)
 ;
 SET name="",ok=0,err=0,total=0
 FOR  SET name=$ORDER(^rMAC(name)) QUIT:name=""  DO
 . SET total=total+1
 . SET rtn=##class(%Routine).%OpenId(name_".MAC")
 . IF '$ISOBJECT(rtn) SET err=err+1 QUIT
 . SET sc=rtn.Compile()
 . IF sc SET ok=ok+1
 . ELSE  SET err=err+1
 . IF total#2000=0 WRITE "  Compiled "_total_" routines...",!
 WRITE "Routines compiled: "_ok_" ok, "_err_" errors, "_total_" total",!
 QUIT
