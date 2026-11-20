#!/bin/bash
# 0098-curtana-make-support.sh
# Purpose: This script is kept as a no-op placeholder.
#          The consolidated 0099-curtana-full-series.patch already handles
#          SWEET/CURTANA support in makedefs/MakeInc.def and
#          osfmk/arm64/proc_reg.h on pristine xnu-8796.141.3.
#          Keeping 0098 as a no-op prevents it from pre-modifying MakeInc.def,
#          which would cause git apply --check to reject the 0099 patch.
set -euo pipefail

[[ "${MACHINE_CONFIG:-}" == CURTANA ]] || exit 0

echo "0098: no-op — 0099 handles CURTANA/SWEET make support on pristine xnu"
exit 0
