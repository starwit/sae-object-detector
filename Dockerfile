# You must run `poetry export` before building this

FROM starwitorg/sae-cv-base:0.1.0

RUN apt update && apt install --no-install-recommends -y \
    libglib2.0-0 \
    libgl1 \
    libturbojpeg0 \
    git

# Download all variants of ultralytics yolov8
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8n.pt" /code/
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8s.pt" /code/
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8m.pt" /code/
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8l.pt" /code/
ADD "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8x.pt" /code/

# TODO Normally we would switch to a non-root user here,
# but we have not gotten the Intel GPU access to work with a non-root user yet

WORKDIR /code

COPY requirements.txt ./
RUN pip install -r ./requirements.txt

COPY main.py ./
COPY objectdetector/ ./objectdetector/

CMD [ "python", "main.py" ]
