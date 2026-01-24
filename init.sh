#!/bin/bash
# Open WebUI Initialization Script

set -e

echo "🚀 Open WebUI + OpenAI Setup"
echo "============================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "   Install from: https://www.docker.com/get-started"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running"
    echo "   Start Docker Desktop (macOS/Windows) or Docker service (Linux)"
    exit 1
fi

echo "✅ Docker is running"

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose is not available"
    echo "   Update Docker to include Compose v2"
    exit 1
fi

echo "✅ Docker Compose is available"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found"

    if [ -f .env.example ]; then
        echo "📝 Copying .env.example to .env..."
        cp .env.example .env
        echo ""
        echo "⚠️  IMPORTANT: Edit .env and add your OpenAI API key!"
        echo "   Run: nano .env"
        echo "   Or: open -e .env (macOS)"
        echo ""

        read -p "Press Enter to continue after editing .env, or Ctrl+C to exit..."
    else
        echo "❌ Error: .env.example not found"
        exit 1
    fi
fi

# Validate .env has OPENAI_API_KEY
if ! grep -q "OPENAI_API_KEY=sk-" .env; then
    echo "⚠️  Warning: OPENAI_API_KEY may not be configured in .env"
    echo "   Make sure you've added your actual API key (starts with 'sk-')"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Please configure .env first."
        exit 1
    fi
fi

echo "✅ Configuration file (.env) exists"
echo ""

# Check if container is already running
if docker compose ps | grep -q "open-webui.*Up"; then
    echo "ℹ️  Open WebUI is already running"
    echo ""
    read -p "Restart the container? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Restarting Open WebUI..."
        docker compose restart
    else
        echo "Skipping restart."
    fi
else
    echo "🚀 Starting Open WebUI..."
    docker compose up -d
fi

echo ""
echo "⏳ Waiting for Open WebUI to be ready..."

# Wait for container to be healthy (max 60 seconds)
SECONDS=0
MAX_WAIT=60

while [ $SECONDS -lt $MAX_WAIT ]; do
    if docker compose ps | grep -q "open-webui.*Up.*healthy"; then
        echo "✅ Open WebUI is ready!"
        break
    fi

    if [ $SECONDS -ge $MAX_WAIT ]; then
        echo "⚠️  Open WebUI is starting but health check hasn't passed yet"
        echo "   Check logs: docker compose logs -f open-webui"
        break
    fi

    sleep 2
done

echo ""
echo "============================="
echo "✅ Setup Complete!"
echo ""
echo "📌 Next Steps:"
echo "   1. Open browser: http://localhost:3000"
echo "   2. Create your admin account"
echo "   3. Select an OpenAI model (e.g., gpt-4o)"
echo "   4. Start chatting or upload PDFs for RAG"
echo ""
echo "📚 Commands:"
echo "   View logs:    docker compose logs -f open-webui"
echo "   Stop:         docker compose down"
echo "   Restart:      docker compose restart"
echo ""
echo "🔧 Troubleshooting:"
echo "   If models don't appear, check your API key in .env"
echo "   For RAG setup, see README.md 'RAG / Document Q&A Setup'"
echo ""
