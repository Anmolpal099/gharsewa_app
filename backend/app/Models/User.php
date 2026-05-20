<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'firebase_uid', 'email', 'name', 'role',
        'phone_number', 'profile_image_url',
        'is_active', 'metadata', 'last_login_at',
    ];

    protected $casts = [
        'is_active'     => 'boolean',
        'metadata'      => 'array',
        'last_login_at' => 'datetime',
    ];

    protected $hidden = ['deleted_at'];

    // ─── Relationships ────────────────────────────────────────────

    public function services()
    {
        return $this->hasMany(Service::class, 'provider_id');
    }

    public function bookingsAsCustomer()
    {
        return $this->hasMany(Booking::class, 'customer_id');
    }

    public function bookingsAsProvider()
    {
        return $this->hasMany(Booking::class, 'provider_id');
    }

    // ─── Scopes ───────────────────────────────────────────────────

    public function scopeCustomers($query)
    {
        return $query->where('role', 'customer');
    }

    public function scopeProviders($query)
    {
        return $query->where('role', 'serviceProvider');
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    // ─── Helpers ──────────────────────────────────────────────────

    public function isCustomer(): bool    { return $this->role === 'customer'; }
    public function isProvider(): bool    { return $this->role === 'serviceProvider'; }
    public function isAdmin(): bool       { return $this->role === 'admin'; }
}
