FROM bitnami/git:latest as base

FROM base as get-tf
RUN git clone https://github.com/tensorflow/tensorflow.git
WORKDIR /tensorflow
RUN git checkout v2.16.1

FROM tensorflow/build:2.17-python3.12 as configure-tf
ENV TF_PYTHON_VERSION=3.12
ENV PYTHON_BIN_PATH=/usr/bin/python3
ENV TF_SET_ANDROID_WORKSPACE=0
ENV TF_NEED_ROCM=0
ENV TF_ENABLE_XLA=1
ENV TF_NEED_CUDA=1
ENV TF_NEED_TENSORRT=1
ENV TF_CUDA_CLANG=1
ENV TF_NEED_CLANG=1
ENV TF_CUDA_COMPUTE_CAPABILITIES=7.5
ENV CLANG_CUDA_COMPILER_PATH=/usr/lib/llvm-17/bin/clang
ENV PYTHON_LIB_PATH /usr/local/lib/python3.12/dist-packages
ENV CC_OPT_FLAGS="-march=native"
COPY --from=get-tf /tensorflow/ /tensorflow/
WORKDIR /tensorflow
RUN ./configure
RUN echo "build --copt=-Wno-error=unused-command-line-argument" >> .tf_configure.bazelrc

FROM configure-tf as build-tf
RUN bazel build //tensorflow/tools/pip_package:build_pip_package --config=opt --config=noaws --config=nogcp --config=nohdfs --config=avx_linux --config=mkl