<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

class AIConsultation extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'ai_consultations';

    /**
     * The primary key type.
     *
     * @var string
     */
    protected $keyType = 'string';

    /**
     * Indicates if the IDs are auto-incrementing.
     *
     * @var bool
     */
    public $incrementing = false;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'customer_id',
        'image_path',
        'image_size_kb',
        'markers',
        'ai_diagnosis',
        'recommended_service_type',
        'cost_min',
        'cost_max',
        'recommended_providers',
        'ai_response_raw',
        'processing_time_ms',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'markers' => 'array',
        'recommended_providers' => 'array',
        'ai_response_raw' => 'array',
        'cost_min' => 'decimal:2',
        'cost_max' => 'decimal:2',
        'image_size_kb' => 'integer',
        'processing_time_ms' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'deleted_at',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var array<int, string>
     */
    protected $appends = [
        'image_url',
    ];

    /**
     * Get the customer that owns the consultation.
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Get the full URL for the consultation image.
     *
     * @return string|null
     */
    public function getImageUrlAttribute(): ?string
    {
        if (!$this->image_path) {
            return null;
        }

        // Check if the path is already a full URL
        if (filter_var($this->image_path, FILTER_VALIDATE_URL)) {
            return $this->image_path;
        }

        // Generate URL from storage path
        return Storage::url($this->image_path);
    }

    /**
     * Scope a query to only include consultations for a specific customer.
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param string $customerId
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeForCustomer($query, string $customerId)
    {
        return $query->where('customer_id', $customerId);
    }

    /**
     * Scope a query to only include recent consultations.
     * Orders by created_at in descending order.
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param int $limit
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeRecent($query, int $limit = 10)
    {
        return $query->orderBy('created_at', 'desc')->limit($limit);
    }

    /**
     * Scope a query to filter by service type.
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param string $serviceType
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeByServiceType($query, string $serviceType)
    {
        return $query->where('recommended_service_type', $serviceType);
    }

    /**
     * Get the cost estimate range as a formatted string.
     *
     * @return string
     */
    public function getCostRangeAttribute(): string
    {
        return "NPR {$this->cost_min} - {$this->cost_max}";
    }

    /**
     * Get the number of markers in the consultation.
     *
     * @return int
     */
    public function getMarkerCountAttribute(): int
    {
        return is_array($this->markers) ? count($this->markers) : 0;
    }

    /**
     * Check if the consultation has recommended providers.
     *
     * @return bool
     */
    public function hasRecommendedProviders(): bool
    {
        return is_array($this->recommended_providers) && count($this->recommended_providers) > 0;
    }

    /**
     * Get the processing time in seconds.
     *
     * @return float
     */
    public function getProcessingTimeSecondsAttribute(): float
    {
        return round($this->processing_time_ms / 1000, 2);
    }
}
