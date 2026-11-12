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

## Active work (2026-11-12)
Creating curtana-specific adaptations:
1. ✅ `tools/mkadt.py` — updated for curtana (curtana-io, curtana-fbcon, xiaomi,curtana/qcom,sm7125 compat)
2. ✅ Memory sizing — MEM_SIZE adjusted for ~3.6 GB (low bank starts at 0xb0000000)
3. ✅ Kernel patches — all 50+ sweet patches extended with `|| defined(CURTANA)` guards; 4 dedicated curtana patches added (0092-0096)
4. ✅ **First CURTANA kernel built via GitHub Actions CI**
   - Run: https://github.com/razeandruins-studios/ios-sweet/actions/runs/43213151467
   - Commit: `de15ea8` (macos-13→15 fix) + `1d73d52` (comment update)
   - Kernel: `kernel.development.sweet` (17 MB, Mach-O 64-bit arm64)
   - SHA-256: `b7f027674c8edc74d7bf76f5a9ed2a4bfc7b65dfa44efa21f4df154e227549a5`
   - All 11 build steps passed in ~11 minutes
5. 🔲 Next: Generate ADT and prepare boot image for device test

## Known facts worth verifying
- [ ] Touch IC model and I2C address (not found in adb shell as non-root)
- [ ] GENI SE7 register base (likely 0xac0000 + offset on qupv3_1)
- [ ] FB base still valid at 0x9c000000 on SM7125 (same reserved-memory pattern)
- [ ] Whether UFS read works immediately (same address, different SoC)

## CI lesson learned
- GitHub retired macOS 14 runners on November 2, 2026 → all `runs-on: macos-14` dispatches were instantly cancelled with "configuration not supported" error
- Switched to `macos-15` (Xcode 16); iig ABI compatibility unknown — will know after first boot attempt
