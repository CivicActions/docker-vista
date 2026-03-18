ZSTU ;Startup routine - RPC brokers (no TaskMan)
 ; XWB Broker on port 9100
 J LISTEN^%ZISTCPS(9100,"NT^XWBTCPM"):"RPMS"
 ; BMX Broker on port 9101
 J LISTEN^%ZISTCPS(9101,"NT^BMXMON"):"RPMS"
 QUIT
