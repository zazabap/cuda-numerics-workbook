# CUDA numerics workbook

Exercises in C++ and CUDA for numerical computing, worked from the ground up:
language fundamentals first, then GPU kernels, then one small project. Started
in November 2026 and filled in week by week, so most of what is listed below is
still to come.

Each kernel is meant to arrive with four things:

- a CPU reference implementation, written before the GPU version;
- correctness tests against that reference, with explicit tolerances;
- a benchmark that one recorded command reproduces;
- a short report: what was predicted, what was measured, and the explanation.

## Contents

| Path            | Contents                                                      |
| --------------- | ------------------------------------------------------------- |
| `cpp/`          | C++ fundamentals: lifetime, ownership, containers             |
| `algorithms/`   | Data structures and algorithm practice                        |
| `cuda/`         | Standalone CUDA kernels with their host code                  |
| `tests/`        | Correctness checks and reference implementations              |
| `benchmarks/`   | Timing drivers                                                |
| `reports/`      | Measurements, profiler findings, and experiments that failed  |
| `projects/dct/` | A DCT built on cuFFT, compared with `jax.scipy.fft.dct`       |
| `notes/`        | Short explanations and derivations                            |
| `tools/`        | Toolchain setup, environment record, and the toolchain check  |

A directory appears when its first exercise does. So far there are `tools/` and
`reports/`.

## Kernels

| # | Kernel                       | What it exercises                                              | Status  |
| - | ---------------------------- | -------------------------------------------------------------- | ------- |
| 1 | Elementwise transform        | Indexing, bounds, launch and error checks                      | planned |
| 2 | Sum and maximum reduction    | Synchronization, and a sequence of optimizations each explained | planned |
| 3 | Matrix transpose             | Naive against shared-memory tiles; memory access patterns      | planned |
| 4 | Matrix multiplication        | Naive against tiled, for sizes that are not multiples of a tile | planned |
| 5 | Softmax                      | Stable max and sum reductions, checked against a reference     | planned |
| 6 | DCT pre- and post-processing | Reordering and phase factors around a cuFFT call               | planned |

## Build

```sh
tools/setup-toolchain.sh        # once: nvcc, cuFFT, cuBLAS, CMake, Ninja into .toolchain/
source tools/env.sh             # in every new shell
cmake -S . -B build -G Ninja
cmake --build build
ctest --test-dir build --output-on-failure
```

Without an NVIDIA GPU, skip the first two lines and use your own CMake: the
build then configures the CPU-only targets.

## Toolchain

The CUDA compiler and libraries come from NVIDIA's pip wheels and are installed
into `.toolchain/` inside the repository. Nothing needs root and nothing touches
the system. The versions are pinned in `tools/toolchain-requirements.txt`.

One rule matters: the compiler must not be newer than the CUDA version the
driver supports, which is the `CUDA Version` field printed by `nvidia-smi`. On
the machine below the driver reports 13.2. nvcc 13.5 builds without complaint
there, and library calls work, but every kernel compiled with it fails at launch
with `the provided PTX was compiled with an unsupported toolchain`. nvcc 13.2
runs.

`tools/toolchain_check.cu` catches this. It launches one kernel compiled on the
spot, then creates a cuFFT plan and a cuBLAS handle. It runs as the CTest test
`toolchain_check`:

```
device   NVIDIA GeForce RTX 5070, sm_120, 11.5 GiB
driver   supports CUDA 13.2
runtime  CUDA 13.2
compiler CUDA 13.2
ok    kernel compiled here ran on the device
ok    cuFFT
ok    cuBLAS
```

Verified with driver 595.84, nvcc 13.2.86, g++ 14.2 and CMake 4.4.5 on Debian 13.
`tools/record-env.sh` prints the same details for whatever machine it runs on.

The wheels do not include Nsight Systems, Nsight Compute or Compute Sanitizer.
Those need a separate install.

## Reports

`reports/TEMPLATE.md` is the form for an experiment: hypothesis, prediction,
revision, environment, workload, correctness, timing scope, sampling, results
and interpretation. The prediction is written before the run.

## Licence

MIT. See `LICENSE`.
