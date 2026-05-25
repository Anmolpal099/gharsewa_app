<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Review extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'booking_id',
        'customer_id',
        'provider_id',
        'service_id',
        'rating',
        'comment',
    ];

    protected $casts = [
        'rating' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    /**
     * Get the customer who wrote this review
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Get the provider being reviewed
     */
    public function provider()
    {
        return $this->belongsTo(User::class, 'provider_id');
    }

    /**
     * Get the service being reviewed
     */
    public function service()
    {
        return $this->belongsTo(Service::class);
    }

    /**
     * Get the booking this review is for
     */
    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    /**
     * Scope to filter by rating
     */
    public function scopeByRating($query, int $rating)
    {
        return $query->where('rating', $rating);
    }

    /**
     * Scope to filter high-rated reviews (4-5 stars)
     */
    public function scopeHighRated($query)
    {
        return $query->where('rating', '>=', 4);
    }
}
