#!/bin/bash
# 0098-curtana-make-support.sh
# Purpose: Ensure CURTANA/SWEET machine config support in XNU build system.
#          This runs BEFORE patches via DXB's *.sh pipeline.
set -euo pipefail

# Always apply for CURTANA builds (MACHINE_CONFIG env var is set by workflow)
if [[ "${MACHINE_CONFIG:-}" != "CURTANA" ]]; then
    exit 0
fi

XNU_ROOT="${WORK_DIR:-.}/xnu"
[[ -d "$XNU_ROOT" ]] || { echo "0098: xnu root not found at $XNU_ROOT"; exit 0; }

echo "0098: Applying CURTANA make support fixes..."

# Add NO_MONITOR to SWEET.h if missing (backup safeguard — 0099 should do this)
SWEET_H="$XNU_ROOT/pexpert/pexpert/arm64/SWEET.h"
if [[ -f "$SWEET_H" ]] && ! grep -q "NO_MONITOR" "$SWEET_H"; then
    echo "0098: Adding NO_MONITOR to $SWEET_H"
    sed -i '' '/#define SWEET_SMP_MAX_CPUS 8/a \\n#define NO_MONITOR              1' "$SWEET_H"
else
    echo "0098: SWEET.h already has NO_MONITOR (or file missing)"
fi

# CRITICAL FIX: MakeInc.kernel has its OWN independent SUPPORTED_ARM64_MACHINE_CONFIGS check
# that 0099 does NOT patch. Must add CURTANA here or build fails with:
#   "Unsupported CURRENT_MACHINE_CONFIG CURTANA"
MAKEINC_KERNEL="$XNU_ROOT/makedefs/MakeInc.kernel"
if [[ -f "$MAKEINC_KERNEL" ]] && ! grep -q "CURTANA" "$MAKEINC_KERNEL"; then
    echo "0098: Adding CURTANA to SUPPORTED_ARM64_MACHINE_CONFIGS in MakeInc.kernel"
    sed -i '' 's/^SUPPORTED_ARM64_MACHINE_CONFIGS = .*$/& CURTANA/' "$MAKEINC_KERNEL"
else
    echo "0098: MakeInc.kernel already has CURTANA (or file missing)"
fi

echo "0098: CURTANA make support configured successfully"
exit 0
