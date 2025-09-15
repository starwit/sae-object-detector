FROM starwitorg/base-python-image:3.13.0 AS build

# Download all variants of ultralytics yolov8
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8n.pt" /code/
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8s.pt" /code/
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8m.pt" /code/
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8l.pt" /code/
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8x.pt" /code/

# This is needed for `tensorrt-*` installation (see https://github.com/NVIDIA/TensorRT/issues/3050)
ENV NVIDIA_TENSORRT_DISABLE_INTERNAL_PIP=True

# Copy only files that are necessary to install dependencies
COPY poetry.lock poetry.toml pyproject.toml /code/
WORKDIR /code
RUN poetry install
    
# Copy the rest of the project
COPY . /code/


### Main artifact / deliverable image

FROM python:3.13-trixie
RUN apt update && apt install --no-install-recommends -y \
    libglib2.0-0 \
    libgl1 \
    libturbojpeg0

RUN mkdir temp_intel && cd temp_intel && \
    apt update && apt install -y ocl-icd-libopencl1 wget && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.16.0/intel-igc-core-2_2.16.0+19683_amd64.deb && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.16.0/intel-igc-opencl-2_2.16.0+19683_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.31.34666.3/intel-ocloc-dbgsym_25.31.34666.3-0_amd64.ddeb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.31.34666.3/intel-ocloc_25.31.34666.3-0_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.31.34666.3/intel-opencl-icd-dbgsym_25.31.34666.3-0_amd64.ddeb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.31.34666.3/intel-opencl-icd_25.31.34666.3-0_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.31.34666.3/libigdgmm12_22.8.1_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.31.34666.3/libze-intel-gpu1-dbgsym_25.31.34666.3-0_amd64.ddeb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.31.34666.3/libze-intel-gpu1_25.31.34666.3-0_amd64.deb && \
    dpkg -i *.deb && \
    cd .. && rm -rf temp_intel

# TODO Normally we would switch to a non-root user here,
# but we have not gotten the Intel GPU access to work with a non-root user yet

COPY --from=build /code /code
WORKDIR /code

ENV PATH="/code/.venv/bin:$PATH"
CMD [ "python", "main.py" ]
