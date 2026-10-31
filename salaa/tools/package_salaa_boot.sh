#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KERNEL="$ROOT"
OUT="$ROOT/salaa/output"
BUILD="$OUT/build"
CONFIG="$ROOT/salaa/config/realme7-salaa-linux-7.3.0.config"
JOBS="${JOBS:-2}"

mkdir -p "$BUILD" "$OUT"
mkdir -p "$ROOT/salaa/initramfs/root"/{bin,dev,proc,sys,tmp,run,usr/bin,usr/share}
if [[ ! -s "$BUILD/.config" ]]; then
	cp "$CONFIG" "$BUILD/.config"
fi

make -C "$KERNEL" -j"$JOBS" O="$BUILD" ARCH=arm64 \
	CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
make -C "$KERNEL" -j"$JOBS" O="$BUILD" ARCH=arm64 \
	CROSS_COMPILE=aarch64-linux-gnu- Image
make -C "$KERNEL" -j"$JOBS" O="$BUILD" ARCH=arm64 \
	CROSS_COMPILE=aarch64-linux-gnu- mediatek/mt6785-realme-salaa.dtb

gzip -n -c "$BUILD/arch/arm64/boot/Image" > "$OUT/Image.gz"
python3 "$ROOT/salaa/tools/mkdtb_table.py" \
	"$BUILD/arch/arm64/boot/dts/mediatek/mt6785-realme-salaa.dtb" \
	"$OUT/salaa-dtb-table.img"

(
	cd "$ROOT/salaa/initramfs/root"
	find . -print0 |
		cpio --null --create --format=newc --owner=0:0 2>/dev/null |
		gzip -n -9 > "$OUT/salaa-initramfs.cpio.gz"
)

python3 "$ROOT/salaa/tools/aosp-mkbootimg/mkbootimg.py" \
	--header_version 2 \
	--pagesize 2048 \
	--base 0x40078000 \
	--kernel_offset 0x00008000 \
	--ramdisk_offset 0x07c08000 \
	--tags_offset 0x0bc08000 \
	--dtb_offset 0x0bc08000 \
	--kernel "$OUT/Image.gz" \
	--ramdisk "$OUT/salaa-initramfs.cpio.gz" \
	--dtb "$OUT/salaa-dtb-table.img" \
	--cmdline 'console=ttyS0,921600n8 earlycon=uart8250,mmio32,0x11002000 root=/dev/ram0 rw rdinit=/init' \
	--os_version 12.0.0 \
	--os_patch_level 2022-11 \
	--output "$OUT/salaa-linux-7.3-boot.img"

IMAGE_SIZE="$(stat -c '%s' "$OUT/salaa-linux-7.3-boot.img")"
BOOT_PARTITION_SIZE=33554432
if (( IMAGE_SIZE > BOOT_PARTITION_SIZE )); then
	printf 'Boot image is %s bytes; SALAA boot partition is %s bytes\n' \
		"$IMAGE_SIZE" "$BOOT_PARTITION_SIZE" >&2
	exit 1
fi

printf 'Packaged %s\n' "$OUT/salaa-linux-7.3-boot.img"
