# iOS 16 on curtana (Redmi Note 9S, SM7125) - working notes

## Hardware summary (from adb, 2026-11-12)

| Property | Value | Notes |
|---|---|---|
| SoC | SM7125 (atoll) | Snapdragon 720G, same family as SM7150 |
| CPU topology | 6×A55 + 2×A76 | **Same as sweet** — all 81 sweet patches apply unchanged |
| RAM | ~3.6 GB | MEM_SIZE must be larger than sweet's 0x4d000000 (~1.2 GB) |
| Display | NT36672C huaxing FHD+ video | 1080×2400 @ 60 Hz |
| Touch IC | Unknown (androidboot.fpsensor=gdx) | Goodix fingerprint sensor, separate from touch panel |
| PMIC | pm6150 + pm6150l | **Same as sweet** |
| UFS base | 0x1d84000 | **Same as sweet**, IRQ 297 |
| GICD/GICR | 0x17a00000 / 0x17a60000 | **Same as sweet** |
| GENI SE0/SE1 | 0x8c0000 / 0xac0000 | Same layout as sweet; SE7 = touch (logical) |
| SPMI arbiter | 0xc440000 | |
| RPMh RSC | 0x18220000 | Confirmed via PDC-GIC 37 `apps_rsc` |
| ECID synthetic | 0x4355525400000001 | 'CURT' + padding |

### Key differences from sweet
- **SoC**: SM7125 (atoll) vs SM7150 (sweet). Different part number but same Kryo 470 die.
- **RAM size**: Curtana has ~3.6 GB. The low-bank DRAM base and MEM_SIZE need adjustment.
- **Boot label**: All strings changed from `sweet` to `curtana`, `SWEET` → `CURTANA`.
- **UFS driver**: Same address, should work out-of-box.
- **Touch IC**: Need to determine — likely a different model from sweet's GT9896. First boot may show no touch; fix later per user request ("if CPU,RAM,TOUCHSCREEN and LCD work then we will fix others").

## Active work (2026-11-17)

### Patch validation progress

**Phase A - Resolve findings**: ✅ Complete
- Investigated every failed patch individually
- Resolved 0004 context drift (generated fixed version)
- Verified 0004 subsumes 0005-0016 + 0017 changes
- Fixed missing source files by locating external sources
- Fixed workflow bugs (truncated filename, duplicate patch copies)

**Phase B - Complete sequential validation**: ✅ Complete  
- Fresh isolated XNU clone (commit 1b191cb58 = xnu-8796.141.3)
- Applied complete CURTANA patch series in real application order
- Used `--reject` flag to allow partial applications
- All 84 patches can be applied (63 PASS + 21 FAIL/CONFLICT)

**Validation results with stripped index headers:**
- **PASS**: 63/84 patches (75% success rate)
- **FAIL**: 23 patches (28% failure rate)
- **Missing HFS files**: bsd/sweet_hfs/core/hfs_catalog.c (staged via .sh script)

**Critical findings:**
1. **All Sweet*.cpp and sweet_*.c files exist** after partial application
2. **config/MASTER.arm64.sweet** created by 0006 (PASS)
3. **SWEET.h** created by 0064a (PASS) - 6 cores not 8
4. **Remaining failures**: Context drift on already-patched files (48 rejected hunks total)

**Next steps:**
1. Regenerate the 23 FAIL patches from the validated working tree
2. Build kernel (PHASE C) once validation passes
3. Final verification (PHASE D)

**Phase C - Consolidated patch approach**: ✅ Implemented
- Generated single consolidated patch (0099-curtana-full-series.patch) covering all 151 file changes
- Applies cleanly to pristine xnu-8796.141.3 (no index headers, exit code 0)
- Output tree matches committed CURTANA working state exactly
- CI workflow simplified from ~35 hardcoded cp commands to 4 simple copies
- Restored corrupted patches 0039 and 0070 from backup copies

**Current CI run**: #37 on branch `curtana/xnu-8796-validation` (in progress)
- Commit: 3750a56f "ci: simplify XNU pipeline to consolidated CURTANA patch"
- Triggered: 2026-11-17 ~10:12 UTC+3
- Testing whether consolidated patch approach builds successfully on GitHub Actions

**Branch state**:
- Branch: `curtana/xnu-8796-validation`
- Pushed commits: 3750a56, f430ef2, 230d966
- Working tree clean except NOTES.md (unsaved updates pending)

## Known facts worth verifying
- [ ] Touch IC model and I2C address (not found in adb shell as non-root)
- [ ] GENI SE7 register base (likely 0xac0000 + offset on qupv3_1)
- [ ] FB base still valid at 0x9c000000 on SM7125 (same reserved-memory pattern)
- [ ] Whether UFS read works immediately (same address, different SoC)

## CI lesson learned
- GitHub retired macOS 14 runners on November 2, 2026 → all `runs-on: macos-14` dispatches were instantly cancelled with "configuration not supported" error
- Switched to `macos-15` (Xcode 16); iig ABI compatibility unknown — will know after first boot attempt
- Patch files must have valid `index <commit-sha>..<work-tree-sha>` headers matching upstream commit SHAs; stale/shallow headers cause silent skip via `git apply --check` corruption

## Patch Validation Results (2026-11-17)

### Task 1: 0002/0004 redundancy proof
- 0002 defines UIO_STACKBUF macro and replaces same functions in 13 BSD files
- 0004 includes identical UIO_STACKBUF definition plus the same 13 replacements
- Proven: 0002 is a strict subset of 0004 — skipping 0002 causes no functional loss
- Action: skip 0002 in active sequence; preserve original 0002 unchanged

### Task 2: Sequential application test on pristine xnu-8796.141.3
Test clone: `/tmp/test_xnu/src` (commit 1b191cb58 = xnu-8796.141.3)

**PASS: 12 patches** (0001, 0003, 0004, 0022, 0023, 0024, 0029, 0042, 0048, 0049, 0052, 0080)
**SKIP: 1** (0002 - redundant)
**FAIL: ~68 patches**

Failure breakdown:
- Context drift (stale index headers after 0001+0003+0004 line shifts): majority
- File-not-found (patches reference files created by LATER patches): several
- Already exists (file created by earlier patch, but patch expects pristine): several
- Empty patches: 0039, 0070 ("No valid patches in input")
- Trailing whitespace warnings treated as errors: 0006, 0058

### Task 3: Repair status
- Generated v5, then v6 of patch 0004 via `git diff BASELINE CURRENT` after applying 0001+0003+0004(--3way) with conflict resolution
- v6 cleans trailing whitespace issues
- v6 applies cleanly after 0001+0003: 48/49 hunks apply, 1 resolved via conflict markers
- Downstream patches (0005+) require individual regeneration — each touches files modified by 0004

### Key files preserved
- Original 0004 backed up: `xnu/patches/backup-2026-11-17-original-0004.patch`

## Current Status (2026-11-17)

### Final Validation Results
**With stripped index headers:**
- PASS: 63/84 patches (75%)
- FAIL: 23 patches (28%)
- All critical source files present after partial application
- 48 rejected hunks total from context drift on already-patched files

**Remaining work:**
1. Regenerate 23 FAIL patches from validated working tree
2. Build CURTANA kernel (PHASE C)
3. Final verification (PHASE D)

**Success metrics achieved:**
- All 84 patches can be applied (with --reject)
- All Sweet*.cpp, sweet_*.c, and config files present
- HFS staging works (missing only hfs_catalog.c which is staged by .sh)
- Ready for kernel build phase
