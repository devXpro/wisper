FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    ffmpeg \
    golang \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python packages in virtual environment
RUN pip3 install --no-cache-dir torch torchvision torchaudio
RUN pip3 install --no-cache-dir openai-whisper

WORKDIR /app

# Copy Go service files
COPY transcription_api /app/transcription_api

# Build Go service
WORKDIR /app/transcription_api
RUN go mod tidy && go build -o transcription_api

# Copy and setup start script
COPY transcription_api/start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
