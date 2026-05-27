<?php

namespace Tests\Unit\Models;

use Tests\TestCase;
use App\Models\User;
use App\Models\AIConsultation;
use Illuminate\Foundation\Testing\RefreshDatabase;

class AIConsultationTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_belongs_to_a_user()
    {
        $user = User::factory()->create();
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $user->id,
        ]);

        $this->assertInstanceOf(User::class, $consultation->customer);
        $this->assertEquals($user->id, $consultation->customer->id);
    }

    /** @test */
    public function it_casts_markers_to_array()
    {
        $markers = [
            ['id' => '1', 'x' => 0.5, 'y' => 0.3, 'description' => 'Issue here'],
            ['id' => '2', 'x' => 0.7, 'y' => 0.8, 'description' => 'Another issue'],
        ];

        $consultation = AIConsultation::factory()->create([
            'markers' => $markers,
        ]);

        $this->assertIsArray($consultation->markers);
        $this->assertCount(2, $consultation->markers);
        $this->assertEquals($markers, $consultation->markers);
    }

    /** @test */
    public function it_casts_recommended_providers_to_array()
    {
        $providers = [
            ['id' => '1', 'name' => 'Provider A', 'rating' => 4.5],
            ['id' => '2', 'name' => 'Provider B', 'rating' => 4.8],
        ];

        $consultation = AIConsultation::factory()->create([
            'recommended_providers' => $providers,
        ]);

        $this->assertIsArray($consultation->recommended_providers);
        $this->assertCount(2, $consultation->recommended_providers);
        $this->assertEquals($providers, $consultation->recommended_providers);
    }

    /** @test */
    public function it_casts_ai_response_raw_to_array()
    {
        $rawResponse = [
            'model' => 'qwen3-vl:2b',
            'response_time' => 27.5,
            'tokens' => 150,
        ];

        $consultation = AIConsultation::factory()->create([
            'ai_response_raw' => $rawResponse,
        ]);

        $this->assertIsArray($consultation->ai_response_raw);
        $this->assertEquals($rawResponse, $consultation->ai_response_raw);
    }

    /** @test */
    public function it_scopes_consultations_for_customer()
    {
        $customer1 = User::factory()->create();
        $customer2 = User::factory()->create();

        AIConsultation::factory()->count(3)->create(['customer_id' => $customer1->id]);
        AIConsultation::factory()->count(2)->create(['customer_id' => $customer2->id]);

        $customer1Consultations = AIConsultation::forCustomer($customer1->id)->get();
        $customer2Consultations = AIConsultation::forCustomer($customer2->id)->get();

        $this->assertCount(3, $customer1Consultations);
        $this->assertCount(2, $customer2Consultations);
    }

    /** @test */
    public function it_scopes_recent_consultations()
    {
        AIConsultation::factory()->count(5)->create([
            'created_at' => now()->subDays(10),
        ]);

        AIConsultation::factory()->count(3)->create([
            'created_at' => now()->subDays(2),
        ]);

        $recentConsultations = AIConsultation::recent()->get();

        $this->assertCount(8, $recentConsultations);
        // Check that most recent is first
        $this->assertTrue(
            $recentConsultations->first()->created_at->greaterThan(
                $recentConsultations->last()->created_at
            )
        );
    }

    /** @test */
    public function it_scopes_consultations_by_service_type()
    {
        AIConsultation::factory()->count(3)->create([
            'recommended_service_type' => 'plumbing',
        ]);

        AIConsultation::factory()->count(2)->create([
            'recommended_service_type' => 'electrical',
        ]);

        $plumbingConsultations = AIConsultation::byServiceType('plumbing')->get();
        $electricalConsultations = AIConsultation::byServiceType('electrical')->get();

        $this->assertCount(3, $plumbingConsultations);
        $this->assertCount(2, $electricalConsultations);
    }

    /** @test */
    public function it_generates_image_url_accessor()
    {
        $consultation = AIConsultation::factory()->create([
            'image_path' => 'consultations/customer-123/test.jpg',
        ]);

        $imageUrl = $consultation->image_url;

        $this->assertStringContainsString('consultations/customer-123/test.jpg', $imageUrl);
        $this->assertStringContainsString('storage', $imageUrl);
    }

    /** @test */
    public function it_generates_cost_range_accessor()
    {
        $consultation = AIConsultation::factory()->create([
            'estimated_cost_min' => 5000,
            'estimated_cost_max' => 10000,
        ]);

        $costRange = $consultation->cost_range;

        $this->assertEquals('NPR 5,000 - 10,000', $costRange);
    }

    /** @test */
    public function it_counts_markers()
    {
        $markers = [
            ['id' => '1', 'x' => 0.5, 'y' => 0.3, 'description' => 'Issue 1'],
            ['id' => '2', 'x' => 0.7, 'y' => 0.8, 'description' => 'Issue 2'],
            ['id' => '3', 'x' => 0.2, 'y' => 0.6, 'description' => 'Issue 3'],
        ];

        $consultation = AIConsultation::factory()->create([
            'markers' => $markers,
        ]);

        $this->assertEquals(3, $consultation->marker_count);
    }

    /** @test */
    public function it_calculates_processing_time_in_seconds()
    {
        $consultation = AIConsultation::factory()->create([
            'processing_time_ms' => 27500, // 27.5 seconds
        ]);

        $this->assertEquals(27.5, $consultation->processing_time_seconds);
    }

    /** @test */
    public function it_checks_if_has_recommended_providers()
    {
        $consultationWithProviders = AIConsultation::factory()->create([
            'recommended_providers' => [
                ['id' => '1', 'name' => 'Provider A'],
            ],
        ]);

        $consultationWithoutProviders = AIConsultation::factory()->create([
            'recommended_providers' => [],
        ]);

        $this->assertTrue($consultationWithProviders->hasRecommendedProviders());
        $this->assertFalse($consultationWithoutProviders->hasRecommendedProviders());
    }

    /** @test */
    public function it_uses_soft_deletes()
    {
        $consultation = AIConsultation::factory()->create();
        $consultationId = $consultation->id;

        $consultation->delete();

        // Should not be found in normal queries
        $this->assertNull(AIConsultation::find($consultationId));

        // Should be found with trashed
        $this->assertNotNull(AIConsultation::withTrashed()->find($consultationId));
    }

    /** @test */
    public function it_can_be_restored_after_soft_delete()
    {
        $consultation = AIConsultation::factory()->create();
        $consultationId = $consultation->id;

        $consultation->delete();
        $this->assertNull(AIConsultation::find($consultationId));

        AIConsultation::withTrashed()->find($consultationId)->restore();
        $this->assertNotNull(AIConsultation::find($consultationId));
    }

    /** @test */
    public function it_can_be_force_deleted()
    {
        $consultation = AIConsultation::factory()->create();
        $consultationId = $consultation->id;

        $consultation->forceDelete();

        // Should not be found even with trashed
        $this->assertNull(AIConsultation::withTrashed()->find($consultationId));
    }

    /** @test */
    public function it_uses_uuid_as_primary_key()
    {
        $consultation = AIConsultation::factory()->create();

        $this->assertIsString($consultation->id);
        $this->assertEquals(36, strlen($consultation->id)); // UUID length
        $this->assertMatchesRegularExpression(
            '/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i',
            $consultation->id
        );
    }

    /** @test */
    public function it_combines_multiple_scopes()
    {
        $customer = User::factory()->create();

        AIConsultation::factory()->count(3)->create([
            'customer_id' => $customer->id,
            'recommended_service_type' => 'plumbing',
            'created_at' => now()->subDays(1),
        ]);

        AIConsultation::factory()->count(2)->create([
            'customer_id' => $customer->id,
            'recommended_service_type' => 'electrical',
            'created_at' => now()->subDays(2),
        ]);

        $consultations = AIConsultation::forCustomer($customer->id)
            ->byServiceType('plumbing')
            ->recent()
            ->get();

        $this->assertCount(3, $consultations);
        $this->assertEquals('plumbing', $consultations->first()->recommended_service_type);
    }
}
