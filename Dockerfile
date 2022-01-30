################ Pytorch Build Stage ################
# Pytorch build stage
FROM ubuntu:latest as pytorch_build

# Set stage environmental variables
ENV TZ=Australia/Brisbane 
ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_CAFFE2_OPS=OFF
ENV USE_FBGEMM=OFF
ENV USE_FAKELOWP=OFF
ENV BUILD_TEST=OFF
ENV USE_MKLDNN=OFF
ENV USE_NNPACK=ON
ENV USE_XNNPACK=ON
ENV USE_QNNPACK=ON
ENV MAX_JOBS=4
ENV USE_OPENCV=OFF
ENV USE_NCCL=OFF
ENV USE_SYSTEM_NCCL=OFF
ENV PATH=/usr/lib/ccache:$PATH

# Install dependancies
RUN apt update && apt install -y \
    python3-pip \
    python3-venv \
    git \
    libgl1-mesa-glx \
    libglib2.0-0 \
    ninja-build \
    cmake \
    libopenmpi-dev \
    libomp-dev ccache \
    libopenblas-dev \
    libblas-dev \
    libeigen3-dev 

# Download the pytorch repository
RUN git clone -b v1.10.0 --depth=1 --recursive https://github.com/pytorch/pytorch.git 
WORKDIR /pytorch

# Install python packages
RUN python3 -m pip install --no-cache --upgrade pip && \
    pip install setuptools==59.5.0 \
    pip install -r requirements.txt

# Build pytorch - torch-1.10.0a0+git36449ea-cp38-cp38-linux_aarch64.whl
RUN python3 setup.py clean && \
    python3 setup.py bdist_wheel 


################ Vision Build Stage ################
# Torchvision stage
FROM pytorch_build as torchvision_build

# Set stage environmental variables
ENV TZ=Australia/Brisbane 
ENV DEBIAN_FRONTEND=noninteractive

# Install dependancies
RUN apt update &&  apt install -y \
    libjpeg-dev \
    zlib1g-dev \
    libpython3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev

# Downlaod the repository
RUN git clone https://github.com/pytorch/vision.git /vision
WORKDIR /vision
RUN git checkout tags/v0.11.1-rc2

# Build torch - torchvision-0.11.0a0+cdacbe0-cp38-cp38-linux_aarch64.whl
RUN PYTORCH_WHEEL=$( ls /pytorch/dist ) && \
    pip install /pytorch/dist/$PYTORCH_WHEEL && \
    python3 setup.py bdist_wheel


# ################ Yolov5 Stage ################
# Yolov5 stage
FROM ubuntu:latest as yolov5_build

# Install linux packages
RUN apt update && apt install -y git && \
    git clone https://github.com/ultralytics/yolov5.git


# ################ Application Stage ################
# Setup main container
FROM ubuntu:latest as app

# Setup environmental variables
ENV TZ=Australia/Brisbane 
ENV DEBIAN_FRONTEND=noninteractive

# Copy in pre build libraries for application
COPY --from=pytorch_build /pytorch/dist /dist/torch
COPY --from=torchvision_build /vision/dist /dist/vision
COPY --from=yolov5_build /yolov5 /yolov5

# Install dependancies
RUN apt update && apt install -y --no-install-recommends \
    gcc \
    python3-pip \
    python3-venv \
    libopenmpi-dev \
    libomp-dev ccache \
    libopenblas-dev \
    libblas-dev \
    libeigen3-dev \
    libjpeg-dev \
    zlib1g-dev \
    libpython3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install python dependancies
RUN PYTORCH_WHEEL=$( ls /dist/torch ) && \
    VISION_WHEEL=$( ls /dist/vision ) && \
    python3 -m pip install --no-cache --upgrade pip && \
    pip install --no-cache \
    astunparse \
    expecttest \
    future \
    psutil \
    setuptools \
    six \
    types-dataclasses \
    typing_extensions \
    setuptools==59.5.0 \
    wheel \
    mock \
    matplotlib>=3.2.2 \
    numpy>=1.18.5 \
    opencv-python>=4.1.2 \
    Pillow>=7.1.2 \
    PyYAML>=5.3.1 \
    requests>=2.23.0 \
    scipy>=1.4.1 \
    tqdm>=4.41.0 \
    pandas>=1.1.4 \
    seaborn>=0.11.0 \
    /dist/torch/$PYTORCH_WHEEL \
    /dist/vision/$VISION_WHEEL

# Copy in the main runtime files
COPY ./app /app

# Create entrypoint for application
CMD python3 watcher.py