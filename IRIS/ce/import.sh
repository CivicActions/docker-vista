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
iris session "$IRIS_INSTANCE" -U %SYS <<NSEOF
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
iris session "$IRIS_INSTANCE" -U "${NAMESPACE}" <<RTNEOF
DO \$SYSTEM.OBJ.Load("${SCRIPTS_DIR}/importrtn.m","ck-d")
DO ^importrtn
HALT
RTNEOF
echo "  Routine import complete"
rm -f /tmp/routines.lst

# --- Step 2: Import Globals (.zwr files) ---
echo ""
echo "=== Step 2: Importing Globals ==="
GLOBAL_COUNT=$(find "$SOURCE_DIR" -name "*.zwr" -type f | wc -l)
echo "  Found $GLOBAL_COUNT global files"
find "$SOURCE_DIR" -name "*.zwr" -type f > /tmp/globals.lst
iris session "$IRIS_INSTANCE" -U "${NAMESPACE}" <<GBLEOF
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
    iris session "$IRIS_INSTANCE" -U "${NAMESPACE}" <<KBANEOF
DO \$SYSTEM.OBJ.Load("${SCRIPTS_DIR}/KBANTCLN.m","ck-d")
IF \$TEXT(START^KBANTCLN)]"" DO START^KBANTCLN("ROU","${NAMESPACE}",9999,"RPMS SANDBOX","RPMS.SANDBOX.OSEHRA.ORG")
HALT
KBANEOF
    echo "  KBANTCLN complete (exit: $?)"
else
    echo "  KBANTCLN.m not found - skipping"
fi

# --- Step 4: Run ZTMGRSET ---
# ZTMGRSET prompts for the OS type — feed it "IRIS" and confirm
echo ""
echo "=== Step 4: Running ZTMGRSET ==="
iris session "$IRIS_INSTANCE" -U "${NAMESPACE}" <<ZTMEOF
IF \$TEXT(^ZTMGRSET)]"" DO ^ZTMGRSET
IRIS
Y
Y
Y
HALT
ZTMEOF
echo "  ZTMGRSET complete (exit: $?)"

# --- Step 5: Post-install configuration ---
echo ""
echo "=== Step 5: Running Post-Install Configuration ==="
POSTINSTALL="$SCRIPTS_DIR/postinstall.m"
if [ -f "$POSTINSTALL" ]; then
    iris session "$IRIS_INSTANCE" -U "${NAMESPACE}" <<POSTEOF || echo "  Post-install had warnings (non-fatal)"
DO \$SYSTEM.OBJ.Load("${POSTINSTALL}","ck-d")
DO ^postinstall
HALT
POSTEOF
    echo "  Post-install complete"
else
    echo "  postinstall.m not found - skipping"
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
