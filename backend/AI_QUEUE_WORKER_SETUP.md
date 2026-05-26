# AI Queue Worker Setup Guide

## Overview

The AI queue worker processes AI-related jobs asynchronously to prevent blocking the main application. This includes:
- Generating service recommendations
- Calculating match scores
- Generating analytics predictions
- Optimizing notification timing

## Configuration

### Queue Configuration

The queue configuration is located in `config/queue.php`. The AI processing queue is configured as follows:

```php
'ai-processing' => [
    'driver' => 'redis',
    'connection' => 'default',
    'queue' => 'ai-processing',
    'retry_after' => 180, // 3 minutes for AI operations
    'block_for' => null,
    'after_commit' => false,
],
```

### Environment Variables

Add the following to your `.env` file:

```env
QUEUE_CONNECTION=redis
REDIS_QUEUE=default
```

## Running the Queue Worker

### Development (Manual)

Start the queue worker manually for development:

```bash
# From the backend directory
php artisan queue:work redis --queue=ai-processing --sleep=3 --tries=3 --timeout=180

# Or using Docker
docker-compose exec app php artisan queue:work redis --queue=ai-processing --sleep=3 --tries=3 --timeout=180
```

**Options explained:**
- `--queue=ai-processing`: Process jobs from the ai-processing queue
- `--sleep=3`: Sleep for 3 seconds when no jobs are available
- `--tries=3`: Retry failed jobs up to 3 times
- `--timeout=180`: Maximum execution time of 180 seconds (3 minutes)

### Production (Supervisor)

For production, use Supervisor to manage the queue worker process.

#### 1. Install Supervisor (if not already installed)

```bash
# Ubuntu/Debian
sudo apt-get install supervisor

# CentOS/RHEL
sudo yum install supervisor
```

#### 2. Copy Supervisor Configuration

```bash
# Copy the configuration file
sudo cp supervisor-ai-worker.conf /etc/supervisor/conf.d/gharsewa-ai-worker.conf

# Update the configuration paths if needed
sudo nano /etc/supervisor/conf.d/gharsewa-ai-worker.conf
```

#### 3. Start Supervisor

```bash
# Reload supervisor configuration
sudo supervisorctl reread
sudo supervisorctl update

# Start the worker
sudo supervisorctl start gharsewa-ai-worker:*

# Check status
sudo supervisorctl status gharsewa-ai-worker:*
```

#### 4. Supervisor Commands

```bash
# Start workers
sudo supervisorctl start gharsewa-ai-worker:*

# Stop workers
sudo supervisorctl stop gharsewa-ai-worker:*

# Restart workers
sudo supervisorctl restart gharsewa-ai-worker:*

# View logs
sudo tail -f /var/www/html/storage/logs/ai-worker.log
```

## Dispatching Jobs

### From Controllers

```php
use App\Jobs\AI\GenerateRecommendationsJob;
use App\Jobs\AI\CalculateMatchScoresJob;
use App\Jobs\AI\GenerateAnalyticsJob;

// Dispatch recommendation generation
GenerateRecommendationsJob::dispatch($user)->onQueue('ai-processing');

// Dispatch match score calculation
CalculateMatchScoresJob::dispatch($booking)->onQueue('ai-processing');

// Dispatch analytics generation
GenerateAnalyticsJob::dispatch('booking_volume', 7)->onQueue('ai-processing');
```

### From Services

```php
use Illuminate\Support\Facades\Queue;

// Dispatch using Queue facade
Queue::push(new GenerateRecommendationsJob($user), '', 'ai-processing');
```

## Monitoring

### Check Queue Status

```bash
# View pending jobs
php artisan queue:monitor redis:ai-processing

# View failed jobs
php artisan queue:failed

# Retry failed jobs
php artisan queue:retry all

# Clear failed jobs
php artisan queue:flush
```

### Logs

Queue worker logs are stored in:
- Development: `storage/logs/laravel.log`
- Production (Supervisor): `storage/logs/ai-worker.log`

