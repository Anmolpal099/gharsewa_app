<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Service extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'provider_id', 'name', 'description', 'category',
        'price', 'currency', 'duration_minutes',
        'status', 'image_urls', 'tags', 'metadata',
    ];

    protected $casts = [
        'price'      => 'decimal:2',
        'image_urls' => 'array',
        'tags'       => 'array',
        'metadata'   => 'array',
    ];

    public function provider()
    {
        return $this->belongsTo(User::class, 'provider_id');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }
}
