# OpenAI Responses API Proxy

This proxy enables Open WebUI to access newer OpenAI models (like `chatgpt-4o-latest`, `gpt-4.1`, `gpt-5.x`) that require the Responses API instead of the older Chat Completions API.

## Problem Solved

**Issue**: Open WebUI only supports the Chat Completions API (`/v1/chat/completions`). Newer OpenAI models require the Responses API, so they don't appear in Open WebUI's chat dropdown even though they're listed in Settings → Models.

**Solution**: This proxy translates between the two APIs, making newer models accessible.

## How It Works

```
Open WebUI → Proxy (/v1/chat/completions) → OpenAI Responses API → Response → Proxy → Open WebUI
```

1. Open WebUI sends requests to the proxy (thinking it's OpenAI)
2. Proxy detects if the model requires Responses API
3. Proxy translates the request and forwards to OpenAI
4. Proxy receives response and converts back to Chat Completions format
5. Open WebUI receives the response and displays it

## Quick Start

### Option 1: Docker Compose (Recommended)

**From the proxy directory:**

```bash
cd proxy

# Copy environment configuration
cp ../.env .env  # Or create new .env with OPENAI_API_KEY

# Start proxy
docker compose up -d

# Check logs
docker compose logs -f openai-proxy

# Proxy is now running on http://localhost:8000
```

### Option 2: Python (Development)

```bash
cd proxy

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variable
export OPENAI_API_KEY=sk-your-key-here

# Run proxy
python app.py

# Or with uvicorn
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

## Configure Open WebUI to Use Proxy

1. **Access Open WebUI** at http://localhost:3000

2. **Go to Settings** (click avatar → Settings)

3. **Add New OpenAI Connection**:
   - Navigate to **Connections** → **OpenAI**
   - Click **Add Connection** or **+ (Plus icon)**

4. **Configure Connection**:
   - **Name**: `OpenAI Proxy (Newer Models)`
   - **API Base URL**: `http://openai-proxy:8000/v1` (if using Docker network)
     - Or: `http://localhost:8000/v1` (if proxy runs separately)
   - **API Key**: Your OpenAI API key (same as before)

5. **Save and Test**

6. **In Chat**: Open model selector → You should now see:
   - All standard models (gpt-4, gpt-4-turbo, etc.)
   - **NEW**: chatgpt-4o-latest, gpt-4.1, etc.

## Integration with Main Stack

To run the proxy alongside Open WebUI in a single stack:

**Edit `../docker-compose.yml`** (parent directory):

```yaml
version: '3.8'

services:
  open-webui:
    # ... existing open-webui config ...
    depends_on:
      - openai-proxy

  openai-proxy:
    build: ./proxy
    container_name: openai-proxy
    restart: unless-stopped
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - OPENAI_BASE_URL=${OPENAI_BASE_URL:-https://api.openai.com/v1}
    healthcheck:
      test: ["CMD", "python", "-c", "import httpx; httpx.get('http://localhost:8000/health')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

volumes:
  open-webui-data:
    name: open-webui-data
```

Then in Open WebUI, use: `http://openai-proxy:8000/v1` as the API Base URL.

## Supported Models

The proxy automatically handles these models:

| Model | Status | Notes |
|-------|--------|-------|
| `chatgpt-4o-latest` | ✅ Proxied | Latest GPT-4o variant |
| `gpt-4.1` | ✅ Proxied | GPT-4.1 (if available) |
| `gpt-5.2-chat-latest` | ✅ Proxied | GPT-5 series (if available) |
| Standard models | ✅ Pass-through | gpt-4, gpt-3.5-turbo, etc. |

**Adding More Models:**

Edit `app.py` and add to `MODEL_MAPPING`:

```python
MODEL_MAPPING = {
    "chatgpt-4o-latest": "chatgpt-4o-latest",
    "gpt-4.1": "gpt-4.1",
    "your-new-model": "actual-openai-model-name",
}
```

Rebuild: `docker compose up -d --build`

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | Yes | - | Your OpenAI API key |
| `OPENAI_BASE_URL` | No | `https://api.openai.com/v1` | OpenAI API base URL |
| `PORT` | No | `8000` | Port to listen on |

### Model Mapping

The proxy includes a model mapping in `app.py`:

```python
MODEL_MAPPING = {
    "chatgpt-4o-latest": "chatgpt-4o-latest",
    "gpt-4.1": "gpt-4.1",
    # Add more mappings here
}
```

- **Key**: Model name as requested by Open WebUI
- **Value**: Actual model name to send to OpenAI

## API Endpoints

### Health Check
```bash
curl http://localhost:8000/health
```

### List Models
```bash
curl http://localhost:8000/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Chat Completions
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "chatgpt-4o-latest",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Troubleshooting

### Proxy won't start

**Check logs:**
```bash
docker compose logs openai-proxy
```

**Common issues:**
- Missing `OPENAI_API_KEY` in `.env`
- Port 8000 already in use

### Models still don't appear in Open WebUI

1. **Verify proxy is running**:
   ```bash
   curl http://localhost:8000/health
   ```

2. **Check Open WebUI connection settings**:
   - Settings → Connections → Verify API Base URL is correct
   - For Docker: use `http://openai-proxy:8000/v1`
   - For separate deployment: use `http://localhost:8000/v1`

3. **Restart Open WebUI**:
   ```bash
   docker compose restart open-webui
   ```

4. **Clear browser cache** and reload Open WebUI

### API errors when using newer models

**Check proxy logs**:
```bash
docker compose logs -f openai-proxy
```

**Possible causes:**
- API key doesn't have access to the model
- Model name is incorrect
- Responses API format has changed (update `app.py`)

## Development

### Running Tests

```bash
# Install dev dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest test_app.py
```

### Debugging

Enable debug logging in `app.py`:

```python
logging.basicConfig(level=logging.DEBUG)
```

### Modifying API Translation

The proxy has two main conversion functions:

1. **`convert_chat_to_responses_format()`**: Converts incoming requests
2. **`convert_responses_to_chat_format()`**: Converts outgoing responses

Edit these functions to adjust the translation logic.

## Security Notes

- **API Key**: Never commit `.env` file or hardcode keys
- **Network Exposure**: Default binds to `127.0.0.1` (localhost only)
- **Production**: Use HTTPS reverse proxy (nginx, Traefik) for external access
- **Rate Limiting**: Consider adding rate limiting for production use

## Performance

- **Latency**: Adds minimal overhead (~10-50ms for request/response conversion)
- **Streaming**: Fully supports streaming responses
- **Concurrent Requests**: Handles multiple simultaneous requests via async/await

## Limitations

- **Responses API Format**: OpenAI's Responses API documentation is limited. This proxy makes best-effort translations based on available information.
- **Model Availability**: You still need API key access to newer models.
- **Feature Parity**: Some Responses API features may not be fully supported yet.

## Updates

To update the proxy:

```bash
cd proxy
git pull  # If in version control
docker compose up -d --build
```

## Contributing

Improvements welcome! Especially:
- Better Responses API format handling
- Additional model mappings
- Error handling improvements
- Tests

## License

This proxy is provided as-is for use with Open WebUI and OpenAI.
Adjust and extend as needed for your use case.
