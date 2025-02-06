FROM manzolo/openai-whisper-docker:latest

WORKDIR /app

RUN apt-get update && apt-get install -y golang && rm -rf /var/lib/apt/lists/*

COPY transcription_api /app/transcription_api

WORKDIR /app/transcription_api
RUN go mod tidy && go build -o transcription_api

CMD ["./transcription_api"]
