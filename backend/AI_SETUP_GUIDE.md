# AI Setup Guide - Ollama Configuration

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation Steps](#installation-steps)
   - [Step 1: Docker Setup](#step-1-docker-setup)
   - [Step 2: Start Ollama Container](#step-2-start-ollama-container)
   - [Step 3: Load AI Model](#step-3-load-ai-model)
   - [Step 4: Configure Laravel Environment](#step-4-configure-laravel-environment)
   - [Step 5: Run Database Migrations](#step-5-run-database-migrations)
   - [Step 6: Verify Installation](#step-6-verify-installation)
4. [Model Management](#model-management)
5. [Environment Configuration](#environment-configuration)
6. [Performance Tuning](#performance-tuning)
7. [Troubleshooting](#troubleshooting)
8. [Common Issues](#common-issues)
9. [Advanced Configuration](#advanced-configuration)
10. [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## Overview

This guide walks you through setting up the AI integration for GharSewa using Ollama, a locally-hosted AI model server. The system uses the Qwen3-VL model to provide:

- **Personalized Service Recommendations**: AI-driven suggestions based on user behavior
- **Provider-Customer Matching**: Intelligent scoring for optimal provider selection
- **Predictive Analytics**: Forecasting and trend analysis for business insights
- **Smart Notification Timing**: Optimized notification delivery
- **Safety SOP Generation**: AI-generated safety procedures for job types

**Key Benefits:**
- ✅ Zero API costs - runs completely locally
- ✅ Complete data privacy - no external API calls
- ✅ Fast response times - typically 1-3 seconds
- ✅ Offline capable - works without internet connection
- ✅ Customizable - switch models based on your needs

---

## Prerequisites

Before starting, ensure you have:


### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **RAM** | 4GB | 8GB+ |
| **Storage** | 5GB free | 10GB+ free |
| **CPU** | 2 cores | 4+ cores |
| **GPU** | Not required | NVIDIA GPU (optional, for faster inference) |

### Software Requirements

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **PHP**: Version 8.1 or higher (for Laravel backend)
- **Redis**: For caching (included in Docker setup)
- **MySQL**: Version 8.0 or higher (included in Docker setup)

### Network Requirements

- Port `11434` available for Ollama API
- Access to Docker Hub (for pulling Ollama image)
- Internet connection for initial model download (1.5GB - 3GB depending on model)

---

## Installation Steps

### Step 1: Docker Setup

Ensure Docker and Docker Compose are installed and running:

```bash
# Check Docker version
docker --version
# Expected output: Docker version 20.10.x or higher

# Check Docker Compose version
docker-compose --version
# Expected output: Docker Compose version 2.x.x or higher

# Verify Docker is running
docker ps
# Should show running containers or empty list (no errors)
```


If Docker is not installed, follow the official installation guide:
- **Windows**: [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- **macOS**: [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- **Linux**: [Docker Engine for Linux](https://docs.docker.com/engine/install/)

### Step 2: Start Ollama Container

The GharSewa project includes a pre-configured Docker Compose file for Ollama.

**2.1. Navigate to the backend directory:**

```bash
cd backend
```

**2.2. Ensure the Docker network exists:**

The Ollama container needs to connect to the existing GharSewa network. If you haven't started the main backend yet:

```bash
# Create the network if it doesn't exist
docker network create backend_gharsewa_network

# Or start the main backend first (which creates the network)
docker-compose up -d
```

**2.3. Start the Ollama container:**

```bash
docker-compose -f docker-compose.ollama.yml up -d
```

**Expected output:**
```
Creating volume "backend_ollama_data" with local driver
Creating gharsewa_ollama ... done
```


**2.4. Verify the container is running:**

```bash
docker ps | grep ollama
```

**Expected output:**
```
CONTAINER ID   IMAGE                  COMMAND               STATUS         PORTS                      NAMES
abc123def456   ollama/ollama:latest   "/bin/ollama serve"   Up 2 minutes   0.0.0.0:11434->11434/tcp   gharsewa_ollama
```

**2.5. Check Ollama logs:**

```bash
docker logs gharsewa_ollama
```

You should see logs indicating Ollama has started successfully.

**2.6. Test Ollama API:**

```bash
# From host machine
curl http://localhost:11434/api/tags

# From within Docker network (if testing from another container)
curl http://gharsewa_ollama:11434/api/tags
```

**Expected response:**
```json
{
  "models": []
}
```

The empty models array is expected at this stage - we'll load models in the next step.

---

### Step 3: Load AI Model

Ollama requires you to explicitly pull AI models before use. GharSewa supports several models with different performance characteristics.


**3.1. Choose a model:**

| Model | Size | Speed | Accuracy | Recommended For |
|-------|------|-------|----------|-----------------|
| `qwen3-vl:2b` | 1.5GB | Fast (1-2s) | Good | **Development & Testing** |
| `qwen3-vl:4b` | 2.8GB | Medium (2-3s) | Better | **Production (Recommended)** |
| `qwen2.5:3b` | 2.1GB | Medium (1.5-2.5s) | Good | General purpose |
| `tinyllama` | 637MB | Very Fast (0.5-1s) | Basic | Quick testing only |

**Recommendation:** Start with `qwen3-vl:2b` for development, then upgrade to `qwen3-vl:4b` for production.

**3.2. Pull the model:**

```bash
# Pull the recommended model (qwen3-vl:2b)
docker exec gharsewa_ollama ollama pull qwen3-vl:2b
```

**Expected output:**
```
pulling manifest
pulling 8934d96d3f08... 100% ▕████████████████▏ 1.5 GB
pulling 8c17c2ebb0ea... 100% ▕████████████████▏ 7.0 KB
pulling 7c23fb36d801... 100% ▕████████████████▏ 4.8 KB
pulling 2e0493f67d0c... 100% ▕████████████████▏   59 B
pulling fa8235e5b48f... 100% ▕████████████████▏  491 B
verifying sha256 digest
writing manifest
removing any unused layers
success
```

**Note:** The download may take 5-15 minutes depending on your internet speed.


**3.3. Verify the model is loaded:**

```bash
docker exec gharsewa_ollama ollama list
```

**Expected output:**
```
NAME              ID              SIZE      MODIFIED
qwen3-vl:2b       abc123def456    1.5 GB    2 minutes ago
```

**3.4. Test the model:**

```bash
docker exec gharsewa_ollama ollama run qwen3-vl:2b "Hello, how are you?"
```

You should receive a response from the AI model. Press `Ctrl+D` or type `/bye` to exit the interactive session.

---

### Step 4: Configure Laravel Environment

**4.1. Copy the environment template:**

```bash
# If you don't have a .env file yet
cp .env.example .env
```

**4.2. Add Ollama configuration to `.env`:**

Open the `.env` file and add/update the following variables:

```env
# AI Service - Ollama Configuration
# Use 'gharsewa_ollama' when accessing from Docker containers
# Use 'localhost' when accessing from host machine
OLLAMA_HOST=http://gharsewa_ollama:11434
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=60
OLLAMA_MAX_TOKENS=2048
OLLAMA_TEMPERATURE=0.7
OLLAMA_TOP_P=0.9
AI_CACHE_TTL=3600
AI_MAX_RETRIES=3
AI_RETRY_DELAY=1000
```


**Configuration Parameters Explained:**

| Parameter | Description | Default | Notes |
|-----------|-------------|---------|-------|
| `OLLAMA_HOST` | Ollama API endpoint | `http://gharsewa_ollama:11434` | Use container name from Docker network |
| `OLLAMA_MODEL` | AI model to use | `qwen3-vl:2b` | Must match a pulled model |
| `OLLAMA_TIMEOUT` | Request timeout (seconds) | `60` | Increase for slower systems |
| `OLLAMA_MAX_TOKENS` | Max tokens per request | `2048` | Higher = longer responses |
| `OLLAMA_TEMPERATURE` | Response randomness (0-1) | `0.7` | Lower = more deterministic |
| `OLLAMA_TOP_P` | Nucleus sampling (0-1) | `0.9` | Controls response diversity |
| `AI_CACHE_TTL` | Cache duration (seconds) | `3600` | 1 hour default |
| `AI_MAX_RETRIES` | Max retry attempts | `3` | For failed requests |
| `AI_RETRY_DELAY` | Retry delay (milliseconds) | `1000` | Exponential backoff |

**4.3. Ensure Redis is configured for caching:**

```env
CACHE_DRIVER=redis
REDIS_HOST=redis
REDIS_PORT=6379
```

**4.4. Ensure queue is configured:**

```env
QUEUE_CONNECTION=redis
```

---

### Step 5: Run Database Migrations

The AI integration requires several database tables for storing recommendations, match scores, predictions, and analytics.

**5.1. Run migrations:**

```bash
docker-compose exec app php artisan migrate
```


**Expected output:**
```
Migrating: 2024_01_xx_create_ai_requests_table
Migrated:  2024_01_xx_create_ai_requests_table (45.23ms)
Migrating: 2024_01_xx_create_ai_recommendations_table
Migrated:  2024_01_xx_create_ai_recommendations_table (52.18ms)
Migrating: 2024_01_xx_create_ai_match_scores_table
Migrated:  2024_01_xx_create_ai_match_scores_table (48.91ms)
Migrating: 2024_01_xx_create_ai_predictions_table
Migrated:  2024_01_xx_create_ai_predictions_table (41.33ms)
Migrating: 2024_01_xx_create_notification_schedules_table
Migrated:  2024_01_xx_create_notification_schedules_table (39.87ms)
```

**5.2. Verify tables were created:**

```bash
docker-compose exec app php artisan db:show
```

You should see the following AI-related tables:
- `ai_requests`
- `ai_recommendations`
- `ai_match_scores`
- `ai_predictions`
- `notification_schedules`

---

### Step 6: Verify Installation

**6.1. Start the queue worker:**

The AI system uses Laravel queues for async processing:

```bash
docker-compose exec app php artisan queue:work --queue=ai-processing
```

Keep this running in a separate terminal, or set up a supervisor process (see [Advanced Configuration](#advanced-configuration)).


**6.2. Test the AI health endpoint:**

```bash
# Get a JWT token first (replace with your admin credentials)
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'

# Use the token to check AI health
curl -X GET http://localhost:8000/api/v1/admin/ai/health \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Expected response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-15T10:30:00Z",
    "components": {
      "ollama": {
        "status": "healthy",
        "message": "Ollama is responding"
      },
      "redis": {
        "status": "healthy",
        "message": "Redis is responding"
      },
      "database": {
        "status": "healthy",
        "message": "Database is responding"
      },
      "model": {
        "status": "healthy",
        "message": "Model is available",
        "model_name": "qwen3-vl:2b"
      },
      "queue": {
        "status": "healthy",
        "message": "Failed jobs: 0",
        "failed_jobs": 0
      }
    }
  }
}
```


**6.3. Test a simple AI request:**

```bash
# Test recommendations endpoint (requires customer JWT token)
curl -X GET http://localhost:8000/api/v1/customer/ai/recommendations \
  -H "Authorization: Bearer YOUR_CUSTOMER_JWT_TOKEN"
```

If you receive recommendations, the AI system is working correctly!

**✅ Installation Complete!**

Your AI integration is now set up and ready to use. Proceed to the next sections for model management, performance tuning, and troubleshooting.

---

## Model Management

### Listing Available Models

```bash
# List models in Ollama
docker exec gharsewa_ollama ollama list
```

### Pulling Additional Models

```bash
# Pull a different model
docker exec gharsewa_ollama ollama pull qwen3-vl:4b

# Pull multiple models for comparison
docker exec gharsewa_ollama ollama pull qwen2.5:3b
docker exec gharsewa_ollama ollama pull tinyllama
```

### Switching Models

**1. Pull the new model (if not already available):**

```bash
docker exec gharsewa_ollama ollama pull qwen3-vl:4b
```

**2. Update `.env` file:**

```env
OLLAMA_MODEL=qwen3-vl:4b
```


**3. Clear the cache:**

```bash
docker-compose exec app php artisan cache:clear
```

**4. Restart the backend:**

```bash
docker-compose restart app
```

**5. Verify the change:**

```bash
curl -X GET http://localhost:8000/api/v1/admin/ai/health \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Check that `model_name` reflects the new model.

### Removing Models

To free up disk space, you can remove unused models:

```bash
# Remove a specific model
docker exec gharsewa_ollama ollama rm qwen2.5:3b

# Verify removal
docker exec gharsewa_ollama ollama list
```

**Warning:** Do not remove the model currently configured in `OLLAMA_MODEL` - this will cause AI requests to fail.

### Model Comparison

Test different models to find the best balance for your needs:

```bash
# Test response time with different models
time docker exec gharsewa_ollama ollama run qwen3-vl:2b "Recommend a service"
time docker exec gharsewa_ollama ollama run qwen3-vl:4b "Recommend a service"
```

---

## Environment Configuration

### Development vs Production Settings


**Development Configuration:**

```env
# Fast model for quick iteration
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=30
OLLAMA_MAX_TOKENS=1024
OLLAMA_TEMPERATURE=0.7
AI_CACHE_TTL=600  # 10 minutes
AI_MAX_RETRIES=2
```

**Production Configuration:**

```env
# Better model for accuracy
OLLAMA_MODEL=qwen3-vl:4b
OLLAMA_TIMEOUT=60
OLLAMA_MAX_TOKENS=2048
OLLAMA_TEMPERATURE=0.5  # More consistent
AI_CACHE_TTL=3600  # 1 hour
AI_MAX_RETRIES=3
```

### Temperature and Top_P Tuning

**Temperature** controls randomness:
- `0.0` - Deterministic, always same output
- `0.3-0.5` - Consistent, reliable (recommended for production)
- `0.7-0.9` - Creative, varied responses
- `1.0` - Very random

**Top_P** (nucleus sampling) controls diversity:
- `0.5` - Conservative, focused responses
- `0.9` - Balanced (recommended)
- `1.0` - Maximum diversity

**Recommended combinations:**

| Use Case | Temperature | Top_P |
|----------|-------------|-------|
| Recommendations | 0.5 | 0.9 |
| Matching Scores | 0.3 | 0.8 |
| Analytics | 0.4 | 0.85 |
| Safety SOPs | 0.3 | 0.8 |


### Cache Configuration

Caching significantly improves performance by avoiding redundant AI requests.

**Cache TTL by operation type:**

```env
# Recommendations: 1 hour (users' preferences change slowly)
AI_CACHE_TTL=3600

# For more frequent updates, reduce TTL:
AI_CACHE_TTL=1800  # 30 minutes
```

**Clear cache when needed:**

```bash
# Clear all cache
docker-compose exec app php artisan cache:clear

# Clear specific cache tags (if using tagged cache)
docker-compose exec app php artisan cache:forget ai:recommendations:user_123
```

### Timeout Configuration

Adjust timeouts based on your system performance:

```env
# Low-end systems (2-4GB RAM)
OLLAMA_TIMEOUT=120

# Mid-range systems (4-8GB RAM)
OLLAMA_TIMEOUT=60

# High-end systems (8GB+ RAM)
OLLAMA_TIMEOUT=30
```

---

## Performance Tuning

### System Resource Optimization

**1. Adjust Ollama memory limits:**

Edit `docker-compose.ollama.yml`:

```yaml
services:
  ollama:
    deploy:
      resources:
        limits:
          memory: 6G  # Increase for better performance
        reservations:
          memory: 4G
```


Restart Ollama after changes:

```bash
docker-compose -f docker-compose.ollama.yml down
docker-compose -f docker-compose.ollama.yml up -d
```

**2. Enable GPU acceleration (if available):**

Uncomment the GPU section in `docker-compose.ollama.yml`:

```yaml
services:
  ollama:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

**Prerequisites:**
- NVIDIA GPU
- NVIDIA Docker runtime installed
- CUDA drivers installed

**3. Optimize queue workers:**

Run multiple queue workers for parallel processing:

```bash
# Start 3 workers
docker-compose exec app php artisan queue:work --queue=ai-processing --tries=3 &
docker-compose exec app php artisan queue:work --queue=ai-processing --tries=3 &
docker-compose exec app php artisan queue:work --queue=ai-processing --tries=3 &
```

Or use Supervisor (see [Advanced Configuration](#advanced-configuration)).

### Response Time Optimization

**1. Reduce max tokens for faster responses:**

```env
OLLAMA_MAX_TOKENS=1024  # Instead of 2048
```

**2. Use a smaller model:**

```env
OLLAMA_MODEL=qwen3-vl:2b  # Instead of 4b
```


**3. Increase cache hit rate:**

```env
AI_CACHE_TTL=7200  # 2 hours
```

**4. Optimize prompts:**

Shorter, more focused prompts = faster responses. Review prompt templates in `backend/resources/prompts/`.

### Monitoring Performance

**Check AI metrics:**

```bash
curl -X GET http://localhost:8000/api/v1/admin/ai/metrics?period=24h \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Key metrics to monitor:**
- Average response time (target: < 3 seconds)
- Success rate (target: > 95%)
- Cache hit rate (target: > 40%)
- Queue length (target: < 10 pending jobs)

---

## Troubleshooting

### Diagnostic Commands

**1. Check all containers:**

```bash
docker ps -a
```

Ensure `gharsewa_ollama`, `backend_app`, `backend_redis`, and `backend_db` are running.

**2. Check Ollama logs:**

```bash
docker logs gharsewa_ollama --tail 50
```

**3. Check Laravel logs:**

```bash
docker-compose exec app tail -f storage/logs/laravel.log
```


**4. Test Ollama connectivity:**

```bash
# From host
curl http://localhost:11434/api/tags

# From backend container
docker-compose exec app curl http://gharsewa_ollama:11434/api/tags
```

**5. Check queue status:**

```bash
docker-compose exec app php artisan queue:failed
```

**6. Test Redis connection:**

```bash
docker-compose exec app php artisan tinker
>>> Cache::get('test');
>>> Cache::put('test', 'value', 60);
>>> Cache::get('test');
```

---

## Common Issues

### Issue 1: "Ollama is not responding"

**Symptoms:**
- AI health check shows Ollama as unhealthy
- Error: `AI_SERVICE_UNAVAILABLE`

**Causes:**
- Ollama container not running
- Network connectivity issues
- Wrong `OLLAMA_HOST` configuration

**Solutions:**

```bash
# Check if Ollama is running
docker ps | grep ollama

# If not running, start it
docker-compose -f docker-compose.ollama.yml up -d

# Check logs for errors
docker logs gharsewa_ollama

# Verify network connectivity
docker network inspect backend_gharsewa_network

# Test connection from backend
docker-compose exec app curl http://gharsewa_ollama:11434/api/tags
```


**Fix network issues:**

```bash
# Recreate the network
docker network rm backend_gharsewa_network
docker network create backend_gharsewa_network

# Restart containers
docker-compose down
docker-compose -f docker-compose.ollama.yml down
docker-compose up -d
docker-compose -f docker-compose.ollama.yml up -d
```

---

### Issue 2: "Model not found"

**Symptoms:**
- Error: `MODEL_NOT_FOUND`
- AI requests fail with model unavailable message

**Cause:**
- Model specified in `.env` not pulled in Ollama

**Solution:**

```bash
# Check available models
docker exec gharsewa_ollama ollama list

# Pull the missing model
docker exec gharsewa_ollama ollama pull qwen3-vl:2b

# Verify it's available
docker exec gharsewa_ollama ollama list

# Restart backend
docker-compose restart app
```

---

### Issue 3: "Request timeout"

**Symptoms:**
- AI requests taking > 60 seconds
- Error: `TIMEOUT_ERROR`

**Causes:**
- Model too large for available resources
- System under heavy load
- Insufficient timeout configuration


**Solutions:**

```env
# Increase timeout in .env
OLLAMA_TIMEOUT=120

# Use a smaller, faster model
OLLAMA_MODEL=qwen3-vl:2b

# Reduce max tokens
OLLAMA_MAX_TOKENS=1024
```

```bash
# Restart backend to apply changes
docker-compose restart app

# Check system resources
docker stats gharsewa_ollama
```

**Increase Ollama memory allocation:**

Edit `docker-compose.ollama.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 8G
    reservations:
      memory: 6G
```

```bash
# Apply changes
docker-compose -f docker-compose.ollama.yml down
docker-compose -f docker-compose.ollama.yml up -d
```

---

### Issue 4: "Parse error - Invalid JSON"

**Symptoms:**
- Error: `PARSE_ERROR`
- AI responses not in expected format

**Causes:**
- Temperature too high causing random output
- Model returning malformed JSON
- Prompt template issues

**Solutions:**

```env
# Lower temperature for more consistent output
OLLAMA_TEMPERATURE=0.5

# Adjust top_p
OLLAMA_TOP_P=0.8
```


```bash
# Check AI request logs
docker-compose exec app tail -f storage/logs/laravel.log | grep "AI request"

# Test model directly
docker exec -it gharsewa_ollama ollama run qwen3-vl:2b "Return JSON: {\"test\": true}"
```

**Review prompt templates:**

Check `backend/resources/prompts/*.txt` files and ensure they clearly specify JSON output format.

---

### Issue 5: "Queue jobs failing"

**Symptoms:**
- Failed jobs in queue
- AI operations not completing

**Causes:**
- Queue worker not running
- Database connection issues
- Redis connection issues

**Solutions:**

```bash
# Check failed jobs
docker-compose exec app php artisan queue:failed

# Retry failed jobs
docker-compose exec app php artisan queue:retry all

# Start queue worker if not running
docker-compose exec app php artisan queue:work --queue=ai-processing --tries=3

# Check Redis connection
docker-compose exec app php artisan tinker
>>> Redis::ping();
```

**Clear failed jobs:**

```bash
docker-compose exec app php artisan queue:flush
```

---

### Issue 6: "High memory usage"

**Symptoms:**
- Ollama container using excessive memory
- System becoming slow


**Solutions:**

```bash
# Check memory usage
docker stats gharsewa_ollama

# Use a smaller model
docker exec gharsewa_ollama ollama pull qwen3-vl:2b
```

Update `.env`:

```env
OLLAMA_MODEL=qwen3-vl:2b
```

**Set memory limits:**

Edit `docker-compose.ollama.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 4G  # Reduce limit
```

```bash
# Restart with new limits
docker-compose -f docker-compose.ollama.yml down
docker-compose -f docker-compose.ollama.yml up -d
```

---

### Issue 7: "Cache not working"

**Symptoms:**
- Every request hits Ollama (slow)
- Cache hit rate is 0%

**Causes:**
- Redis not running
- Wrong cache driver configuration
- Cache keys not consistent

**Solutions:**

```bash
# Check Redis is running
docker ps | grep redis

# Test Redis connection
docker-compose exec app php artisan tinker
>>> Cache::put('test', 'value', 60);
>>> Cache::get('test');
```


Verify `.env` configuration:

```env
CACHE_DRIVER=redis
REDIS_HOST=redis
REDIS_PORT=6379
```

```bash
# Clear config cache
docker-compose exec app php artisan config:clear

# Restart backend
docker-compose restart app
```

---

## Advanced Configuration

### Setting Up Supervisor for Queue Workers

For production, use Supervisor to keep queue workers running.

**1. Create supervisor config:**

Create `backend/supervisor/ai-worker.conf`:

```ini
[program:ai-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work redis --queue=ai-processing --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=3
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/worker.log
stopwaitsecs=3600
```

**2. Update Dockerfile to include Supervisor:**

Add to your `Dockerfile`:

```dockerfile
RUN apt-get update && apt-get install -y supervisor
COPY supervisor/ai-worker.conf /etc/supervisor/conf.d/
```


**3. Start Supervisor:**

```bash
docker-compose exec app supervisorctl reread
docker-compose exec app supervisorctl update
docker-compose exec app supervisorctl start ai-worker:*
```

### Scheduled Analytics Generation

Set up a cron job to generate analytics daily.

**1. Add to `app/Console/Kernel.php`:**

```php
protected function schedule(Schedule $schedule)
{
    $schedule->command('ai:generate-analytics')
        ->dailyAt('00:00')
        ->withoutOverlapping();
}
```

**2. Start the scheduler:**

```bash
docker-compose exec app php artisan schedule:work
```

Or add to crontab:

```bash
* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1
```

### Load Balancing Multiple Ollama Instances

For high-traffic scenarios, run multiple Ollama instances.

**1. Update `docker-compose.ollama.yml`:**

```yaml
services:
  ollama1:
    image: ollama/ollama:latest
    container_name: gharsewa_ollama_1
    ports:
      - "11434:11434"
    # ... rest of config

  ollama2:
    image: ollama/ollama:latest
    container_name: gharsewa_ollama_2
    ports:
      - "11435:11434"
    # ... rest of config
```


**2. Implement load balancing in Laravel:**

Update `AIService.php` to rotate between instances:

```php
protected function getOllamaHost(): string
{
    $hosts = [
        'http://gharsewa_ollama_1:11434',
        'http://gharsewa_ollama_2:11434',
    ];
    
    return $hosts[array_rand($hosts)];
}
```

### Custom Prompt Templates

Create custom prompts for specific use cases.

**1. Create a new template:**

Create `backend/resources/prompts/custom_recommendation.txt`:

```
You are an AI assistant for GharSewa.

TASK: Recommend services based on {{criteria}}.

CUSTOMER: {{customer_data}}

SERVICES: {{services}}

Return JSON: {"recommendations": [{"service_id": "uuid", "score": 85, "reason": "text"}]}
```

**2. Use in your service:**

```php
$prompt = $this->promptBuilder->build('custom_recommendation', [
    'criteria' => 'seasonal trends',
    'customer_data' => $customerData,
    'services' => $services,
]);
```

---

## Monitoring and Maintenance

### Daily Monitoring Checklist

**1. Check AI system health:**

```bash
curl -X GET http://localhost:8000/api/v1/admin/ai/health \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```


**2. Review AI metrics:**

```bash
curl -X GET http://localhost:8000/api/v1/admin/ai/metrics?period=24h \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**3. Check failed queue jobs:**

```bash
docker-compose exec app php artisan queue:failed
```

**4. Monitor Ollama resource usage:**

```bash
docker stats gharsewa_ollama
```

**5. Check disk space:**

```bash
docker system df
```

### Weekly Maintenance Tasks

**1. Review and retry failed jobs:**

```bash
docker-compose exec app php artisan queue:retry all
```

**2. Clear old AI request logs:**

```bash
docker-compose exec app php artisan db:query "DELETE FROM ai_requests WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY)"
```

**3. Optimize database:**

```bash
docker-compose exec app php artisan db:query "OPTIMIZE TABLE ai_requests, ai_recommendations, ai_match_scores, ai_predictions"
```

**4. Review cache hit rates:**

Check metrics endpoint and adjust `AI_CACHE_TTL` if needed.

### Monthly Maintenance Tasks

**1. Update Ollama:**

```bash
docker pull ollama/ollama:latest
docker-compose -f docker-compose.ollama.yml down
docker-compose -f docker-compose.ollama.yml up -d
```


**2. Review and update models:**

```bash
# Check for model updates
docker exec gharsewa_ollama ollama list

# Pull updated models
docker exec gharsewa_ollama ollama pull qwen3-vl:2b
```

**3. Backup AI data:**

```bash
# Backup AI-related tables
docker-compose exec db mysqldump -u root -p gharsewa \
  ai_requests ai_recommendations ai_match_scores ai_predictions notification_schedules \
  > ai_backup_$(date +%Y%m%d).sql
```

**4. Clean up unused Docker resources:**

```bash
docker system prune -a --volumes
```

### Performance Benchmarking

Run periodic benchmarks to track performance:

```bash
# Test recommendation endpoint response time
time curl -X GET http://localhost:8000/api/v1/customer/ai/recommendations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Test multiple concurrent requests
for i in {1..10}; do
  curl -X GET http://localhost:8000/api/v1/customer/ai/recommendations \
    -H "Authorization: Bearer YOUR_JWT_TOKEN" &
done
wait
```

### Log Rotation

Set up log rotation to prevent disk space issues:

**1. Create logrotate config:**

Create `/etc/logrotate.d/gharsewa-ai`:

```
/var/www/html/storage/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0644 www-data www-data
    sharedscripts
}
```


### Alerting and Notifications

Set up alerts for critical issues:

**1. Monitor Ollama uptime:**

Create a monitoring script:

```bash
#!/bin/bash
# check_ollama.sh

HEALTH=$(curl -s http://localhost:8000/api/v1/admin/ai/health -H "Authorization: Bearer $JWT_TOKEN")
STATUS=$(echo $HEALTH | jq -r '.data.status')

if [ "$STATUS" != "healthy" ]; then
    echo "ALERT: AI system unhealthy!"
    # Send notification (email, Slack, etc.)
fi
```

**2. Schedule the check:**

```bash
# Add to crontab (every 5 minutes)
*/5 * * * * /path/to/check_ollama.sh
```

---

## Additional Resources

### Documentation Links

- **Ollama Documentation**: https://github.com/ollama/ollama/blob/main/docs/api.md
- **Qwen Model Info**: https://ollama.com/library/qwen
- **Laravel Queues**: https://laravel.com/docs/queues
- **Redis Caching**: https://laravel.com/docs/cache

### Support and Community

- **GharSewa AI API Documentation**: See `AI_API_DOCUMENTATION.md`
- **GitHub Issues**: Report bugs and request features
- **Development Team**: Contact for technical support

### Best Practices Summary

✅ **DO:**
- Use caching to reduce AI requests
- Monitor system health regularly
- Start with smaller models for development
- Set appropriate timeouts
- Use queue workers for async processing
- Keep models updated
- Back up AI data regularly


❌ **DON'T:**
- Run without caching in production
- Use large models on low-memory systems
- Ignore failed queue jobs
- Skip health monitoring
- Remove models currently in use
- Set temperature too high (> 0.9)
- Forget to restart after config changes

---

## Quick Reference

### Essential Commands

```bash
# Start Ollama
docker-compose -f docker-compose.ollama.yml up -d

# Stop Ollama
docker-compose -f docker-compose.ollama.yml down

# Check Ollama status
docker ps | grep ollama

# View Ollama logs
docker logs gharsewa_ollama

# List models
docker exec gharsewa_ollama ollama list

# Pull a model
docker exec gharsewa_ollama ollama pull qwen3-vl:2b

# Test Ollama API
curl http://localhost:11434/api/tags

# Check AI health
curl http://localhost:8000/api/v1/admin/ai/health -H "Authorization: Bearer TOKEN"

# Start queue worker
docker-compose exec app php artisan queue:work --queue=ai-processing

# Check failed jobs
docker-compose exec app php artisan queue:failed

# Clear cache
docker-compose exec app php artisan cache:clear

# Run migrations
docker-compose exec app php artisan migrate
```


### Environment Variables Quick Reference

```env
# Required
OLLAMA_HOST=http://gharsewa_ollama:11434
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=60
OLLAMA_MAX_TOKENS=2048
OLLAMA_TEMPERATURE=0.7
OLLAMA_TOP_P=0.9
AI_CACHE_TTL=3600
AI_MAX_RETRIES=3
AI_RETRY_DELAY=1000

# Cache & Queue
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
REDIS_HOST=redis
REDIS_PORT=6379
```

### Model Comparison Quick Reference

| Model | Size | Speed | RAM | Use Case |
|-------|------|-------|-----|----------|
| tinyllama | 637MB | ⚡⚡⚡ | 2GB | Testing only |
| qwen3-vl:2b | 1.5GB | ⚡⚡ | 4GB | Development |
| qwen2.5:3b | 2.1GB | ⚡⚡ | 4GB | General |
| qwen3-vl:4b | 2.8GB | ⚡ | 6GB | Production |

### Troubleshooting Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| Ollama not responding | `docker-compose -f docker-compose.ollama.yml restart` |
| Model not found | `docker exec gharsewa_ollama ollama pull qwen3-vl:2b` |
| Timeout errors | Increase `OLLAMA_TIMEOUT` in `.env` |
| Parse errors | Lower `OLLAMA_TEMPERATURE` to 0.5 |
| Queue jobs failing | `docker-compose exec app php artisan queue:retry all` |
| Cache not working | Verify `CACHE_DRIVER=redis` and restart |
| High memory usage | Use smaller model or increase memory limits |

---

## Conclusion


You now have a fully functional AI integration for GharSewa! The system provides:

- ✅ Personalized recommendations for customers
- ✅ Intelligent provider-customer matching
- ✅ Predictive analytics for admins
- ✅ Smart notification timing
- ✅ AI-generated safety SOPs

**Next Steps:**

1. **Test the integration**: Use the API endpoints to verify all features work
2. **Monitor performance**: Check metrics regularly and optimize as needed
3. **Tune for your workload**: Adjust cache TTL, timeouts, and model based on usage
4. **Set up monitoring**: Implement health checks and alerting
5. **Plan for scale**: Consider multiple Ollama instances for high traffic

**Need Help?**

- Review the [AI API Documentation](AI_API_DOCUMENTATION.md) for endpoint details
- Check the [Troubleshooting](#troubleshooting) section for common issues
- Contact the development team for technical support

**Happy AI-powered service matching! 🚀**

---

*Last Updated: January 2024*
*Version: 1.0*
