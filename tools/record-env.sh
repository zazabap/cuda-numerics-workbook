#!/usr/bin/env bash
# Print the environment a measurement was taken in, for pasting into a report.
# Run it after `source tools/env.sh` so that it sees the same nvcc and cmake as
# the build.
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
first_line() { "$@" 2>/dev/null | head -n 1; }

echo "date      $(date -u +%Y-%m-%dT%H:%MZ)"
echo "revision  $(git -C "$root" describe --always --dirty 2>/dev/null || echo unknown)"
echo "os        $(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-unknown}"), kernel $(uname -r)"
echo "cpu       $(grep -m 1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//'), $(nproc) threads"
echo "memory    $(awk '/MemTotal/ { printf "%.0f GiB", $2 / 1048576 }' /proc/meminfo)"
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "gpu       $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -n 1)"
    echo "driver    $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)," \
         "supports CUDA $(nvidia-smi | grep -o 'CUDA Version: [0-9.]*' | cut -d' ' -f3)"
else
    echo "gpu       none found (no nvidia-smi)"
fi
echo "nvcc      $(nvcc --version 2>/dev/null | grep release || echo 'not on PATH')"
echo "g++       $(first_line g++ --version)"
echo "cmake     $(first_line cmake --version)"
