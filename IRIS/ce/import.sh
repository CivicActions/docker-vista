#!/bin/bash
#---------------------------------------------------------------------------
# RPMS/VistA Import Script for IRIS Community Edition
#
# Imports routines (.m) and globals (.zwr) from a VistA-M or FOIA-RPMS
# repository into the target namespace. Runs ZTMGRSET and post-install.
#
# Expects IRIS to already be running (started by the Dockerfile RUN step).
#
# Environment:
#   SOURCE_DIR  - Override source directory (default: /opt/vista/source)
#   SCRIPTS_DIR - Override scripts directory (default: /opt/vista/scripts)
#   NAMESPACE   - Override namespace (default: RPMS)
#---------------------------------------------------------------------------
# Steps 1-2 (import) are critical; steps 3-5 are best-effort configuration
set -e

echo "=== IRIS CE Import Script ==="
echo "Starting import at $(date)"

IRIS_INSTANCE="IRIS"
NAMESPACE="${NAMESPACE:-RPMS}"
NAMESPACE=$(echo "$NAMESPACE" | tr '[:lower:]' '[:upper:]')
SOURCE_DIR="${SOURCE_DIR:-/opt/vista/source}"
SCRIPTS_DIR="${SCRIPTS_DIR:-/opt/vista/scripts}"

# --- Step 0: Create Database, Namespace, and Mappings ---
echo ""
echo "=== Step 0: Creating Database and Namespace ==="
iris session "$IRIS_INSTANCE" -B <<NSEOF
ZN "%SYS"
DO \$SYSTEM.OBJ.Load("${SCRIPTS_DIR}/setup-namespace.m","ck-d")
DO ^setupns
HALT
NSEOF
echo "  Namespace setup complete"

# --- Step 1: Import Routines (.m files) ---
echo ""
echo "=== Step 1: Importing Routines ==="
ROUTINE_COUNT=$(find "$SOURCE_DIR" -name "*.m" -type f | wc -l)
echo "  Found $ROUTINE_COUNT routine files"
find "$SOURCE_DIR" -name "*.m" -type f > /tmp/routines.lst
# Include KBANTCLN.m (from Common/ — no ROUTINE header so $SYSTEM.OBJ.Load can't handle it)
if [ -f "$SCRIPTS_DIR/KBANTCLN.m" ]; then
    echo "${SCRIPTS_DIR}/KBANTCLN.m" >> /tmp/routines.lst
fi
iris session "$IRIS_INSTANCE" -B <<RTNEOF
ZN "${NAMESPACE}"
DO \$SYSTEM.OBJ.Load("${SCRIPTS_DIR}/importrtn.m","ck-d")
DO ^importrtn
HALT
RTNEOF
echo "  Routine import complete"
rm -f /tmp/routines.lst

# --- Step 1b: Compile Routines ---
echo ""
echo "=== Step 1b: Compiling Routines ==="
iris session "$IRIS_INSTANCE" -B <<CMPEOF
ZN "${NAMESPACE}"
DO \$SYSTEM.OBJ.Load("${SCRIPTS_DIR}/compilertn.m","ck-d")
DO ^compilertn
HALT
CMPEOF
echo "  Routine compile complete"

# --- Step 2: Import Globals (.zwr files) ---
echo ""
echo "=== Step 2: Importing Globals ==="
GLOBAL_COUNT=$(find "$SOURCE_DIR" -name "*.zwr" -type f | wc -l)
echo "  Found $GLOBAL_COUNT global files"
find "$SOURCE_DIR" -name "*.zwr" -type f > /tmp/globals.lst
iris session "$IRIS_INSTANCE" -B <<GBLEOF
ZN "${NAMESPACE}"
DO \$SYSTEM.OBJ.Load("${SCRIPTS_DIR}/importgbl.m","ck-d")
DO ^importgbl
HALT
GBLEOF
echo "  Global import complete"
rm -f /tmp/globals.lst

# --- Step 3: Run KBANTCLN ---
# From here on, steps are best-effort (non-fatal)
set +e
echo ""
echo "=== Step 3: Running KBANTCLN ==="
if [ -f "$SCRIPTS_DIR/KBANTCLN.m" ]; then
    # KBANTCLN was already imported in Step 1 and compiled in Step 1b
    iris session "$IRIS_INSTANCE" -B <<KBANEOF
ZN "${NAMESPACE}"
IF \$TEXT(START^KBANTCLN)]"" DO START^KBANTCLN("ROU","${NAMESPACE}",9999,"RPMS SANDBOX","RPMS.SANDBOX.OSEHRA.ORG")
HALT
KBANEOF
    echo "  KBANTCLN complete (exit: $?)"
else
    echo "  KBANTCLN.m not found - skipping"
fi

# --- Step 4: (Removed — KBANTCLN in Step 3 replaces interactive ZTMGRSET) ---
# KBANTCLN calls DES^ZTMGRSET, MOVE^ZTMGRSET, RUM^ZTMGRSET, ALL^ZTMGRSET,
# and GLOBALS^ZTMGRSET non-interactively.  Running ZTMGRSET interactively
# after KBANTCLN causes <ENDOFFILE> errors due to changed prompt sequence.

# --- Step 5: Post-install configuration ---
echo ""
echo "=== Step 5: Running Post-Install Configuration ==="
POSTINSTALL="$SCRIPTS_DIR/postinstall.m"
if [ -f "$POSTINSTALL" ]; then
    iris session "$IRIS_INSTANCE" -B <<POSTEOF || echo "  Post-install had warnings (non-fatal)"
