<?php

namespace Tests\Feature\Commands;

use Tests\TestCase;
use App\Models\User;
use App\Models\AIConsultation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class CleanupOldConsultationsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    /** @test */
    public function it_cleans_up_consultations_older_than_12_months()
    {
        // Create a customer
        $customer = User::factory()->create(['role' => 'customer']);

        // Create old consultation (13 months old)
        $oldConsultation = AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'image_path' => 'consultations/test-old.jpg',
            'created_at' => Carbon::now()->subMonths(13),
        ]);

        // Create recent consultation (6 months old)
        $recentConsultation = AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'image_path' => 'consultations/test-recent.jpg',
            'created_at' => Carbon::now()->subMonths(6),
        ]);

        // Create fake image files
        Storage::disk('public')->put($oldConsultation->image_path, 'old image content');
        Storage::disk('public')->put($recentConsultation->image_path, 'recent image content');

        // Run cleanup command
        $this->artisan('consultations:cleanup')
            ->expectsOutput('Starting cleanup of consultations older than 12 months...')
            ->expectsOutput('Found 1 consultations to clean up.')
            ->assertExitCode(0);

        // Assert old consultation was deleted
        $this->assertDatabaseMissing('ai_consultations', [
            'id' => $oldConsultation->id,
        ]);

        // Assert old image was deleted
        Storage::disk('public')->assertMissing($oldConsultation->image_path);

        // Assert recent consultation still exists
        $this->assertDatabaseHas('ai_consultations', [
            'id' => $recentConsultation->id,
        ]);

        // Assert recent image still exists
        Storage::disk('public')->assertExists($recentConsultation->image_path);
    }

    /** @test */
    public function it_supports_dry_run_mode()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        // Create old consultation
        $oldConsultation = AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'image_path' => 'consultations/test-old.jpg',
            'created_at' => Carbon::now()->subMonths(13),
        ]);

        Storage::disk('public')->put($oldConsultation->image_path, 'old image content');

        // Run cleanup in dry-run mode
        $this->artisan('consultations:cleanup --dry-run')
            ->expectsOutput('DRY RUN MODE - No data will be deleted')
            ->expectsOutput('This was a DRY RUN. No data was actually deleted.')
            ->assertExitCode(0);

        // Assert consultation still exists
        $this->assertDatabaseHas('ai_consultations', [
            'id' => $oldConsultation->id,
        ]);

        // Assert image still exists
        Storage::disk('public')->assertExists($oldConsultation->image_path);
    }

    /** @test */
    public function it_supports_custom_retention_period()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        // Create consultation 7 months old
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'image_path' => 'consultations/test.jpg',
            'created_at' => Carbon::now()->subMonths(7),
        ]);

        Storage::disk('public')->put($consultation->image_path, 'image content');

        // Run cleanup with 6 months retention
        $this->artisan('consultations:cleanup --months=6')
            ->expectsOutput('Starting cleanup of consultations older than 6 months...')
            ->assertExitCode(0);

        // Assert consultation was deleted (it's 7 months old, retention is 6)
        $this->assertDatabaseMissing('ai_consultations', [
            'id' => $consultation->id,
        ]);

        // Assert image was deleted
        Storage::disk('public')->assertMissing($consultation->image_path);
    }

    /** @test */
    public function it_handles_consultations_without_images()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        // Create old consultation without image
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'image_path' => null,
            'created_at' => Carbon::now()->subMonths(13),
        ]);

        // Run cleanup
        $this->artisan('consultations:cleanup')
            ->assertExitCode(0);

        // Assert consultation was deleted
        $this->assertDatabaseMissing('ai_consultations', [
            'id' => $consultation->id,
        ]);
    }

    /** @test */
    public function it_handles_missing_image_files_gracefully()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        // Create old consultation with image path but no actual file
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'image_path' => 'consultations/missing.jpg',
            'created_at' => Carbon::now()->subMonths(13),
        ]);

        // Don't create the actual file

        // Run cleanup (should not fail)
        $this->artisan('consultations:cleanup')
            ->assertExitCode(0);

        // Assert consultation was deleted
        $this->assertDatabaseMissing('ai_consultations', [
            'id' => $consultation->id,
        ]);
    }

    /** @test */
    public function it_shows_message_when_no_old_consultations_exist()
    {
        // Don't create any consultations

        $this->artisan('consultations:cleanup')
            ->expectsOutput('No old consultations found. Nothing to clean up.')
            ->assertExitCode(0);
    }

    /** @test */
    public function it_deletes_soft_deleted_consultations()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        // Create and soft delete old consultation
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'image_path' => 'consultations/test.jpg',
            'created_at' => Carbon::now()->subMonths(13),
        ]);

        Storage::disk('public')->put($consultation->image_path, 'image content');

        // Soft delete it
        $consultation->delete();

        // Run cleanup
        $this->artisan('consultations:cleanup')
            ->assertExitCode(0);

        // Assert consultation was permanently deleted (force deleted)
        $this->assertDatabaseMissing('ai_consultations', [
            'id' => $consultation->id,
        ]);

        // Assert image was deleted
        Storage::disk('public')->assertMissing($consultation->image_path);
    }

    /** @test */
    public function it_displays_summary_table()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        // Create 3 old consultations
        for ($i = 0; $i < 3; $i++) {
            $consultation = AIConsultation::factory()->create([
                'customer_id' => $customer->id,
                'image_path' => "consultations/test-{$i}.jpg",
                'created_at' => Carbon::now()->subMonths(13),
            ]);
            Storage::disk('public')->put($consultation->image_path, "image content {$i}");
        }

        $this->artisan('consultations:cleanup')
            ->expectsOutput('Cleanup Summary:')
            ->assertExitCode(0);
    }
}
