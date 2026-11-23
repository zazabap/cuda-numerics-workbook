cmake_minimum_required(VERSION 3.24)
project(cuda_numerics_workbook LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

# Warnings for host C++ only; nvcc takes its own set of flags.
add_compile_options($<$<COMPILE_LANGUAGE:CXX>:-Wall$<SEMICOLON>-Wextra$<SEMICOLON>-Wpedantic>)

# CUDA is optional, so the CPU exercises still build on a machine without a GPU.
# nvcc is found through the CUDACXX variable that tools/env.sh sets.
include(CheckLanguage)
check_language(CUDA)
if(CMAKE_CUDA_COMPILER)
  enable_language(CUDA)
  set(CMAKE_CUDA_STANDARD 17)
  set(CMAKE_CUDA_STANDARD_REQUIRED ON)

  # Provides the CUDA::cufft, CUDA::cublas, ... targets to every directory.
  find_package(CUDAToolkit REQUIRED)

  # CMake leaves the toolkit's library directory out of the run path, since a
  # system-wide install is known to the dynamic loader. This one is private to
  # the repository, so name it, or the programs fail to find libcufft.so at start.
  list(APPEND CMAKE_BUILD_RPATH "${CUDAToolkit_LIBRARY_DIR}")
else()
  message(STATUS "No CUDA compiler found: configuring the CPU-only targets. "
                 "Run tools/setup-toolchain.sh, then source tools/env.sh.")
endif()

enable_testing()

add_subdirectory(tools)

# Each exercise directory joins the build once it has a CMakeLists.txt.
foreach(dir cpp algorithms cuda tests benchmarks projects/dct)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dir}/CMakeLists.txt")
    add_subdirectory(${dir})
  endif()
endforeach()
