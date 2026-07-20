#!/bin/sh
set -eu

mem_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
swap_mb=$(( mem_kb / 1024 / 2 ))
[ "$swap_mb" -gt 16384 ] && swap_mb=16384
[ "$swap_mb" -lt 1024 ] && swap_mb=1024

btrfs filesystem mkswapfile --size "${swap_mb}m" /var/swapfile
