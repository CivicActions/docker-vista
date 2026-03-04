ROUTINE setupns [Type=MAC]
setupns ; Create RPMS database, namespace, and mappings
 ;
 ; Run in %SYS namespace AFTER iris start with superserver disabled.
 ; Replaces iris merge of merge-create.cpf and merge-map.cpf so that
 ; we never need the superserver during the build.
 ;
 ; Environment: NAMESPACE (read from /tmp/.iris-namespace)
 ;
 NEW ns,dir,sc,props
 ;
 ; --- Read namespace name from file ---
 SET ns="RPMS"
 TRY {
   OPEN "/tmp/.iris-namespace":("R"):2
   USE "/tmp/.iris-namespace" READ ns
   CLOSE "/tmp/.iris-namespace"
 } CATCH e { }
 IF ns="" SET ns="RPMS"
 SET dir="/usr/irissys/mgr/"_$ZCONVERT(ns,"L")_"/"
 ;
 WRITE "=== Namespace Setup: "_ns_" ===",!
 WRITE "  Database dir: "_dir,!
 ;
 ; --- Step 1: Create Database ---
 WRITE "Creating database...",!
 ; First create the physical IRIS.DAT file
 SET sc=##class(SYS.Database).CreateDatabase(dir)
 IF 'sc WRITE "  ERROR creating database file: ",$SYSTEM.Status.GetErrorText(sc),! QUIT
 WRITE "  Database file created.",!
 ; Then register in CPF configuration
 KILL props
 SET props("Directory")=dir
 SET sc=##class(Config.Databases).Create(ns,.props)
 IF 'sc WRITE "  ERROR registering database: ",$SYSTEM.Status.GetErrorText(sc),! QUIT
 WRITE "  Database registered.",!
 ;
 ; --- Step 2: Create Namespace ---
 WRITE "Creating namespace...",!
 KILL props
 SET props("Globals")=ns
 SET props("Routines")=ns
 SET props("Library")="IRISLIB"
 SET sc=##class(Config.Namespaces).Create(ns,.props)
 IF 'sc WRITE "  ERROR creating namespace: ",$SYSTEM.Status.GetErrorText(sc),! QUIT
 WRITE "  Namespace created.",!
 ;
 ; --- Step 3: Add Routine Mappings ---
 WRITE "Adding routine mappings...",!
 DO MAP("Routine",ns,"%","Routine_%")
 DO MAP("Routine",ns,"%DT*","Routine_%DT*")
 DO MAP("Routine",ns,"%HOSTCMD","Routine_%HOSTCMD")
 DO MAP("Routine",ns,"%INET","Routine_%INET")
 DO MAP("Routine",ns,"%RCR","Routine_%RCR")
 DO MAP("Routine",ns,"%XB*","Routine_%XB*")
 DO MAP("Routine",ns,"%XU*","Routine_%XU*")
 DO MAP("Routine",ns,"%Z*","Routine_%Z*")
 DO MAP("Routine",ns,"%ut*","Routine_%ut*")
 ;
 ; --- Step 4: Add Global Mappings ---
 WRITE "Adding global mappings...",!
 ; System globals to RPMS database
 DO GMAP(ns,"%Z*",ns,"Global_%Z*")
 DO GMAP(ns,"%ut*",ns,"Global_%ut*")
 DO GMAP(ns,"%z*",ns,"Global_%z*")
 ;
 ; Temporary globals to IRISTEMP
 DO GMAP(ns,"HLTMP","IRISTEMP","Global_HLTMP")
 DO GMAP(ns,"TMP","IRISTEMP","Global_TMP")
 DO GMAP(ns,"TEMP","IRISTEMP","Global_TEMP")
 DO GMAP(ns,"UTILITY","IRISTEMP","Global_UTILITY")
 DO GMAP(ns,"XTMP","IRISTEMP","Global_XTMP")
 DO GMAP(ns,"XUTL","IRISTEMP","Global_XUTL")
 DO GMAP(ns,"BMXTMP","IRISTEMP","Global_BMXTMP")
 DO GMAP(ns,"KMPTMP","IRISTEMP","Global_KMPTMP")
 DO GMAP(ns,"DISV","IRISTEMP","Global_DISV")
 DO GMAP(ns,"DOSV","IRISTEMP","Global_DOSV")
 DO GMAP(ns,"SPOOL","IRISTEMP","Global_SPOOL")
 ;
 ; RPMS-specific temporary globals to IRISTEMP
 DO GMAP(ns,"ABMDTMP","IRISTEMP","Global_ABMDTMP")
 DO GMAP(ns,"ACPTEMP","IRISTEMP","Global_ACPTEMP")
 DO GMAP(ns,"AGSSTEMP","IRISTEMP","Global_AGSSTEMP")
 DO GMAP(ns,"AGSSTMP1","IRISTEMP","Global_AGSSTMP1")
 DO GMAP(ns,"AGSTEMP","IRISTEMP","Global_AGSTEMP")
 DO GMAP(ns,"AGTMP","IRISTEMP","Global_AGTMP")
 DO GMAP(ns,"APCHTMP","IRISTEMP","Global_APCHTMP")
 DO GMAP(ns,"ATXTMP","IRISTEMP","Global_ATXTMP")
 DO GMAP(ns,"AUMDDTMP","IRISTEMP","Global_AUMDDTMP")
 DO GMAP(ns,"AUMDOTMP","IRISTEMP","Global_AUMDOTMP")
 DO GMAP(ns,"AUTTEMP","IRISTEMP","Global_AUTTEMP")
 DO GMAP(ns,"BARTMP","IRISTEMP","Global_BARTMP")
 DO GMAP(ns,"BDMTMP","IRISTEMP","Global_BDMTMP")
 DO GMAP(ns,"BDWBLOG","IRISTEMP","Global_BDWBLOG")
 DO GMAP(ns,"BDWTMP","IRISTEMP","Global_BDWTMP")
 DO GMAP(ns,"BGOTEMP","IRISTEMP","Global_BGOTEMP")
 DO GMAP(ns,"BGOTMP","IRISTEMP","Global_BGOTMP")
 DO GMAP(ns,"BGPELLDBA","IRISTEMP","Global_BGPELLDBA")
 DO GMAP(ns,"BPATEMP","IRISTEMP","Global_BPATEMP")
 DO GMAP(ns,"BPCTMP","IRISTEMP","Global_BPCTMP")
 DO GMAP(ns,"BSDZTMP","IRISTEMP","Global_BSDZTMP")
 DO GMAP(ns,"BGPTMP","IRISTEMP","Global_BGPTMP")
 DO GMAP(ns,"BIPDUE","IRISTEMP","Global_BIPDUE")
 DO GMAP(ns,"BITEMP","IRISTEMP","Global_BITEMP")
 DO GMAP(ns,"BITMP","IRISTEMP","Global_BITMP")
 DO GMAP(ns,"BQIFAC","IRISTEMP","Global_BQIFAC")
 DO GMAP(ns,"BQIPAT","IRISTEMP","Global_BQIPAT")
 DO GMAP(ns,"BQIPROV","IRISTEMP","Global_BQIPROV")
 DO GMAP(ns,"BTPWPQ","IRISTEMP","Global_BTPWPQ")
 DO GMAP(ns,"BTPWQ","IRISTEMP","Global_BTPWQ")
 DO GMAP(ns,"BUSAD","IRISTEMP","Global_BUSAD")
 ;
 WRITE "=== Namespace setup complete ===",!
 QUIT
 ;
MAP(type,ns,name,label) ; Add a routine mapping
 NEW sc,props
 SET props("Database")=ns
 SET sc=##class(Config.MapRoutines).Create(ns,name,.props)
 IF 'sc WRITE "  WARN "_label_": ",$SYSTEM.Status.GetErrorText(sc),!
 QUIT
 ;
GMAP(ns,name,db,label) ; Add a global mapping
 NEW sc,props
 SET props("Database")=db
 SET sc=##class(Config.MapGlobals).Create(ns,name,.props)
 IF 'sc WRITE "  WARN "_label_": ",$SYSTEM.Status.GetErrorText(sc),!
 QUIT
