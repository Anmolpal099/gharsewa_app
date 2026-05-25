<?php

namespace Database\Factories;

use App\Models\Booking;
use App\Models\User;
use App\Models\Service;
use Illuminate\Database\Eloquent\Factories\Factory;

class BookingFactory extends Factory
{
    protected $model = Booking::class;

    public function definition(): array
    {
        $service = Service::factory()->create();
        
        return [
            'customer_id' => User::factory()->create(['role' => 'customer'])->id,
            'service_id' => $service->id,
            'provider_id' => $service->provider_id,
            'scheduled_at' => $this->faker->dateTimeBetween('now', '+30 days'),
            'status' => $this->faker->randomElement(['pending', 'confirmed', 'completed', 'cancelled', 'rejected']),
            'total_price' => $this->faker->randomFloat(2, 20, 500),
            'currency' => 'USD',
            'cancellation_reason' => null,
        ];
    }
}
