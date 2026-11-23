#!/usr/bin/env bash
# Install a private CUDA toolchain into .toolchain/ from NVIDIA's pip wheels.
#
# Needs no root: only an NVIDIA driver, a host C++ compiler, and either uv or
# python3 with venv. Safe to run again; it only adds what is missing.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
venv="$root/.toolchain"
reqs="$root/tools/toolchain-requirements.txt"

if command -v uv >/dev/null 2>&1; then
    [ -x "$venv/bin/python" ] || uv venv --quiet "$venv"
    uv pip install --quiet --python "$venv/bin/python" -r "$reqs"
else
    [ -x "$venv/bin/python" ] || python3 -m venv "$venv"
    "$venv/bin/pip" install --quiet -r "$reqs"
fi

# Every wheel unpacks into the same tree, laid out like a toolkit install:
# bin/ (nvcc), include/, lib/, nvvm/.
cuda="$(echo "$venv"/lib/python*/site-packages/nvidia/cu*)"
if [ ! -x "$cuda/bin/nvcc" ]; then
    echo "error: nvcc not found under $cuda" >&2
    exit 1
fi

# The wheels ship only versioned shared libraries (libcufft.so.12). The linker
# and CMake look for the unversioned name, so add it.
for lib in "$cuda"/lib/lib*.so.*; do
    link="${lib%%.so.*}.so"
    [ -e "$link" ] || ln -s "$(basename "$lib")" "$link"
done

ln -sfn "$cuda" "$venv/cuda"

echo "Toolchain ready: $("$cuda/bin/nvcc" --version | grep release)"
echo "Next: source tools/env.sh"
