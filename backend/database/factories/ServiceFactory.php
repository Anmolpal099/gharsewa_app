<?php

namespace Database\Factories;

use App\Models\Service;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ServiceFactory extends Factory
{
    protected $model = Service::class;

    public function definition(): array
    {
        return [
            'provider_id' => User::factory()->create(['role' => 'serviceProvider'])->id,
            'name' => $this->faker->words(3, true),
            'description' => $this->faker->paragraph(),
            'category' => $this->faker->randomElement(['cleaning', 'plumbing', 'electrical', 'carpentry', 'painting']),
            'price' => $this->faker->randomFloat(2, 20, 500),
            'currency' => 'USD',
            'duration_minutes' => $this->faker->randomElement([30, 60, 90, 120, 180]),
            'status' => 'active',
        ];
    }
}
