ROUTINE %ZSTART [Type=MAC]
%ZSTART ;System startup/shutdown callbacks for IRIS
 ;
SYSTEM ;Called by IRIS at system startup
 ; Start XWB Broker on port 9100
 JOB LISTEN^%ZISTCPS(9100,"NT^XWBTCPM"):"RPMS"
 ; Start BMX Broker on port 9101
 JOB LISTEN^%ZISTCPS(9101,"NT^BMXMON"):"RPMS"
 QUIT
 ;
LOGIN ;Called at user login (optional)
 QUIT
 ;
CALLIN ;Called for CALLIN connections (optional)
 QUIT
