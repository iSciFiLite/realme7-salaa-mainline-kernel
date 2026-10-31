# Realme 7 SALAA mainline kernel

Experimental mainline bring-up for the Realme 7 (`RMX2151`, codename `salaa`, MediaTek MT6785). This branch is based on upstream Linux **v7.3.0** (`c03c1a14507d`). It carries an initial Salaa board DTS plus MT6785 SoC support adapted from the Realme 6/Nemo work. This is an early, incomplete port.

## Current state

- Added the MT6785 SoC DTS, clock-controller drivers, pinctrl driver, DT binding headers and Kconfig/Makefile wiring.
- Added `arch/arm64/boot/dts/mediatek/mt6785-realme-salaa.dts` and its DTB Makefile entry. The board DTS defines initial identity, UART boot console, memory/SCP reservations and selected CPU/PMIC connections; it is not complete.
- Saved the current ARM64 config under `salaa/config/` and added a build/package script, a minimal BusyBox initramfs, Android DT-table tooling, and decompiled stock F.11 DTB/DTBO DTS references under `salaa/`.
- A SALAA DTB exists from the previous workspace build. No kernel `Image` or packaged boot image is present in this snapshot. On-device boot has not been verified.

## Build and temporary boot

On Ubuntu with AArch64 GCC, `dtc`, `cpio`, Python 3 and `gzip` installed:

```sh
JOBS=2 ./salaa/tools/package_salaa_boot.sh
fastboot boot salaa/output/salaa-linux-7.3-boot.img
```

The script builds the kernel and SALAA DTB, creates the Android DT table and serial-console initramfs, then packages an Android boot image v2. The initramfs starts BusyBox on `ttyS0` at 921600 baud; it contains no Android userspace. Boot only with `fastboot boot` while bring-up is in progress.

## Remaining work

1. Forward-port the changes from v7.3.0 to stable v7.3.1, then build from a clean checkout. See the [kernel release archive](https://www.kernel.org/pub/linux/kernel/v7.x/).
2. Build and fix the MT6785 clock/pinctrl support and validate bindings; the added SoC support has not yet been confirmed by a complete kernel build.
3. Review the saved config and complete the DTS from the F.11 references, including pinctrl, clocks, regulators, storage and peripheral wiring.
4. Produce and inspect the kernel image and boot package, including boot-header offsets and the 32 MiB partition-size limit.
5. Boot on an RMX2151 and capture UART logs; verify bootloader acceptance, kernel startup, DTB selection and the initramfs shell.
6. Port and validate storage/rootfs, display, touch, audio, Wi-Fi/Bluetooth, camera, sensors, modem, fingerprint, charging and suspend/resume support.

The stock DTS/DTB files are references only. The current boot image is a serial shell prototype, not a daily-use kernel.

## References

- [Upstream Linux v7.3.0](https://github.com/torvalds/linux/tree/v7.3)
- [Realme 6/Nemo MT6785 port](https://github.com/Hari-Pi/realme6-pmos-port)
- [SALAA Android device tree](https://github.com/elohim-etz/android_device_realme_RM6785)
- [SALAA Android kernel](https://github.com/elohim-etz/android_kernel_realme_mt6785)
- [AOSP mkbootimg](https://android.googlesource.com/platform/system/tools/mkbootimg/)
