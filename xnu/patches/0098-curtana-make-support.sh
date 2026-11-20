#!/bin/bash
# Pre-condition: xnu has been cloned; we're running from the XNU source root.
# Purpose: add CURTANA MACHINE_CONFIG support to makedefs/MakeInc.def so that
#          DXB's build system accepts MACHINE_CONFIG=CURTANA without requiring
#          the consolidated 0099 patch to pass `git apply --check` first.
set -euo pipefail

[[ "${MACHINE_CONFIG:-}" == CURTANA ]] || exit 0

MAKEDefs="makedefs/MakeInc.def"
[[ -f "$MAKEDefs" ]] || {
    echo "CURTANA make support: $MAKEDefs not found" >&2
    exit 1
}

# Add CURTANA to SUPPORTED_ARM64_MACHINE_CONFIGS if not already present.
if ! grep -q '^SUPPORTED_ARM64_MACHINE_CONFIGS.*CURTANA' "$MAKEDefs"; then
    sed -i '' 's/^SUPPORTED_ARM64_MACHINE_CONFIGS = .*/& CURTANA/' "$MAKEDefs"
fi

# Add MACHINE_FLAGS_ARM64_CURTANA entry immediately after the SWEET entry.
if ! grep -q '^MACHINE_FLAGS_ARM64_CURTANA' "$MAKEDefs"; then
    sed -i '' '/^MACHINE_FLAGS_ARM64_SWEET/a MACHINE_FLAGS_ARM64_CURTANA = -DARM64_BOARD_CONFIG_CURTANA            -march=armv8.2-a+crypto' "$MAKEDefs"
fi

echo "CURTANA make support injected into $MAKEDefs"
grep -E "SUPPORTED_ARM64_MACHINE_CONFIGS|MACHINE_FLAGS_ARM64_(SWEET|CURTANA)" "$MAKEDefs"
