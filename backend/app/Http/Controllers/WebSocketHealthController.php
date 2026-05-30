<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Redis;
use Exception;

class WebSocketHealthController extends Controller
{
    /**
     * Health check endpoint for WebSocket server
     * 
     * Returns HTTP 200 when healthy, HTTP 503 when Redis unavailable
     * 
     * @return JsonResponse
     */
    public function health(): JsonResponse
    {
        try {
            // Check Redis connection
            $redis = Redis::connection();
            $pingResult = $redis->ping();
            
            // Verify ping was successful
            if ($pingResult === null || $pingResult === false) {
                throw new Exception('Redis ping failed');
            }
            
            $stats = [
                'status' => 'healthy',
                'uptime' => $this->getUptime(),
                'connections' => $this->getConnectionCount(),
                'redis' => 'connected',
                'timestamp' => now()->toIso8601String(),
            ];
            
            return response()->json($stats, 200);
            
        } catch (Exception $e) {
            return response()->json([
                'status' => 'unhealthy',
                'error' => 'Redis connection failed',
                'timestamp' => now()->toIso8601String(),
            ], 503);
        }
    }
    
    /**
     * Get server uptime in seconds
     * 
     * @return int
     */
    private function getUptime(): int
    {
        // For now, return 0 as uptime tracking requires process monitoring
        // This can be enhanced with a cache-based timestamp or process tracking
        return 0;
    }
    
    /**
     * Get current WebSocket connection count
     * 
     * @return int
     */
    private function getConnectionCount(): int
    {
        // For now, return 0 as connection count requires Reverb metrics integration
        // This can be enhanced by querying Reverb's internal metrics or Redis pub/sub stats
        return 0;
    }
}
