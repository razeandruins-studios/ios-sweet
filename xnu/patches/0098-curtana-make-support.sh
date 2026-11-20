#!/bin/bash
# 0098-curtana-make-support.sh
# Purpose: Ensure CURTANA/SWEET machine config support in XNU build system.
#          This runs BEFORE patches via DXB's *.sh pipeline.
set -euo pipefail

[[ "${MACHINE_CONFIG:-}" == CURTANA ]] || exit 0

XNU_ROOT="${WORK_DIR:-.}/xnu"
[[ -d "$XNU_ROOT" ]] || { echo "0098: xnu root not found at $XNU_ROOT"; exit 0; }

# Add NO_MONITOR to SWEET.h if missing (backup safeguard)
SWEET_H="$XNU_ROOT/pexpert/pexpert/arm64/SWEET.h"
if [[ -f "$SWEET_H" ]] && ! grep -q "NO_MONITOR" "$SWEET_H"; then
    echo "0098: Adding NO_MONITOR to $SWEET_H"
    sed -i '' '/#define SWEET_SMP_MAX_CPUS 8/a \\n#define NO_MONITOR              1' "$SWEET_H"
fi

# Add CURTANA to SUPPORTED_ARM64_MACHINE_CONFIGS in MakeInc.kernel if missing
MAKEINC_KERNEL="$XNU_ROOT/makedefs/MakeInc.kernel"
if [[ -f "$MAKEINC_KERNEL" ]] && ! grep -q "CURTANA" "$MAKEINC_KERNEL"; then
    echo "0098: Adding CURTANA to SUPPORTED_ARM64_MACHINE_CONFIGS in MakeInc.kernel"
    sed -i '' 's/^SUPPORTED_ARM64_MACHINE_CONFIGS = .*$/& CURTANA/' "$MAKEINC_KERNEL"
fi

echo "0098: CURTANA make support configured"
exit 0
