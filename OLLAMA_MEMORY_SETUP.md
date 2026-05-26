# Ollama Memory Configuration Guide

## Current Issue
The qwen3-vl:4b model requires 4.3 GiB of memory but only 2.3 GiB is currently available to the Ollama container.

## Solution: Increase Docker Memory Allocation

### For Docker Desktop on Windows (WSL2 Backend)

#### Option 1: Docker Desktop Settings (Recommended)
1. Open Docker Desktop
2. Go to **Settings** (gear icon)
3. Navigate to **Resources** → **Advanced**
4. Increase **Memory** slider to at least **8 GB** (recommended for qwen3-vl:4b)
5. Click **Apply & Restart**

#### Option 2: WSL2 Configuration File
If Docker Desktop settings don't work, configure WSL2 directly:

1. Create or edit `.wslconfig` file in your Windows user directory:
   ```
   C:\Users\<YourUsername>\.wslconfig
   ```

2. Add the following configuration:
   ```ini
   [wsl2]
   memory=8GB
   processors=4
   swap=2GB
   ```

3. Restart WSL2:
   ```powershell
   wsl --shutdown
   ```

4. Restart Docker Desktop

### Verification Steps

After increasing memory allocation:

1. **Check Docker stats:**
   ```powershell
   docker stats gharsewa_ollama --no-stream
   ```

2. **Test the model:**
   ```powershell
   docker exec gharsewa_ollama ollama run qwen3-vl:4b "Hello, can you help me?"
   ```

3. **Test via API:**
   ```powershell
   $body = @{model='qwen3-vl:4b'; prompt='Hello, test message'; stream=$false} | ConvertTo-Json
   Invoke-RestMethod -Uri 'http://localhost:11434/api/generate' -Method Post -Body $body -ContentType 'application/json'
   ```

## Current Model Status

Models loaded in Ollama:
- ✅ `qwen3-vl:4b` (3.3 GB) - **Target model** (requires 4.3GB RAM)
- ✅ `qwen3-vl:2b` (1.9 GB) - Smaller vision model (requires 2.7GB RAM)
- ✅ `qwen2.5:3b` (1.9 GB) - Text-only model (requires 1.9GB RAM)
- ✅ `tinyllama:latest` (637 MB) - Smallest model (requires ~800MB RAM)

## Recommended Configuration

For optimal performance with qwen3-vl:4b:
- **Memory:** 8 GB minimum (12 GB recommended)
- **Processors:** 4 cores minimum
- **Swap:** 2 GB

## Alternative: Use Smaller Model

If you cannot increase memory allocation, consider using:
- **qwen2.5:3b** - Good for text-based AI features (recommendations, matching, analytics)
- **qwen3-vl:2b** - Smaller vision model (may work with 4GB Docker memory)

Update the `.env` file to use the alternative model:
```env
OLLAMA_MODEL=qwen2.5:3b
```

## Next Steps

1. Increase Docker memory allocation using one of the methods above
2. Restart Docker Desktop
3. Run the verification steps
4. Continue with Task 1.2 verification
