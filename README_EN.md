# Hello, Xiao A — Enterprise Knowledge Workflow Agent

[简体中文](README.md) | [English](README_EN.md)

An enterprise knowledge workflow agent built with FastAPI, LangGraph, PostgreSQL, Redis, and Milvus.

[Live showcase](https://kingoftaro.github.io/hello-xiao-a/) · [Project from 0 to 1](docs/从0到1项目搭建.md) · [Product documentation](docs/产品文档.md) · [Deployment guide](deploy/DEPLOY.md)

[![Project preview](showcase/screenshots/02-zhangsan-welcome.webp)](https://kingoftaro.github.io/hello-xiao-a/)

中文文档：[README.md](README.md)

## Quick start

### Prerequisites

- Docker Desktop with Docker Compose v2
- At least 8 GB of available memory; the first build downloads Python dependencies and local embedding models
- An API key for an OpenAI-compatible endpoint (the examples use DeepSeek)

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd hello-xiao-a
```

### 2. Create local configuration

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

macOS/Linux:

```bash
cp .env.example .env
```

At minimum, update these values in `.env`:

```dotenv
OPENAI_API_KEY=your-api-key
OPENAI_BASE_URL=https://api.deepseek.com/v1
PRIMARY_LLM_MODEL=deepseek-chat
LITE_LLM_MODEL=deepseek-chat
JWT_SECRET_KEY=replace-with-a-long-random-string
```

Development PostgreSQL and Redis passwords default to `change-me` and match `docker-compose.yml`. If you change either value, update `.env`; Compose reads the same values.

### 3. Start the stack

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f api
```

PostgreSQL initializes the base tables and demo users on first startup. To ingest the sample knowledge documents once the services are ready:

```bash
docker compose exec api python -m app.rag.ingest eval/sample_docs --type policy --ns shared_company
```

Do not ingest the same batch repeatedly, or Milvus will contain duplicate chunks.

Open:

- Web UI: http://localhost:8000/ui
- API docs: http://localhost:8000/docs
- Health check: http://localhost:8000/health
- Readiness check: http://localhost:8000/ready

Stop the services with `docker compose down`. Use `docker compose down -v` only when local database and model volumes are no longer needed.

## Configuration

Put real values in `.env`; it is ignored by Git. The repository only includes the secret-free `.env.example` template.

| Group | Main variables | Purpose |
| --- | --- | --- |
| LLM | `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `PRIMARY_LLM_MODEL` | Required; supports OpenAI-compatible endpoints |
| Embeddings | `EMBEDDING_MODEL`, `EMBEDDING_DIM`, `LOCAL_MODEL_DEVICE` | Local `BAAI/bge-m3`, 1024 dimensions by default |
| Milvus | `MILVUS_HOST`, `MILVUS_PORT`, `MILVUS_COLLECTION` | Vector storage and retrieval |
| PostgreSQL | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | Application and business data |
| Redis | `REDIS_PASSWORD`, `REDIS_DB` | Checkpoints, rate limiting, and cache |
| JWT | `JWT_SECRET_KEY`, `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | Authentication; replace the secret before public deployment |
| Observability | `OTEL_ENABLED`, `OTEL_EXPORTER_OTLP_ENDPOINT` | Optional OpenTelemetry tracing |
| External systems | `CRM_API_BASE`, `MAIL_API_BASE`, `TICKET_API_BASE` | Replace example endpoints when connecting real systems |

When running Python directly on the host, keep database hosts as `localhost`. Compose overrides them inside containers with `postgres`, `redis`, and `milvus-standalone`.

## Optional monitoring

```bash
docker compose --profile monitoring up -d prometheus grafana jaeger
```

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (development password: `admin`)
- Jaeger: http://localhost:16686

Enable tracing in `.env`:

```dotenv
OTEL_ENABLED=true
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4317
```

## Production deployment

```bash
cp .env.prod.example .env.prod
docker compose --env-file .env.prod -f docker-compose.prod.yml config
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

Replace every `change-me` value in `.env.prod` with an independent strong secret. Do not omit `--env-file .env.prod`: Compose needs it while resolving variables such as `${POSTGRES_PASSWORD}`. Configure HTTPS and review [deploy/DEPLOY.md](deploy/DEPLOY.md).

Before starting production Nginx, prepare `deploy/certs/server.crt` and `deploy/certs/server.key` according to `deploy/certs/README.md`. Real certificates are ignored by Git. The backup script is `scripts/backup.sh`; it writes to `backups/` and keeps seven days by default.

## Local Python development

```bash
python -m venv .venv
# Windows: .venv\Scripts\Activate.ps1
# macOS/Linux: source .venv/bin/activate
pip install -e ".[dev]"
docker compose up -d etcd minio milvus-standalone postgres redis
python -m app.main
```

## Repository structure

```text
app/                      application source
deploy/                   database, Nginx, Prometheus, and deployment files
docs/                     product and usage documentation
showcase/                 GitHub Pages project showcase
eval/                     evaluation data and validation scripts
scripts/                  maintenance scripts
.github/workflows/        automated project and Compose validation
.env.example              development configuration template
.env.prod.example         production configuration template
docker-compose.yml        development stack
docker-compose.prod.yml   production stack
```

## Security

- Never commit `.env`, `.env.prod`, logs, database files, or private keys.
- Before public deployment, change JWT, PostgreSQL, Redis, MinIO, and Grafana passwords.
- `change-me` in `.env.example` is only for local quick starts.

## Validation

```bash
python scripts/validate_project.py
docker compose -f docker-compose.yml config --quiet
docker compose --env-file .env.prod -f docker-compose.prod.yml config --quiet
```

GitHub Actions runs the same structure and Compose checks on every push and pull request. Updates to `showcase/` on `main` are automatically published to GitHub Pages. For a first deployment, set `Settings → Pages → Build and deployment → Source` to `GitHub Actions`.
