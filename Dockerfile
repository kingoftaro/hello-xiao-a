FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# The package source must exist before Hatchling builds the editable package.
COPY pyproject.toml ./
COPY app ./app
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir -e .

# Cache the default embedding model in the image when the network is available.
# A failed pre-download does not fail the build; startup will retry the download.
RUN mkdir -p /data/hf_cache && \
    HF_HOME=/data/hf_cache \
    SENTENCE_TRANSFORMERS_HOME=/data/hf_cache \
    python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('BAAI/bge-m3')" || \
    echo "WARN: model pre-download failed; it will be retried at runtime"

COPY eval ./eval
COPY deploy ./deploy

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
