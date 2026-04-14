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
 DO ASSIGNKEYS
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
 ;
 ; Remove the lock key from the option (piece 6 of node 0) so all
 ; authenticated users can use this context in the test environment.
 ; The FOIA RPMS import sets piece 6 to "XUPROGMODE", requiring the
 ; XUPROGMODE security key — unnecessary for development/testing.
 IF IEN DO
 . NEW LOCK SET LOCK=$PIECE($GET(^DIC(19,IEN,0)),"^",6)
 . IF LOCK]"" DO
 . . SET $PIECE(^DIC(19,IEN,0),"^",6)=""
 . . WRITE "  XUPROGMODE lock key removed (was '"_LOCK_"')",!
 QUIT
 ;
ASSIGNKEYS ;
 ; Assign the XUPROGMODE security key to test users so they can
 ; use the programmer-mode broker context even if the lock is restored.
 ;
 NEW KEYIEN
 SET KEYIEN=$ORDER(^DIC(19.1,"B","XUPROGMODE",0))
 IF 'KEYIEN DO  QUIT
 . WRITE "  XUPROGMODE security key not found in file 19.1 - skipping",!
 ;
 ; Assign to users 1 (PROVIDER), 2 (PROGRAMMER), 3 (NURSE)
 DO GIVEKEY(1,KEYIEN)
 DO GIVEKEY(2,KEYIEN)
 DO GIVEKEY(3,KEYIEN)
 QUIT
 ;
GIVEKEY(DUZ,KEYIEN) ;
 ; Add security key KEYIEN to user DUZ in the KEYS multiple (200.051)
 ; Skip if user already holds this key.
 ;
 IF $DATA(^VA(200,DUZ,51,"B",KEYIEN)) DO  QUIT
 . WRITE "  User ",DUZ,": already holds XUPROGMODE key",!
 ;
 NEW NEXTIEN,HEADER
 SET HEADER=$GET(^VA(200,DUZ,51,0))
 IF HEADER="" SET HEADER="^200.051PA^0^0"
 SET NEXTIEN=$PIECE(HEADER,"^",3)+1
 ;
 ; Add the key entry: IEN^active_flag^date_assigned
 SET ^VA(200,DUZ,51,NEXTIEN,0)=KEYIEN_"^1^"_$PIECE($HOROLOG,",",1)
 SET ^VA(200,DUZ,51,"B",KEYIEN,NEXTIEN)=""
 ;
 ; Update sub-file header
 SET $PIECE(^VA(200,DUZ,51,0),"^",3)=NEXTIEN
 SET $PIECE(^VA(200,DUZ,51,0),"^",4)=$PIECE(HEADER,"^",4)+1
 ;
 WRITE "  User ",DUZ,": XUPROGMODE key assigned (key IEN=",KEYIEN,")",!
 QUIT
