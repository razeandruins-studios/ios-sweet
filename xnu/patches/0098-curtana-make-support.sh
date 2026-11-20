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

python3 - "$MAKEDefs" << 'PY'
import re, sys

makefile = sys.argv[1]
with open(makefile, 'r') as f:
    content = f.read()

# Add CURTANA to all SUPPORTED_ARM64_MACHINE_CONFIGS lines that don't already have it.
content = re.sub(
    r'^(SUPPORTED_ARM64_MACHINE_CONFIGS\s*=\s*.+?)(?<!CURTANA)\s*$',
    r'\1 CURTANA',
    content,
    flags=re.MULTILINE
)

# Insert MACHINE_FLAGS_ARM64_CURTANA immediately after VMAPPLE entry.
if 'MACHINE_FLAGS_ARM64_CURTANA' not in content:
    content = content.replace(
        'MACHINE_FLAGS_ARM64_VMAPPLE = -DARM64_BOARD_CONFIG_VMAPPLE              -march=armv8.5a\n',
        'MACHINE_FLAGS_ARM64_VMAPPLE = -DARM64_BOARD_CONFIG_VMAPPLE              -march=armv8.5a\nMACHINE_FLAGS_ARM64_CURTANA = -DARM64_BOARD_CONFIG_CURTANA            -march=armv8.2-a+crypto\n'
    )

with open(makefile, 'w') as f:
    f.write(content)
PY

echo "CURTANA make support injected into $MAKEDefs"
grep -nE "SUPPORTED_ARM64_MACHINE_CONFIGS|MACHINE_FLAGS_ARM64_(VMAPPLE|CURTANA)" "$MAKEDefs"
