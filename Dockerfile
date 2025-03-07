FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04

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

# Install Python packages with specific CUDA version
RUN pip3 install --no-cache-dir torch torchvision torchaudio
RUN pip3 install --no-cache-dir openai-whisper

# Add CUDA to PATH
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

WORKDIR /app

# Copy Go service files
COPY transcription_api /app/transcription_api

# Build Go service
WORKDIR /app/transcription_api
# Инициализируем новый модуль с правильной версией Go
RUN go mod init whisper && \
    go mod tidy && \
    go build -o transcription_api

# Copy and setup start script
COPY transcription_api/start.sh .
RUN chmod +x start.sh

# Add CUDA check to start script
RUN echo '#!/bin/bash\npython3 -c "import torch; print(\"CUDA available:\", torch.cuda.is_available()); print(\"CUDA version:\", torch.version.cuda if torch.cuda.is_available() else \"N/A\")" && ./transcription_api' > start.sh
RUN chmod +x start.sh

CMD ["./start.sh"]