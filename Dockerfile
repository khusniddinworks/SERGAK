# Use a lightweight official Python image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY sergak_bot/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire workspace
COPY . .

# Set working directory to sergak_bot
WORKDIR /app/sergak_bot

# Expose default port
EXPOSE 8000

# Run the bot
CMD ["python", "bot.py"]
