<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Booking extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'customer_id', 'service_id', 'provider_id',
        'scheduled_at', 'status', 'total_price', 'currency',
        'cancellation_reason', 'admin_notes', 'is_disputed', 'metadata',
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
        'total_price'  => 'decimal:2',
        'is_disputed'  => 'boolean',
        'metadata'     => 'array',
    ];

    public function customer()  { return $this->belongsTo(User::class, 'customer_id'); }
    public function provider()  { return $this->belongsTo(User::class, 'provider_id'); }
    public function service()   { return $this->belongsTo(Service::class); }
    public function payment()   { return $this->hasOne(Payment::class); }

    public function isPending():   bool { return $this->status === 'pending'; }
    public function isConfirmed(): bool { return $this->status === 'confirmed'; }
    public function isCompleted(): bool { return $this->status === 'completed'; }
    public function isCancelled(): bool { return $this->status === 'cancelled'; }
}
