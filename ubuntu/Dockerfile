ARG UBUNTU_VERSION=22.04
ARG PYTHON_VERSION=3.12.2
ARG BAZEL_VERSION=6.5.0
ARG TENSORFLOW_VERSION=2.16.1
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

FROM base AS get-cuda
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
RUN wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda-repo-ubuntu2204-12-4-local_12.4.0-550.54.14-1_amd64.deb

FROM base AS get-tensorrt
RUN wget https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/secure/8.6.1/local_repos/nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-12.0_1.0-1_amd64.deb

FROM base AS get-clang
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}.tar.xz
RUN tar -xvf clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}.tar.xz
RUN cp -r clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}/* /usr

FROM base AS get-tf
ARG TENSORFLOW_VERSION
RUN git clone https://github.com/tensorflow/tensorflow.git
WORKDIR /tensorflow
RUN git checkout v${TENSORFLOW_VERSION}

FROM base AS get-python
ARG PYTHON_VERSION=3.12.2
RUN curl -sL https://python.org/ftp/python/$PYTHON_VERSION/Python-${PYTHON_VERSION}.tar.xz -o - | tar -xvJ

FROM base as build-python
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

FROM base as install-cuda-python
COPY --from=build-python /Python-3.12.2 /Python-3.12.2
WORKDIR /Python-3.12.2
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends python3-certifi  libc6  xz-utils build-essential  gdb lcov pkg-config libbz2-dev libffi-dev uuid-dev libssl-dev zlib1g-dev libncurses5-dev libreadline6-dev libgdbm-dev libgdbm-compat-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install make libreadline6-dev libsqlite3-dev tk-dev -y
RUN make altinstall
WORKDIR /
COPY --from=get-cuda cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
COPY --from=get-cuda cuda-repo-ubuntu2204-12-4-local_12.4.0-550.54.14-1_amd64.deb .
COPY --from=get-tensorrt nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-12.0_1.0-1_amd64.deb .
COPY --from=get-cudnn cudnn-local-repo-ubuntu2204-9.0.0_1.0-1_amd64.deb .
RUN dpkg -i nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-12.0_1.0-1_amd64.deb
RUN dpkg -i cudnn-local-repo-ubuntu2204-9.0.0_1.0-1_amd64.deb
RUN dpkg -i cuda-repo-ubuntu2204-12-4-local_12.4.0-550.54.14-1_amd64.deb
RUN cp /var/cuda-repo-ubuntu2204-12-4-local/cuda-*-keyring.gpg /usr/share/keyrings/
RUN cp /var/nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-12.0/nv-tensorrt-local-42B2FC56-keyring.gpg /usr/share/keyrings/
RUN cp /var/cudnn-local-repo-ubuntu2204-9.0.0/cudnn-local-960825AE-keyring.gpg /usr/share/keyrings/
RUN echo 'deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /' >> /etc/apt/sources.list.d/cuda-ubuntu2204-x86_64.list
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
RUN dpkg -i cuda-keyring_1.1-1_all.deb
RUN apt-get update && apt-get -y install cuda-toolkit-12-4

ARG BAZEL_VERSION
RUN apt-get install -y libnvinfer-dev libnvinfer-plugin-dev patchelf
RUN apt-get install -y python3-pip
RUN python3.12 -m venv /.venv
RUN python3 -m pip install -U pip setuptools wheel packaging
RUN python3 -m pip install -U pip numpy wheel packaging requests opt_einsum
RUN python3 -m pip install -U keras_preprocessing --no-deps
RUN /.venv/bin/python3.12 -m pip install -U pip setuptools wheel packaging
RUN /.venv/bin/python3.12 -m pip install -U pip numpy wheel packaging requests opt_einsum
RUN /.venv/bin/python3.12 -m pip install -U keras_preprocessing --no-deps
RUN python3.12 -m pip install -U pip setuptools wheel packaging
RUN python3.12 -m pip install -U pip numpy wheel packaging requests opt_einsum
RUN python3.12 -m pip install -U keras_preprocessing --no-deps
COPY --from=get-tf /tensorflow /tensorflow
RUN echo 'deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-17 main' >> /etc/apt/sources.list.d/archive_uri-http_apt_llvm_org_jammy_-jammy.list
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
RUN apt-get update
RUN apt-get install -y clang-17 llvm-17
FROM install-cuda-python as tf-env

ENV TF_NEED_ROCM=0
ENV TF_ENABLE_XLA=1
ENV TF_NEED_CUDA=1
ENV TF_NEED_TENSORRT=1
ENV TF_CUDA_CLANG=1
ENV TF_NEED_CLANG=1
ENV TF_CUDA_PATHS=/usr/local/cuda-12.4,/usr/include,/usr/lib/x86_64-linux-gnu/,/usr/include/x86_64-linux-gnu/
ENV TF_CUDA_COMPUTE_CAPABILITIES=7.5
ENV TF_CUDA_VERSION=12
ENV TF_CUDNN_VERSION=8
ENV TF_TENSORRT_VERSION=8
ENV TF_SET_ANDROID_WORKSPACE=0
ENV CC_OPT_FLAGS="-march=native"
ENV CLANG_CUDA_COMPILER_PATH=/usr/bin/clang-17
COPY --from=get-bazel /bazel-${BAZEL_VERSION}-linux-x86_64 /usr/local/bin/bazel

FROM tf-env as build-tf
ENV TF_PYTHON_VERSION=3.12
ENV PYTHON_BIN_PATH=/usr/local/bin/python3.12
ENV PYTHON_LIB_PATH=/usr/lib/python3.12/dist-packages
WORKDIR /tensorflow

RUN ./configure
RUN echo "build --copt=-Wno-error=unused-command-line-argument" >> .tf_configure.bazelrc

RUN bazel build //tensorflow/tools/pip_package:build_pip_package
RUN mkdir /tf_output
RUN bazel-bin/tensorflow/tools/pip_package/build_pip_package /tf_output

ADD main.py /
FROM build-tf as cleanup
WORKDIR /
#RUN rm /root/.cache cuda-keyring_1.1-1_all.deb cuda-repo-ubuntu2204-12-4-local_12.4.0-550.54.14-1_amd64.deb  cudnn-local-repo-ubuntu2204-9.0.0_1.0-1_amd64.deb  nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-12.0_1.0-1_amd64.deb
