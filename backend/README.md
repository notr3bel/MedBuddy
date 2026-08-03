# MedIntel Backend

Simple FastAPI backend for MedIntel using Google Gemini API for prescription explanations.

## Setup

```bash
cd backend
python -m venv .venv
.\.venv\Scripts\activate  # On Windows
pip install -r requirements.txt
```

## API Key Setup (Gemini)

1. **Get your Gemini API key:**
   - Go to https://aistudio.google.com/app/apikey
   - Sign in with your Google account
   - Click "Create API Key" or use an existing key
   - Copy your API key (starts with `AIza...`)

2. **Set the environment variable:**

   **PowerShell (Windows):**
   ```powershell
   $env:GEMINI_API_KEY = "YOUR_API_KEY_HERE"
   ```

   **Command Prompt (Windows):**
   ```cmd
   set GEMINI_API_KEY=YOUR_API_KEY_HERE
   ```

   **Linux/macOS:**
   ```bash
   export GEMINI_API_KEY=YOUR_API_KEY_HERE
   ```

   **For permanent setup (Windows):**
   - Open System Properties → Environment Variables
   - Add new User variable: `GEMINI_API_KEY` = `YOUR_API_KEY_HERE`

## Run the server

```bash
uvicorn app.main:app --reload --port 8000
```

Then open `http://localhost:8000/api/health` to check the health endpoint, or `http://localhost:8000/docs` for Swagger UI.

