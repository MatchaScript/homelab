#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
[ -f /etc/sysconfig/update-m1n1 ] && . /etc/sysconfig/update-m1n1

: "${M1N1:=/usr/lib/asahi-boot/m1n1.bin}"
: "${U_BOOT:=/usr/lib/asahi-boot/u-boot-nodtb.bin}"

if [ -z "${U_BOOT:-}" ] && [ -n "${UBOOT:-}" ]; then U_BOOT="$UBOOT"; fi

: "${CONFIG:=/etc/m1n1.conf}"
OUT="/usr/share/m1n1/universal-boot.bin"

TARGETS=(
    "t8103-j274"
)

if [ -z "${KVER:-}" ]; then
    # shellcheck disable=SC2012
    KVER=$(ls /lib/modules/ | sort -V | tail -n1)
fi

if [ -d "/lib/modules/${KVER}/dtb/apple" ]; then
    DTB_DIR="/lib/modules/${KVER}/dtb/apple"
elif [ -d "/lib/modules/${KVER}/dtbs/apple" ]; then
    DTB_DIR="/lib/modules/${KVER}/dtbs/apple"
else
    DTB_DIR="/lib/modules/${KVER}/dtb"
fi

if [ ! -d "$DTB_DIR" ]; then
    echo "ERROR: DTB directory not found at $DTB_DIR"
    exit 1
fi


if [ ! -f "$M1N1" ]; then
    echo "ERROR: m1n1 binary not found at $M1N1"
    exit 1
fi
if [ ! -f "$U_BOOT" ]; then
    echo "ERROR: U-Boot binary not found at $U_BOOT"
    exit 1
fi


WORK_DIR=$(mktemp -d)

trap 'rm -rf "$WORK_DIR"' EXIT

M1N1_CONFIG_TMP="$WORK_DIR/m1n1.conf"
OUT_TMP="$WORK_DIR/boot.bin.tmp"

: > "$M1N1_CONFIG_TMP"

if [ -f "$CONFIG" ]; then
    echo "Reading m1n1 config from $CONFIG:"
    while read -r line || [ -n "$line" ]; do
        case "$line" in
            "") ;;
            \#*) ;;
            chosen.*=*|display=*|mitigations=*)
                echo "$line" >> "$M1N1_CONFIG_TMP"
                echo "  Option: $line"
                ;;
            *)
                echo "  Ignoring unknown option: $line"
                ;;
        esac
    done < "$CONFIG"
fi

echo "Building custom m1n1..."
echo "  Kernel: $KVER"
echo "  DTB Dir: $DTB_DIR"


cat "$M1N1" > "$OUT_TMP"


FOUND_COUNT=0
for TARGET in "${TARGETS[@]}"; do

    DTB_FILE=$(find "$DTB_DIR" -name "*${TARGET}*.dtb" 2>/dev/null | head -n1)

    if [ -n "$DTB_FILE" ] && [ -f "$DTB_FILE" ]; then
        echo "  Adding DTB: $(basename "$DTB_FILE") (Target: $TARGET)"
        cat "$DTB_FILE" >> "$OUT_TMP"
        FOUND_COUNT=$((FOUND_COUNT + 1))
    else
        echo "  WARNING: DTB matching '$TARGET' not found in $DTB_DIR"
    fi
done

if [ "$FOUND_COUNT" -eq 0 ]; then
    echo "ERROR: No valid DTBs were found for the specified targets."
    exit 1
fi


gzip -cn9 "$U_BOOT" >> "$OUT_TMP"


cat "$M1N1_CONFIG_TMP" >> "$OUT_TMP"

mkdir -p "$(dirname "$OUT")"

mv "$OUT_TMP" "$OUT"
chmod 644 "$OUT"

OUT_HASH=$(sha256sum "$OUT" | awk '{print $1}')
printf '%s  %s\n' "$OUT_HASH" "$(basename "$OUT")" > "${OUT}.sha256"
chmod 644 "${OUT}.sha256"

echo "---------------------------------------------------"
echo "Success! Custom m1n1 binary created:"
echo "  Path:   $OUT"
echo "  Size:   $(du -h "$OUT" | cut -f1)"
echo "  SHA256: $OUT_HASH"
echo "---------------------------------------------------"
