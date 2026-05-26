<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AIRequest extends Model
{
    use HasFactory;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'ai_requests';

    protected $fillable = [
        'request_type',
        'user_id',
        'prompt',
        'response',
        'response_time_ms',
        'success',
        'error_message',
        'metadata',
    ];

    protected $casts = [
        'success' => 'boolean',
        'metadata' => 'array',
        'response_time_ms' => 'integer',
    ];

    /**
     * Get the user that made the request
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope for successful requests
     */
    public function scopeSuccessful($query)
    {
        return $query->where('success', true);
    }

    /**
     * Scope for failed requests
     */
    public function scopeFailed($query)
    {
        return $query->where('success', false);
    }

    /**
     * Scope by request type
     */
    public function scopeOfType($query, string $type)
    {
        return $query->where('request_type', $type);
    }

    /**
     * Get average response time
     */
    public static function averageResponseTime(string $type = null): float
    {
        $query = static::successful();

        if ($type !== null) {
            $query->ofType($type);
        }

        return $query->avg('response_time_ms') ?? 0;
    }

    /**
     * Get success rate
     */
    public static function successRate(string $type = null): float
    {
        $query = static::query();

        if ($type !== null) {
            $query->ofType($type);
        }

        $total = $query->count();

        if ($total === 0) {
            return 0;
        }

        $successful = $query->where('success', true)->count();

        return ($successful / $total) * 100;
    }
}
