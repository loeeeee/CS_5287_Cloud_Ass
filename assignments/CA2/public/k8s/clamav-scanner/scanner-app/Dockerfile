FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy scanner application
COPY scanner.py .

# Create non-root user
RUN useradd -m -u 1000 scanner && chown -R scanner:scanner /app
USER scanner

# Run the scanner
CMD ["python", "scanner.py"]