### Metrics

Monitor queue performance using the AI Health endpoint:

```bash
GET /api/v1/admin/ai/metrics
```

Returns:
- Total jobs processed
- Average processing time
- Success rate
- Failed jobs count

## Troubleshooting

### Worker Not Processing Jobs

1. Check if Redis is running:
   ```bash
   docker-compose ps redis
   ```

2. Check if worker is running:
   ```bash
   # Development
   ps aux | grep "queue:work"
   
   # Production
   sudo supervisorctl status gharsewa-ai-worker:*
   ```

3. Check Redis connection:
   ```bash
   docker-compose exec redis redis-cli ping
   ```

### Jobs Failing

1. Check failed jobs table:
   ```bash
   php artisan queue:failed
   ```

2. View error details:
   ```bash
   php artisan queue:failed --id=<job-id>
   ```

3. Retry failed job:
   ```bash
   php artisan queue:retry <job-id>
   ```

### High Memory Usage

1. Restart worker periodically:
   ```bash
   php artisan queue:restart
   ```

2. Limit worker memory:
   ```bash
   php artisan queue:work --memory=512
   ```

3. Process fewer jobs before restarting:
   ```bash
   php artisan queue:work --max-jobs=1000
   ```

## Performance Tuning

### Increase Worker Processes

Edit `supervisor-ai-worker.conf`:

```ini
numprocs=4  # Increase from 2 to 4 workers
```

Then reload:

```bash
sudo supervisorctl reread
sudo supervisorctl update
```

### Adjust Timeout

For longer AI operations, increase timeout:

```bash
php artisan queue:work --timeout=300  # 5 minutes
```

### Priority Queues

Process high-priority jobs first:

```bash
php artisan queue:work --queue=ai-processing-high,ai-processing
```

## Testing

### Test Job Dispatch

```bash
# Start worker in one terminal
php artisan queue:work redis --queue=ai-processing

# In another terminal, dispatch a test job
php artisan tinker
>>> $user = App\Models\User::first();
>>> App\Jobs\AI\GenerateRecommendationsJob::dispatch($user)->onQueue('ai-processing');
```

### Monitor Job Processing

```bash
# Watch logs in real-time
tail -f storage/logs/laravel.log | grep "AI"
```

## Docker Integration

### Add to docker-compose.yml

```yaml
ai-worker:
  build:
    context: ./backend
    dockerfile: Dockerfile
  command: php artisan queue:work redis --queue=ai-processing --sleep=3 --tries=3 --timeout=180
  volumes:
    - ./backend:/var/www/html
  depends_on:
    - redis
    - mysql
  networks:
    - gharsewa_network
  restart: unless-stopped
```

### Start with Docker Compose

```bash
docker-compose up -d ai-worker
```

## Best Practices

1. **Always use queues for AI operations** - AI requests can take 10-30 seconds
2. **Monitor queue depth** - Alert if queue grows too large
3. **Set appropriate timeouts** - AI operations need longer timeouts
4. **Implement retry logic** - AI services can be temporarily unavailable
5. **Log all operations** - Essential for debugging AI issues
6. **Use job batching** - Process multiple similar jobs together
7. **Implement rate limiting** - Prevent overwhelming Ollama service

## Security

1. **Validate job data** - Always validate input before processing
2. **Limit job payload size** - Prevent memory issues
3. **Sanitize AI responses** - Never trust AI output directly
4. **Monitor for abuse** - Track job dispatch patterns
5. **Implement job throttling** - Prevent queue flooding

## Maintenance

### Daily Tasks

- Check failed jobs: `php artisan queue:failed`
- Monitor queue depth: `php artisan queue:monitor`
- Review logs: `tail -f storage/logs/ai-worker.log`

### Weekly Tasks

- Analyze job performance metrics
- Review and retry failed jobs
- Clean up old failed jobs: `php artisan queue:prune-failed --hours=168`

### Monthly Tasks

- Review worker configuration
- Optimize queue performance
- Update supervisor configuration if needed
