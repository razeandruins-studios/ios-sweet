#!/bin/bash
# 0098-curtana-make-support.sh
# Purpose: Ensure CURTANA/SWEET machine config support in XNU build system.
#          This runs BEFORE patches via DXB's *.sh pipeline.
#          Scripts execute from the XNU source root (same as other *.sh patches).
set -euo pipefail

[[ "${MACHINE_CONFIG:-}" == SWEET || "${MACHINE_CONFIG:-}" == CURTANA ]] || exit 0

# Verify we're running from xnu source root (like other staging scripts)
[[ -f Makefile ]] || { echo "0098: not in xnu source root"; exit 0; }

echo "0098: Applying CURTANA make support fixes..."

# Add NO_MONITOR to SWEET.h if missing (backup safeguard — 0099 should handle this)
SWEET_H="pexpert/pexpert/arm64/SWEET.h"
if [[ -f "$SWEET_H" ]] && ! grep -q "NO_MONITOR" "$SWEET_H"; then
    echo "0098: Adding NO_MONITOR to $SWEET_H"
    sed -i '/#define SWEET_SMP_MAX_CPUS 8/a \
\
#define NO_MONITOR              1' "$SWEET_H"
else
    echo "0098: SWEET.h OK (already has NO_MONITOR or file missing)"
fi

# CRITICAL FIX: Add CURTANA and SWEET to SUPPORTED_ARM64_MACHINE_CONFIGS in MakeInc.def
MAKEINC_DEF="makedefs/MakeInc.def"
if [[ -f "$MAKEINC_DEF" ]]; then
    if ! grep -q "SWEET CURTANA" "$MAKEINC_DEF"; then
        echo "0098: Adding SWEET and CURTANA to SUPPORTED list in $MAKEINC_DEF"
        sed -i 's/^SUPPORTED_ARM64_MACHINE_CONFIGS = \(.*VMAPPLE\)$/\1 SWEET CURTANA/' "$MAKEINC_DEF"
    else
        echo "0098: MakeInc.def already has SWEET/CURTANA in SUPPORTED list"
    fi

    # Add MACHINE_FLAGS for SWEET and CURTANA if missing
    if ! grep -q "MACHINE_FLAGS_ARM64_SWEET" "$MAKEINC_DEF"; then
        echo "0098: Adding MACHINE_FLAGS for SWEET and CURTANA"
        sed -i '/^MACHINE_FLAGS_ARM64_/a MACHINE_FLAGS_ARM64_SWEET = -DARM64_BOARD_CONFIG_SWEET                -march=armv8.2-a+crypto\nMACHINE_FLAGS_ARM64_CURTANA = -DARM64_BOARD_CONFIG_CURTANA            -march=armv8.2-a+crypto' "$MAKEINC_DEF"
    else
        echo "0098: MACHINE_FLAGS already present"
    fi
else
    echo "0098: WARNING: $MAKEINC_DEF not found"
fi

echo "0098: CURTANA make support configured successfully"
exit 0
