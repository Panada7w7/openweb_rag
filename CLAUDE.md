# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker-based **Open WebUI** deployment configured to use **OpenAI API only** (no Ollama, no local LLMs) with built-in **RAG (Retrieval-Augmented Generation)** capabilities for document Q&A.

**Core Purpose**: Provide a ChatGPT-like interface that can:
1. Chat using OpenAI models (GPT-4o, GPT-4 Turbo, etc.)
2. Upload and process PDFs for RAG-based question answering
3. Persist all data (chats, documents, embeddings) across container restarts

## Architecture

### Components

1. **Open WebUI** (single Docker container)
   - Web interface for chat and document management
   - Built-in ChromaDB for vector storage
   - Handles PDF parsing, chunking, and embedding generation
   - Uses OpenAI API for both chat completions and embeddings

2. **Persistent Storage**
   - Named Docker volume: `open-webui-data`
   - Stores: user data, chat history, uploaded files, vector embeddings (ChromaDB database)

3. **OpenAI API** (external service)
   - Chat completions: User-selected model (gpt-4o default)
   - Embeddings: text-embedding-3-small (configurable in UI)

### Data Flow

**Chat Query:**
User Input → Open WebUI → OpenAI API (chat completion) → Response

**RAG Query:**
User Input → Open WebUI → Vector Search (ChromaDB) → Retrieve Chunks → OpenAI API (chat completion with context) → Response

**Document Upload:**
PDF File → Open WebUI (parse & chunk) → OpenAI API (generate embeddings) → Store in ChromaDB → Index for retrieval

## Key Files

- **docker-compose.yml**: Single-service stack (open-webui), port 3000, volume persistence
- **.env**: Contains OPENAI_API_KEY (gitignored, see .env.example)
- **.env.example**: Template with required environment variables
- **init.sh**: Helper script to validate Docker, check .env, start stack
- **README.md**: Complete user documentation (setup, RAG usage, troubleshooting)

## Common Commands

### Initial Setup
```bash
# Copy environment template and configure API key
cp .env.example .env
nano .env  # Add OPENAI_API_KEY=sk-...

# Start (automated)
./init.sh

# Start (manual)
docker compose up -d
```

### Operations
```bash
# View logs
docker compose logs -f open-webui

# Restart
docker compose restart

# Stop
docker compose down

# Stop and remove all data (DESTRUCTIVE)
docker compose down -v

# Update to latest image
docker compose pull && docker compose up -d
```

### Troubleshooting
```bash
# Check if container is running and healthy
docker compose ps

# Inspect environment variables inside container
docker compose exec open-webui env | grep OPENAI

# Access container shell
docker compose exec open-webui bash

# Check volume contents
docker compose exec open-webui ls -la /app/backend/data

# Inspect volume
docker volume inspect open-webui-data
```

### Backup/Restore
```bash
# Backup
docker compose down
docker run --rm -v open-webui-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/backup-$(date +%Y%m%d).tar.gz -C /data .
docker compose up -d

# Restore
docker compose down
docker volume rm open-webui-data
docker volume create open-webui-data
docker run --rm -v open-webui-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/backup-YYYYMMDD.tar.gz -C /data
docker compose up -d
```

## Configuration Details

### Environment Variables (docker-compose.yml)

**Required:**
- `OPENAI_API_KEY`: OpenAI API key (from .env file)

**Important:**
- `ENABLE_OLLAMA_API=false`: Disables Ollama integration
- `ENABLE_OPENAI_API=true`: Enables OpenAI API
- `OPENAI_API_BASE_URL`: Default is https://api.openai.com/v1 (override for proxies)
- `OPENAI_API_MODEL`: Default chat model (gpt-4o)

**Optional:**
- `ENABLE_SIGNUP`: Set to `false` to disable public registration
- Resource limits: Adjust memory/CPU in docker-compose.yml `deploy:` section

### Port Binding

**Default:** `127.0.0.1:3000:8080` (localhost only, secure)
- Open WebUI listens on port 8080 inside container
- Exposed as port 3000 on host
- Bound to 127.0.0.1 for security (local access only)

**External Access:** Change to `0.0.0.0:3000:8080` (use reverse proxy + HTTPS in production)

### Volume Persistence

**Volume Name:** `open-webui-data`
**Mount Path:** `/app/backend/data` (inside container)

**Contains:**
- `webui.db` - SQLite database (users, chats, settings)
- `uploads/` - Uploaded PDF files
- `vector_db/` or `chroma/` - ChromaDB vector embeddings
- Model configurations

**CRITICAL**: Never use `docker compose down -v` in production (deletes all data)

## RAG Implementation

Open WebUI's RAG is **built-in** and uses:

