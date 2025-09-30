# 使用專案原始指定的 devel 映像檔作為我們唯一的基礎
ARG NVIDIA_IMAGE=nvidia/cuda:12.2.0-devel-ubuntu20.04
FROM ${NVIDIA_IMAGE}

# 設定非互動式前端，並安裝所有依賴：git, cmake, python
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i "s/archive.ubuntu/tw.archive.ubuntu/g" /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    python3.9 \
    python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 複製整個專案
WORKDIR /
COPY . /k8s-vgpu
WORKDIR /k8s-vgpu

# 初始化 submodule 並編譯 libvgpu.so
RUN git config --global --add safe.directory /k8s-vgpu
RUN git submodule update --init --recursive
WORKDIR /k8s-vgpu/libvgpu
RUN bash ./build.sh
WORKDIR /k8s-vgpu

# 編譯 Go 元件
ARG GOLANG_IMAGE=golang:1.24.6-bullseye
COPY --from=${GOLANG_IMAGE} /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"
ARG GOPROXY
RUN go env -w GOPROXY=${GOPROXY:-"https://goproxy.cn,direct"}
ARG VERSION
RUN make all VERSION=${VERSION}

# 安裝 Python 依賴
RUN python3.9 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 最終設定
COPY --from=0 /k8s-vgpu/libvgpu/build/libvgpu.so /k8s-vgpu/lib/nvidia/libvgpu.so."${VERSION}"
ENV PATH="/k8s-vgpu/bin:${PATH}"
ENTRYPOINT ["/k8s-vgpu/docker/entrypoint.sh"]
