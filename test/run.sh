#!/bin/bash
set -e
cd "$(dirname "$0")"
bash make-disk.sh

qemu-system-x86_64 -M q35 -m 2G -debugcon stdio -cdrom test.iso -boot d