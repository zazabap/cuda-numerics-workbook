// Checks that the compiler, the driver and the libraries agree with each other.
//
// Listing the device is not enough. A compiler newer than the driver supports
// still builds, and library calls still work, because the libraries carry
// their own prebuilt kernels. Only launching a kernel compiled here shows the
// mismatch. So this launches one, on a single thread, and reads the answer back.

#include <cstdio>

#include <cublas_v2.h>
#include <cuda_runtime.h>
#include <cufft.h>

__global__ void probe(int* out) { *out = 42; }

static bool ok(cudaError_t status, const char* what) {
    if (status == cudaSuccess) return true;
    std::printf("FAIL  %s: %s\n", what, cudaGetErrorString(status));
    if (status == cudaErrorUnsupportedPtxVersion) {
        std::printf("      nvcc is newer than the driver supports. Compare `nvcc --version`\n"
                    "      with the CUDA version printed by `nvidia-smi`, and lower the\n"
                    "      compiler pins in tools/toolchain-requirements.txt.\n");
    }
    return false;
}

int main() {
    int driver = 0;
    int runtime = 0;
    cudaDeviceProp device{};
    if (!ok(cudaDriverGetVersion(&driver), "driver version")) return 1;
    if (!ok(cudaRuntimeGetVersion(&runtime), "runtime version")) return 1;
    if (!ok(cudaGetDeviceProperties(&device, 0), "device properties")) return 1;

    std::printf("device   %s, sm_%d%d, %.1f GiB\n", device.name, device.major, device.minor,
                static_cast<double>(device.totalGlobalMem) / (1024.0 * 1024.0 * 1024.0));
    std::printf("driver   supports CUDA %d.%d\n", driver / 1000, driver % 1000 / 10);
    std::printf("runtime  CUDA %d.%d\n", runtime / 1000, runtime % 1000 / 10);
    std::printf("compiler CUDA %d.%d\n", __CUDACC_VER_MAJOR__, __CUDACC_VER_MINOR__);

    int* answer = nullptr;
    if (!ok(cudaMalloc(&answer, sizeof(int)), "cudaMalloc")) return 1;
    probe<<<1, 1>>>(answer);
    if (!ok(cudaGetLastError(), "kernel launch")) return 1;
    if (!ok(cudaDeviceSynchronize(), "kernel execution")) return 1;
    int host = 0;
    if (!ok(cudaMemcpy(&host, answer, sizeof(int), cudaMemcpyDeviceToHost), "cudaMemcpy")) return 1;
    cudaFree(answer);
    if (host != 42) {
        std::printf("FAIL  kernel wrote %d, expected 42\n", host);
        return 1;
    }
    std::printf("ok    kernel compiled here ran on the device\n");

    cufftHandle plan;
    if (cufftPlan1d(&plan, 1024, CUFFT_R2C, 1) != CUFFT_SUCCESS) {
        std::printf("FAIL  cuFFT could not create a plan\n");
        return 1;
    }
    cufftDestroy(plan);
    std::printf("ok    cuFFT\n");

    cublasHandle_t blas;
    if (cublasCreate(&blas) != CUBLAS_STATUS_SUCCESS) {
        std::printf("FAIL  cuBLAS could not create a handle\n");
        return 1;
    }
    cublasDestroy(blas);
    std::printf("ok    cuBLAS\n");
    return 0;
}
