<?php

namespace Database\Factories;

use App\Models\AIConsultation;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\AIConsultation>
 */
class AIConsultationFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = AIConsultation::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $serviceTypes = [
            'Plumbing Repair',
            'Electrical Work',
            'Carpentry',
            'Painting',
            'Cleaning',
            'Appliance Repair',
            'HVAC',
            'Pest Control',
            'Landscaping',
            'General Maintenance',
        ];

        $costMin = $this->faker->numberBetween(500, 5000);
        $costMax = $costMin * $this->faker->randomFloat(1, 1.5, 3.0);

        return [
            'id' => (string) Str::uuid(),
            'customer_id' => User::factory(),
            'image_path' => 'consultations/' . $this->faker->uuid() . '.jpg',
            'image_size_kb' => $this->faker->numberBetween(100, 5000),
            'markers' => $this->generateMarkers(),
            'ai_diagnosis' => $this->faker->sentence(10),
            'recommended_service_type' => $this->faker->randomElement($serviceTypes),
            'cost_min' => $costMin,
            'cost_max' => $costMax,
            'recommended_providers' => $this->generateProviders(),
            'ai_response_raw' => [
                'diagnosis' => $this->faker->sentence(10),
                'service_type' => $this->faker->randomElement($serviceTypes),
                'cost_estimate' => [
                    'min' => $costMin,
                    'max' => $costMax,
                    'currency' => 'NPR',
                ],
                'confidence' => $this->faker->randomFloat(2, 0.5, 1.0),
                'model' => 'qwen3-vl:2b',
                'processing_time_ms' => $this->faker->numberBetween(5000, 30000),
            ],
            'processing_time_ms' => $this->faker->numberBetween(5000, 30000),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }

    /**
     * Generate random markers array
     *
     * @return array
     */
    private function generateMarkers(): array
    {
        $markerCount = $this->faker->numberBetween(1, 5);
        $markers = [];

        for ($i = 0; $i < $markerCount; $i++) {
            $markers[] = [
                'x' => $this->faker->randomFloat(2, 0, 1),
                'y' => $this->faker->randomFloat(2, 0, 1),
                'description' => $this->faker->sentence(5),
            ];
        }

        return $markers;
    }

    /**
     * Generate random providers array
     *
     * @return array
     */
    private function generateProviders(): array
    {
        $providerCount = $this->faker->numberBetween(1, 3);
        $providers = [];

        for ($i = 0; $i < $providerCount; $i++) {
            $providers[] = [
                'id' => (string) Str::uuid(),
                'name' => $this->faker->company(),
                'rating' => $this->faker->randomFloat(1, 3.5, 5.0),
                'services' => [$this->faker->randomElement([
                    'Plumbing Repair',
                    'Electrical Work',
                    'Carpentry',
                    'Painting',
                ])],
            ];
        }

        return $providers;
    }

    /**
     * Indicate that the consultation is for a specific customer.
     *
     * @param string $customerId
     * @return static
     */
    public function forCustomer(string $customerId): static
    {
        return $this->state(fn (array $attributes) => [
            'customer_id' => $customerId,
        ]);
    }

    /**
     * Indicate that the consultation has a specific service type.
     *
     * @param string $serviceType
     * @return static
     */
    public function withServiceType(string $serviceType): static
    {
        return $this->state(fn (array $attributes) => [
            'recommended_service_type' => $serviceType,
        ]);
    }

    /**
     * Indicate that the consultation has specific markers.
     *
     * @param array $markers
     * @return static
     */
    public function withMarkers(array $markers): static
    {
        return $this->state(fn (array $attributes) => [
            'markers' => $markers,
        ]);
    }

    /**
     * Indicate that the consultation has specific providers.
     *
     * @param array $providers
     * @return static
     */
    public function withProviders(array $providers): static
    {
        return $this->state(fn (array $attributes) => [
            'recommended_providers' => $providers,
        ]);
    }
}