1. **Document Processing**:
   - PDF parsing (PyPDF2 or similar)
   - Text chunking (configurable size/overlap in Settings → Documents)
   - Deduplication based on content hash

2. **Embedding Generation**:
   - Uses OpenAI API: `text-embedding-3-small` (default) or `text-embedding-3-large`
   - Configured in UI: Settings → Documents → Embedding Model
   - Embeddings stored in ChromaDB (inside `open-webui-data` volume)

3. **Retrieval**:
   - User query is embedded using same OpenAI embedding model
   - ChromaDB performs vector similarity search
   - Top K chunks retrieved (default: 5, configurable)
   - Chunks injected into OpenAI chat completion context

4. **UI Workflow**:
   - Upload: Workspace → Documents → Upload PDF
   - Attach to chat: Click document icon in message input, select files/collections
   - Query: Type question, Open WebUI automatically retrieves relevant chunks

**Settings Location**: Settings → Documents (chunk size, overlap, Top K, embedding model)

## Security Considerations

1. **API Key Protection**:
   - `.env` is gitignored
   - Never commit API keys
   - Rotate keys periodically at platform.openai.com

2. **Network Exposure**:
   - Default localhost binding is secure for single-user
   - For external access: use reverse proxy (nginx/Traefik) with HTTPS + authentication

3. **User Management**:
   - First user becomes admin
   - Set `ENABLE_SIGNUP=false` after initial setup to prevent unauthorized registrations

4. **API Usage Monitoring**:
   - Monitor costs at https://platform.openai.com/usage
   - Set spending limits in OpenAI dashboard
   - Large PDFs can consume significant embedding tokens

## Troubleshooting Common Issues

### No OpenAI models appear in UI
- Verify `OPENAI_API_KEY` in `.env` is valid (starts with `sk-`)
- Check logs: `docker compose logs open-webui | grep -i openai`
- Test API key: `curl https://api.openai.com/v1/models -H "Authorization: Bearer YOUR_KEY"`
- Ensure billing enabled at platform.openai.com

### Documents not processing
- Check Settings → Documents → Embedding Model is set to OpenAI
- Verify `OPENAI_API_KEY` is configured
- Check logs: `docker compose logs open-webui | grep -i "embed\|document"`
- Try smaller PDF (< 50 pages) first to isolate issue

### Container fails health check
- Check logs: `docker compose logs open-webui`
- Verify port 3000 not in use: `lsof -i :3000`
- Ensure sufficient resources (2GB+ RAM)

### Data lost after restart
- Verify volume exists: `docker volume ls | grep open-webui-data`
- Check volume mount in container: `docker compose exec open-webui ls /app/backend/data`
- Ensure `docker-compose.yml` has correct volumes section
- DO NOT use `docker compose down -v` (deletes volumes)

## Development Notes

### Modifying Configuration

**Change OpenAI model:**
- Edit `.env`: `OPENAI_API_MODEL=gpt-3.5-turbo`
- Restart: `docker compose restart`

**Change port:**
- Edit `docker-compose.yml`: `ports: - "127.0.0.1:8080:8080"`
- Recreate: `docker compose up -d --force-recreate`

**Add resource limits:**
- Uncomment `deploy:` section in docker-compose.yml
- Adjust memory/CPU values
- Apply: `docker compose up -d`

### Testing Changes

```bash
# Validate compose file
docker compose config

# Dry-run (check what would change)
docker compose up --dry-run

# Apply changes
docker compose up -d

# Watch logs
docker compose logs -f open-webui
```

### Debugging

**Enable verbose logging:**
Add to docker-compose.yml environment:
```yaml
- WEBUI_DEBUG=true
```

**Access container:**
```bash
docker compose exec open-webui bash
# Inside container:
ls -la /app/backend/data
env | grep OPENAI
```

## Update Strategy

**Stable Version (Recommended):**
Pin to specific tag in docker-compose.yml:
```yaml
image: ghcr.io/open-webui/open-webui:v0.1.124
```

**Latest (Bleeding Edge):**
Use `:main` tag (current configuration) - updates on `docker compose pull`

**Check for updates:**
https://github.com/open-webui/open-webui/releases

**Update process:**
1. Backup data (see Backup section)
2. `docker compose pull`
3. `docker compose up -d`
4. Monitor logs for errors
5. Test functionality (chat, RAG)

## Important Constraints

- **No Ollama**: This setup explicitly disables Ollama (`ENABLE_OLLAMA_API=false`)
- **OpenAI Only**: All LLM and embedding requests go to OpenAI API
- **Built-in Vector DB**: Uses ChromaDB (included in Open WebUI), no external vector database
- **Single Service**: Only one container (open-webui), no separate services for embeddings/storage
- **macOS/Linux**: Shell scripts assume Unix-like environment (adapt for Windows)
