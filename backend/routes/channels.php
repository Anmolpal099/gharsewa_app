<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\Booking;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

/**
 * Private channel for user-specific events (bookings, notifications)
 * 
 * Authorization: User can only subscribe to their own channel
 * Requirements: 2.5, 5.1
 */
Broadcast::channel('user.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

/**
 * Private channel for booking-specific events
 * 
 * Authorization: Only the customer or provider involved in the booking can subscribe
 * Requirements: 2.5, 5.2
 */
Broadcast::channel('booking.{bookingId}', function ($user, $bookingId) {
    $booking = Booking::find($bookingId);
    
    if (!$booking) {
        return false;
    }
    
    return $booking->customer_id === $user->id || 
           $booking->provider_id === $user->id;
});

/**
 * Presence channel for online service providers
 * 
 * Authorization: Only users with 'serviceProvider' role can join
 * Returns user information to be shared with other channel members
 * Requirements: 5.3, 5.4, 5.5
 */
Broadcast::channel('providers', function ($user) {
    // Check if user has serviceProvider role
    if (!$user->hasRole('serviceProvider')) {
        return null;
    }
    
    // Return user information to be shared with other presence channel members
    return [
        'id' => $user->id,
        'name' => $user->name,
    ];
});

/**
 * Presence channel for online customers
 * 
 * Authorization: Only users with 'customer' role can join
 * Returns user information to be shared with other channel members
 * Requirements: 5.3, 5.4, 5.5
 */
Broadcast::channel('customers', function ($user) {
    // Check if user has customer role
    if (!$user->hasRole('customer')) {
        return null;
    }
    
    // Return user information to be shared with other presence channel members
    return [
        'id' => $user->id,
        'name' => $user->name,
    ];
});
