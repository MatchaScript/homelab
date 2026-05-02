#!/bin/bash
set -euo pipefail

NEW_M1N1="/usr/share/m1n1/universal-boot.bin"
NEW_HASH_FILE="${NEW_M1N1}.sha256"
ESP_DIR="/boot/efi/m1n1"
ESP_M1N1="${ESP_DIR}/boot.bin"
ESP_BACKUP="${ESP_DIR}/boot.bin.old"

if [ ! -f "$NEW_M1N1" ] || [ ! -f "$NEW_HASH_FILE" ]; then
    echo "No m1n1 image payload at $NEW_M1N1 (.sha256). Skipping."
    exit 0
fi

if [ ! -d "$ESP_DIR" ]; then
    echo "ESP m1n1 directory $ESP_DIR not present. Skipping."
    exit 0
fi

EXPECTED_HASH=$(awk '{print $1}' "$NEW_HASH_FILE")
if [ -z "$EXPECTED_HASH" ]; then
    echo "ERROR: empty expected hash in $NEW_HASH_FILE"
    exit 1
fi

if [ -f "$ESP_M1N1" ]; then
    CURRENT_HASH=$(sha256sum "$ESP_M1N1" | awk '{print $1}')
else
    CURRENT_HASH=""
fi

if [ "$EXPECTED_HASH" = "$CURRENT_HASH" ]; then
    echo "m1n1 is up to date (sha256: ${EXPECTED_HASH:0:12}...)"
    exit 0
fi

echo "m1n1 hash mismatch:"
echo "  expected: ${EXPECTED_HASH}"
echo "  current:  ${CURRENT_HASH:-<missing>}"
echo "Updating ESP m1n1..."

if [ -f "$ESP_M1N1" ]; then
    cp -a "$ESP_M1N1" "$ESP_BACKUP"
fi
cp "$NEW_M1N1" "$ESP_M1N1"
sync

APPLIED_HASH=$(sha256sum "$ESP_M1N1" | awk '{print $1}')
if [ "$APPLIED_HASH" != "$EXPECTED_HASH" ]; then
    echo "ERROR: post-copy hash mismatch (got ${APPLIED_HASH}, expected ${EXPECTED_HASH})"
    exit 1
fi

echo "m1n1 updated. Rebooting to apply changes..."
systemctl reboot
exit 0