ZN "${NAMESPACE}"
DO \$SYSTEM.OBJ.Load("${POSTINSTALL}","ck-d")
DO ^postinstall
HALT
POSTEOF
    echo "  Post-install complete"
else
    echo "  postinstall.m not found - skipping"
fi

# --- Step 6: Seed test users ---
echo ""
echo "=== Step 6: Seeding Test Users ==="
SEEDUSERS="$SCRIPTS_DIR/seedusers.m"
if [ -f "$SEEDUSERS" ]; then
    iris session "$IRIS_INSTANCE" -B <<SEEDEOF || echo "  Seed users had warnings (non-fatal)"
ZN "${NAMESPACE}"
DO \$SYSTEM.OBJ.Load("${SEEDUSERS}","ck-d")
DO ^seedusers
HALT
SEEDEOF
    echo "  Seed users complete"
else
    echo "  seedusers.m not found - skipping"
fi

# --- Step 7: Register application context options ---
echo ""
echo "=== Step 7: Registering Application Context Options ==="
SEEDOPTIONS="$SCRIPTS_DIR/seedoptions.m"
if [ -f "$SEEDOPTIONS" ]; then
    iris session "$IRIS_INSTANCE" -B <<OPTEOF || echo "  Seed options had warnings (non-fatal)"
ZN "${NAMESPACE}"
DO \$SYSTEM.OBJ.Load("${SEEDOPTIONS}","ck-d")
DO ^seedoptions
HALT
OPTEOF
    echo "  Seed options complete"
else
    echo "  seedoptions.m not found - skipping"
fi

# --- Step 8: Seed test patients ---
echo ""
echo "=== Step 8: Seeding Test Patients ==="
SEEDPATIENTS="$SCRIPTS_DIR/seedpatients.m"
if [ -f "$SEEDPATIENTS" ]; then
    iris session "$IRIS_INSTANCE" -B <<PATEOF || echo "  Seed patients had warnings (non-fatal)"
ZN "${NAMESPACE}"
DO \$SYSTEM.OBJ.Load("${SEEDPATIENTS}","ck-d")
DO ^seedpatients
HALT
PATEOF
    echo "  Seed patients complete"
else
    echo "  seedpatients.m not found - skipping"
fi

# --- Step 9: Patch %ZOSV and fix NULL device ---
echo ""
echo "=== Step 9: Patching %ZOSV and Device Configuration ==="
# Add missing PRI entry point to %ZOSV (needed by %ZIS for XWB broker)
ZOSVONT=$(find "$SOURCE_DIR" -name "ZOSVONT.m" -type f | head -1)
if [ -n "$ZOSVONT" ]; then
    cp "$ZOSVONT" /tmp/zosvont_patched.m
    printf 'PRI() ;Return process priority for IRIS\n Q 8 ;Normal priority\n' >> /tmp/zosvont_patched.m
    # Add ROUTINE header for IRIS loading
    { echo 'ROUTINE %ZOSV [Type=MAC]'; cat /tmp/zosvont_patched.m; } > /tmp/zosv_final.m
    iris session "$IRIS_INSTANCE" -B <<ZOSVEOF || echo "  %ZOSV patch had warnings (non-fatal)"
ZN "${NAMESPACE}"
DO \$SYSTEM.OBJ.Load("/tmp/zosv_final.m","ck-d")
IF \$TEXT(PRI^%ZOSV)]"" WRITE "  PRI^%ZOSV patched successfully",!
HALT
ZOSVEOF
    rm -f /tmp/zosvont_patched.m /tmp/zosv_final.m
fi
# Fix NULL device path from Windows (//./nul) to Linux (/dev/null)
iris session "$IRIS_INSTANCE" -B <<NULLEOF || echo "  NULL device fix had warnings (non-fatal)"
ZN "${NAMESPACE}"
NEW I SET I=0 FOR  SET I=\$ORDER(^%ZIS(1,I)) QUIT:'I  IF \$GET(^%ZIS(1,I,0))["//./nul" SET \$PIECE(^%ZIS(1,I,0),"^",2)="/dev/null" WRITE "  NULL device ",I," fixed to /dev/null",!
HALT
NULLEOF
echo "  Device configuration complete"

# --- Step 10: Load %ZSTART system startup routine ---
echo ""
echo "=== Step 10: Loading %ZSTART Startup Routine ==="
ZSTU="$SCRIPTS_DIR/ZSTU.m"
if [ -f "$ZSTU" ]; then
    iris session "$IRIS_INSTANCE" -B <<ZSTUEOF || echo "  %ZSTART load had warnings (non-fatal)"
ZN "%SYS"
DO \$SYSTEM.OBJ.Load("${ZSTU}","ck-d")
IF \$TEXT(SYSTEM^%ZSTART)]"" WRITE "  %ZSTART loaded - XWB/BMX listeners will start on boot",!
HALT
ZSTUEOF
    echo "  %ZSTART startup routine loaded"
else
    echo "  ZSTU.m not found - skipping"
fi

echo ""
echo "=== Import Summary ==="
echo "  Source:       $SOURCE_DIR"
echo "  Routines:    $ROUTINE_COUNT files"
echo "  Globals:     $GLOBAL_COUNT files"
echo "  Namespace:   $NAMESPACE"
echo "  Completed at: $(date)"

# Always exit 0 — the critical import steps (1-2) already use set -e;
# steps 3-5 are best-effort and should not fail the build.
exit 0
