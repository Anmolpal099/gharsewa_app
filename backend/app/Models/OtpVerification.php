<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class OtpVerification extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'email',
        'otp',
        'type',
        'expires_at',
        'is_used',
        'used_at',
        'attempts',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'used_at' => 'datetime',
        'is_used' => 'boolean',
        'attempts' => 'integer',
    ];

    /**
     * Generate a 6-digit OTP
     */
    public static function generateOtp(): string
    {
        return str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
    }

    /**
     * Create a new OTP for email verification
     */
    public static function createForEmailVerification(string $email): self
    {
        // Invalidate any existing OTPs for this email and type
        self::where('email', $email)
            ->where('type', 'email_verification')
            ->where('is_used', false)
            ->update(['is_used' => true]);

        return self::create([
            'email' => $email,
            'otp' => self::generateOtp(),
            'type' => 'email_verification',
            'expires_at' => Carbon::now()->addMinutes(10), // 10 minutes expiry
        ]);
    }

    /**
     * Create a new OTP for password reset
     */
    public static function createForPasswordReset(string $email): self
    {
        // Invalidate any existing OTPs for this email and type
        self::where('email', $email)
            ->where('type', 'password_reset')
            ->where('is_used', false)
            ->update(['is_used' => true]);

        return self::create([
            'email' => $email,
            'otp' => self::generateOtp(),
            'type' => 'password_reset',
            'expires_at' => Carbon::now()->addMinutes(10), // 10 minutes expiry
        ]);
    }

    /**
     * Verify OTP
     */
    public static function verify(string $email, string $otp, string $type): bool
    {
        $otpRecord = self::where('email', $email)
            ->where('otp', $otp)
            ->where('type', $type)
            ->where('is_used', false)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$otpRecord) {
            return false;
        }

        // Mark as used
        $otpRecord->update([
            'is_used' => true,
            'used_at' => Carbon::now(),
        ]);

        return true;
    }

    /**
     * Increment attempts
     */
    public function incrementAttempts(): void
    {
        $this->increment('attempts');
    }

    /**
     * Check if OTP is expired
     */
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * Check if OTP is valid
     */
    public function isValid(): bool
    {
        return !$this->is_used && !$this->isExpired() && $this->attempts < 5;
    }
}
