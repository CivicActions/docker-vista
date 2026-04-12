ROUTINE seedoptions [Type=MAC]
seedoptions ; Register missing broker context options
 ;
 ; Ensures XUPROGMODE exists as a type-B (Broker context) option
 ; in the OPTION file (^DIC(19)) so that XWB CREATE CONTEXT
 ; can succeed for programmer-mode clients.
 ;
 WRITE "=== Seeding Application Context Options ===",!
 ;
 DO XUPROGMODE
 ;
 WRITE !,"=== Option Seeding Complete ===",!
 QUIT
 ;
XUPROGMODE ;
 ; Check if XUPROGMODE already exists as a type-B option
 NEW IEN,FOUND
 SET FOUND=0
 SET IEN=$ORDER(^DIC(19,"B","XUPROGMODE",0))
 IF IEN DO
 . SET FOUND=1
 . ; Verify it's type B
 . NEW TYPE SET TYPE=$PIECE($GET(^DIC(19,IEN,0)),"^",4)
 . IF TYPE="B" DO
 . . WRITE "  XUPROGMODE already registered as type-B context (IEN="_IEN_")",!
 . ELSE  DO
 . . ; Update type to B
 . . SET $PIECE(^DIC(19,IEN,0),"^",4)="B"
 . . WRITE "  XUPROGMODE updated to type-B context (IEN="_IEN_")",!
 ;
 IF 'FOUND DO
 . ; Find next available IEN
 . NEW NEXTIEN
 . SET NEXTIEN=$PIECE($GET(^DIC(19,0)),"^",3)+1
 . ; Create the option entry
 . SET ^DIC(19,NEXTIEN,0)="XUPROGMODE^^^^B"
 . SET ^DIC(19,"B","XUPROGMODE",NEXTIEN)=""
 . ; Update file header
 . SET $PIECE(^DIC(19,0),"^",3)=NEXTIEN
 . SET $PIECE(^DIC(19,0),"^",4)=$GET(^DIC(19,0,"count"))+1
 . WRITE "  XUPROGMODE created as type-B context (IEN="_NEXTIEN_")",!
 QUIT
