if(CMAKE_CUDA_COMPILER)
  add_executable(toolchain_check toolchain_check.cu)
  target_link_libraries(toolchain_check PRIVATE CUDA::cufft CUDA::cublas)

  add_test(NAME toolchain_check COMMAND toolchain_check)
endif()
