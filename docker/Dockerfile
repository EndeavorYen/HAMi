# --- 全域宣告，使用專案原始指定的版本 ---
ARG GOLANG_IMAGE=golang:1.24.6-bullseye
ARG NVIDIA_IMAGE=nvidia/cuda:12.2.0-devel-ubuntu20.04

# --- Stage 1: 'gobuild' - 編譯 Go 元件 ---
FROM ${GOLANG_IMAGE} AS gobuild
ARG GOPROXY
ARG VERSION
ADD . /k8s-vgpu
RUN cd /k8s-vgpu && make all VERSION=$VERSION
# RUN git submodule update --init --recursive
RUN go install github.com/NVIDIA/mig-parted/cmd/nvidia-mig-parted@v0.10.0

# --- Stage 2: 'vgpubuild' - 在指定的 CUDA 環境中編譯 C++ 核心庫 ---
FROM ${NVIDIA_IMAGE} AS vgpubuild
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i "s/archive.ubuntu/tw.archive.ubuntu/g" /etc/apt/sources.list
RUN apt-get update && apt-get install -y cmake
COPY ./libvgpu /libvgpu
WORKDIR /libvgpu
RUN bash ./build.sh

# --- Final Stage: 以對應的 runtime 映像檔為基礎，組裝所有產物 ---
FROM nvidia/cuda:12.2.0-runtime-ubuntu20.04
WORKDIR /

# 安裝 Python 執行環境，並處理所有細節
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i "s/archive.ubuntu/tw.archive.ubuntu/g" /etc/apt/sources.list
RUN apt-get update && apt-get install -y python3.9 python3-pip && \
    python3.9 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 複製所有產物
ARG VERSION
COPY ./LICENSE /k8s-vgpu/LICENSE
COPY --from=gobuild /k8s-vgpu/bin /k8s-vgpu/bin
COPY --from=gobuild /go/bin/nvidia-mig-parted /k8s-vgpu/bin/
COPY ./docker/entrypoint.sh /k8s-vgpu/bin/entrypoint.sh
COPY ./lib /k8s-vgpu/lib
COPY --from=vgpubuild /libvgpu/build/libvgpu.so /k8s-vgpu/lib/nvidia/libvgpu.so."${VERSION}"
COPY ./docker/vgpu-init.sh /k8s-vgpu/bin/vgpu-init.sh

# 設定所有必要的環境變數
ENV NVIDIA_DISABLE_REQUIRE="true"
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV PATH="/k8s-vgpu/bin:${PATH}"

LABEL version="$VERSION"
LABEL maintainer="info@dynamia.ai"

ARG DEST_DIR
ENTRYPOINT ["/bin/bash", "-c", "entrypoint.sh  $DEST_DIR"]