<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'booking_id', 'customer_id', 'amount', 'currency',
        'status', 'payment_intent_id', 'payment_method', 'metadata',
    ];

    protected $casts = [
        'amount'   => 'decimal:2',
        'metadata' => 'array',
    ];

    public function booking()  { return $this->belongsTo(Booking::class); }
    public function customer() { return $this->belongsTo(User::class, 'customer_id'); }
}
