<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AIPrediction extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'prediction_type',
        'prediction_data',
        'confidence_score',
        'insights',
        'factors',
        'valid_until'
    ];

    protected $casts = [
        'prediction_data' => 'array',
        'factors' => 'array',
        'confidence_score' => 'float',
        'valid_until' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];

    /**
     * Scope for active predictions
     */
    public function scopeActive($query)
    {
        return $query->where('valid_until', '>', now());
    }

    /**
     * Scope for predictions by type
     */
    public function scopeOfType($query, string $type)
    {
        return $query->where('prediction_type', $type);
    }

    /**
     * Check if prediction is still valid
     */
    public function isValid(): bool
    {
        return $this->valid_until > now();
    }
}
