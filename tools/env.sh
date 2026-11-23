# Source this file (do not execute it) to put the toolchain on PATH:
#
#     source tools/env.sh
#
# It sets CUDACXX, which is how CMake finds nvcc.
_workbook_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

if [ ! -x "$_workbook_root/.toolchain/cuda/bin/nvcc" ]; then
    echo "No toolchain yet: run tools/setup-toolchain.sh first." >&2
else
    export CUDA_HOME="$_workbook_root/.toolchain/cuda"
    export CUDACXX="$CUDA_HOME/bin/nvcc"
    case ":$PATH:" in
        *":$CUDA_HOME/bin:"*) ;;
        *) PATH="$_workbook_root/.toolchain/bin:$CUDA_HOME/bin:$PATH" ;;
    esac
    export PATH
fi
unset _workbook_root
