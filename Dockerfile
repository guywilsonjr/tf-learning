ARG UBUNTU_VERSION=22.04
ARG PYTHON_VERSION=3.12.2
ARG BAZEL_VERSION=6.5.0
ARG TENSORFLOW_VERSION=2.16.0-rc0
ARG CUDA_VERSION=12.3.2
ARG CLANG_VERSION=17.0.2

FROM ubuntu:$UBUNTU_VERSION AS base
RUN apt-get update && apt-get install -yq wget git curl xz-utils mlocate && updatedb

FROM base AS get-bazel
ARG BAZEL_VERSION
RUN wget https://releases.bazel.build/$BAZEL_VERSION/release/bazel-${BAZEL_VERSION}-linux-x86_64
RUN chmod +x bazel-${BAZEL_VERSION}-linux-x86_64

FROM base AS get-cudnn
RUN wget https://developer.download.nvidia.com/compute/cudnn/9.0.0/local_installers/cudnn-local-repo-ubuntu2204-9.0.0_1.0-1_amd64.deb

FROM base AS get-clang
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}.tar.xz
RUN tar -xvf clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}.tar.xz
RUN cp -r clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}/* /usr

FROM base AS get-tf
RUN git clone https://github.com/tensorflow/tensorflow.git
WORKDIR /tensorflow
RUN git checkout v2.16.0-rc0

FROM base AS get-python
ARG PYTHON_VERSION=3.12.2
RUN curl -sL https://python.org/ftp/python/$PYTHON_VERSION/Python-${PYTHON_VERSION}.tar.xz -o - | tar -xvJ

FROM nvidia/cuda:12.3.2-devel-ubuntu22.04 as build
RUN apt-get update && apt-get upgrade -y
RUN apt-get update && apt-get install -yq curl wget lsb-release software-properties-common gpg vim mlocate git
RUN updatedb
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends libmysqlclient-dev python3-certifi libsqlite3-dev libclang-rt-18-dev libc6 expat clang-18 llvm-18 xz-utils build-essential tk-dev gdb lcov pkg-config libbz2-dev libffi-dev liblzma-dev lzma lzma-dev uuid-dev libssl-dev zlib1g-dev libncurses5-dev libreadline6-dev libgdbm-dev libgdbm-compat-dev
ARG PYTHON_VERSION=3.12.2
ARG PYTHON_SRC_NAME=Python-${PYTHON_VERSION}
ENV LLVM_PROFDATA=/usr/bin/llvm-profdata-18
ENV LLVM_AR=/usr/bin/llvm-ar-18
ENV CC='/usr/bin/clang-18 -Ofast'
ENV CXX='/usr/bin/clang-18++ -Ofast'
ENV TZ="America/New_York"
ENV DEBIAN_FRONTEND="noninteractive"
COPY --from=get-python /Python-3.12.2 /Python-3.12.2
WORKDIR /Python-3.12.2
RUN ./configure --with-ensurepip=upgrade --with-lto=full --with-computed-gotos --disable-test-modules --enable-loadable-sqlite-extensions --enable-optimizations --without-doc-strings --without-pymalloc --with-strict-overflow
RUN make -j 8
RUN make altinstall

FROM build as build-tf
ARG BAZEL_VERSION
RUN apt-get install -y libnvinfer-dev libnvinfer-plugin-dev
RUN apt-get install -y python3-pip
RUN python3.12 -m venv /.venv
RUN python3 -m pip install -U pip setuptools wheel packaging
RUN python3 -m pip install -U pip numpy wheel packaging requests opt_einsum
RUN python3 -m pip install -U keras_preprocessing --no-deps
RUN /.venv/bin/python3.12 -m pip install -U pip setuptools wheel packaging
RUN /.venv/bin/python3.12 -m pip install -U pip numpy wheel packaging requests opt_einsum
RUN /.venv/bin/python3.12 -m pip install -U keras_preprocessing --no-deps

COPY --from=get-tf /tensorflow /tensorflow
RUN echo 'deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-17 main' >> /etc/apt/sources.list.d/archive_uri-http_apt_llvm_org_jammy_-jammy.list
RUN apt-get update
RUN apt-get install -y clang-17 llvm-17
WORKDIR /tensorflow

ENV TF_NEED_ROCM=0
#ENV TF_ENABLE_XLA=1
ENV TF_NEED_CUDA=1
ENV TF_NEED_TENSORRT=1
ENV TF_CUDA_CLANG=0
ENV TF_NEED_CLANG=0
ENV TF_CUDA_PATHS=/usr/local/cuda-12.3,/usr/include,/usr/lib/x86_64-linux-gnu/,/usr/include/x86_64-linux-gnu/
#ENV PYTHON_BIN_PATH=/usr/bin/python3
ENV TF_CUDA_COMPUTE_CAPABILITIES=7.5
ENV TF_CUDA_VERSION=12
ENV TF_CUDNN_VERSION=8
ENV TF_TENSORRT_VERSION=8
ENV TF_SET_ANDROID_WORKSPACE=0
ENV TF_PYTHON_VERSION=3.12
ENV CC_OPT_FLAGS="-march=native"
#ENV CLANG_CUDA_COMPILER_PATH=/usr/bin/clang-17

ENV PYTHON_LIB_PATH=/usr/lib/python3/dist-packages

COPY --from=get-bazel /bazel-${BAZEL_VERSION}-linux-x86_64 /usr/local/bin/bazel

#RUN bazel build //tensorflow/tools/pip_package:build_pip_package
# bazel build
#RUN bazel build \
#   --config=opt \
#   --config=cuda_clang \
#   --config=avx_linux \
#   --config=cuda \
#   --config=mkl \
#   --config=tensorrt \
#   --config=monolithic \
#   //tensorflow/tools/pip_package:build_pip_package