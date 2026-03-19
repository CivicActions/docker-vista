ROUTINE seedusers [Type=MAC]
seedusers ; Seed test users for XUS AV CODE authentication
 ;
 ; Creates/updates users in ^VA(200) with hashed ACCESS CODE and
 ; VERIFY CODE values. CHECKAV^XUS hashes user input via $$EN^XUSHSH
 ; before looking up ^VA(200,"A",hash), so the stored values and
 ; cross-references must also be hashed.
 ;
 WRITE "=== Seeding Test Users ===",!
 ;
 DO ADDUSER(1,"PROVIDER,TEST","PT","PROV123","PROV123!!","@")
 DO ADDUSER(2,"PROGRAMMER,SYSTEM","PS","PROG123","PROG123!!","@")
 DO ADDUSER(3,"NURSE,TEST","NT","NURSE123","NURSE123!!","@")
 ;
 WRITE !,"=== Test User Seeding Complete ===",!
 WRITE "  Login format: ACCESS_CODE;VERIFY_CODE",!
 WRITE "  Example: PROV123;PROV123!!",!
 QUIT
 ;
ADDUSER(IEN,NAME,INITIALS,AC,VC,FILEACC) ;
 ; IEN      - Internal Entry Number in ^VA(200)
 ; NAME     - User name (LAST,FIRST format)
 ; INITIALS - Two-letter initials
 ; AC       - Access Code (plaintext — will be hashed)
 ; VC       - Verify Code (plaintext — will be hashed)
 ; FILEACC  - FileMan access string
 ;
 NEW HAC,HVC,OLDAC,OLDNAME
 ;
 ; Hash the codes
 SET HAC=$$EN^XUSHSH(AC)
 SET HVC=$$EN^XUSHSH(VC)
 ;
 ; Clean up old cross-references if user already exists
 SET OLDAC=$PIECE($GET(^VA(200,IEN,0)),"^",3)
 IF OLDAC]"" KILL ^VA(200,"A",OLDAC,IEN)
 SET OLDNAME=$PIECE($GET(^VA(200,IEN,0)),"^",1)
 IF OLDNAME]"" KILL ^VA(200,"B",OLDNAME,IEN)
 ;
 ; Set the user record
 ; Node 0: NAME^INITIALS^HASHED_AC^FILEACC
 SET ^VA(200,IEN,0)=NAME_"^"_INITIALS_"^"_HAC_"^"_FILEACC
 ;
 ; Node .1: piece 2 = HASHED_VC
 SET $PIECE(^VA(200,IEN,.1),"^",2)=HVC
 ;
 ; Cross-references
 SET ^VA(200,"A",HAC,IEN)=""
 SET ^VA(200,"B",NAME,IEN)=""
 ;
 WRITE "  User ",IEN,": ",NAME," (AC=",AC,") - OK",!
 QUIT
