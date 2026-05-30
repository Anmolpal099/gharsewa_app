<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Tymon\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'firebase_uid',
        'email',
        'name',
        'password',
        'role',
        'roles', // New: Support multiple roles
        'phone_number',
        'profile_image_url',
        'profile_image_data', // NEW: Base64 image data
        'profile_image_mime_type', // NEW: Image MIME type
        'is_active',
        'email_verified_at',
        'metadata',
        'last_login_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'metadata' => 'array',
        'roles' => 'array', // Cast roles to array
        'email_verified_at' => 'datetime',
        'last_login_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    protected $hidden = [
        'password',
        'deleted_at',
        'profile_image_data', // Hide base64 data from responses (use profile_image_url instead)
    ];

    /**
     * Check if user has a specific role
     */
    public function hasRole(string $role): bool
    {
        return in_array($role, $this->roles ?? []);
    }

    /**
     * Check if user has any of the given roles
     */
    public function hasAnyRole(array $roles): bool
    {
        return !empty(array_intersect($roles, $this->roles ?? []));
    }

    /**
     * Add a role to the user
     */
    public function addRole(string $role): void
    {
        $roles = $this->roles ?? [];
        if (!in_array($role, $roles)) {
            $roles[] = $role;
            $this->roles = $roles;
            $this->save();
        }
    }

    /**
     * Remove a role from the user
     */
    public function removeRole(string $role): void
    {
        $roles = $this->roles ?? [];
        $this->roles = array_values(array_diff($roles, [$role]));
        $this->save();
    }

    /**
     * Get primary role (for backward compatibility)
     */
    public function getPrimaryRole(): string
    {
        return $this->roles[0] ?? 'customer';
    }

    /**
     * Check if user is a customer
     */
    public function isCustomer(): bool
    {
        return $this->hasRole('customer');
    }

    /**
     * Check if user is a service provider
     */
    public function isServiceProvider(): bool
    {
        return $this->hasRole('serviceProvider');
    }

    /**
     * Check if user is an admin
     */
    public function isAdmin(): bool
    {
        return $this->hasRole('admin');
    }

    /**
     * Scope to filter by role
     */
    public function scopeByRole($query, string $role)
    {
        return $query->where('role', $role);
    }

    /**
     * Scope to filter active users
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Get services provided by this user (if service provider)
     */
    public function services()
    {
        return $this->hasMany(Service::class, 'provider_id');
    }

    /**
     * Get bookings made by this user (if customer)
     */
    public function customerBookings()
    {
        return $this->hasMany(Booking::class, 'customer_id');
    }

    /**
     * Get bookings received by this user (if service provider)
     */
    public function providerBookings()
    {
        return $this->hasMany(Booking::class, 'provider_id');
    }

    /**
     * Get reviews written by this user
     */
    public function reviewsGiven()
    {
        return $this->hasMany(Review::class, 'customer_id');
    }

    /**
     * Get reviews received by this user (if service provider)
     */
    public function reviewsReceived()
    {
        return $this->hasMany(Review::class, 'provider_id');
    }

    /**
     * Get refresh tokens for this user
     */
    public function refreshTokens()
    {
        return $this->hasMany(RefreshToken::class);
    }

    /**
     * Get AI consultations for this user (if customer)
     */
    public function aiConsultations()
    {
        return $this->hasMany(AIConsultation::class, 'customer_id');
    }

    /**
     * Get the identifier that will be stored in the subject claim of the JWT.
     *
     * @return mixed
     */
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    /**
     * Return a key value array, containing any custom claims to be added to the JWT.
     *
     * @return array
     */
    public function getJWTCustomClaims()
    {
        return [
            'role' => $this->getPrimaryRole(), // Primary role for backward compatibility
            'roles' => $this->roles ?? [], // All roles
            'email' => $this->email,
            'name' => $this->name,
        ];
    }
}
