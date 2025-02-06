FROM nvidia/cuda:12.1.0-base-ubuntu22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    ffmpeg \
    golang \
    && rm -rf /var/lib/apt/lists/*

# Install Whisper
RUN pip3 install --no-cache-dir torch torchvision torchaudio
RUN pip3 install --no-cache-dir openai-whisper

WORKDIR /app

# Copy Go service files
COPY transcription_api /app/transcription_api

# Build Go service
WORKDIR /app/transcription_api
RUN go mod tidy && go build -o transcription_api

CMD ["./transcription_api"]
