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

# Copy the rest of your application code (main.py, etc.)
COPY . .

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
