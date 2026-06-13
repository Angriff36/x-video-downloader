# Use the slim Python base image
FROM python:3.12.4-slim

# Install ffmpeg and unzip (needed for Deno install)
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg unzip curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Deno (required by yt-dlp >= 2025.11.12 for YouTube JS execution)
RUN curl -fsSL https://deno.land/install.sh | sh && \
    mv /root/.deno/bin/deno /usr/local/bin/deno && \
    rm -rf /root/.deno

# Set the working directory
WORKDIR /app

# Copy requirements file first
COPY requirements.txt .

# Install Python dependencies (globally in the container for simplicity now)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Install yt-dlp in its OWN layer, last, so it can be refreshed independently.
# The nightly GitHub Action passes a unique --build-arg YTDLP_REFRESH value,
# which busts the cache for this single line and pulls the latest master —
# i.e. the newest site-extractor fixes — without rebuilding ffmpeg/Deno/deps.
ARG YTDLP_REFRESH=manual
RUN echo "yt-dlp refresh token: ${YTDLP_REFRESH}" && \
    pip install --no-cache-dir --upgrade \
    "yt-dlp @ https://github.com/yt-dlp/yt-dlp/archive/refs/heads/master.tar.gz"

# Copy the rest of your application code (main.py, etc.)
COPY . .

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
