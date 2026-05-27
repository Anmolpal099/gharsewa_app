<?php

namespace App\Console\Commands;

use App\Models\AIConsultation;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class CleanupOldConsultations extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'consultations:cleanup 
                            {--dry-run : Run without actually deleting anything}
                            {--months=12 : Number of months to retain (default: 12)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean up AI consultations and associated images older than specified months (default: 12 months)';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $dryRun = $this->option('dry-run');
        $months = (int) $this->option('months');
        
        $this->info("Starting cleanup of consultations older than {$months} months...");
        
        if ($dryRun) {
            $this->warn('DRY RUN MODE - No data will be deleted');
        }

        // Calculate cutoff date
        $cutoffDate = Carbon::now()->subMonths($months);
        $this->info("Cutoff date: {$cutoffDate->toDateTimeString()}");

        // Query old consultations (including soft deleted ones)
        $consultations = AIConsultation::withTrashed()
            ->where('created_at', '<', $cutoffDate)
            ->get();

        if ($consultations->isEmpty()) {
            $this->info('No old consultations found. Nothing to clean up.');
            return Command::SUCCESS;
        }

        $this->info("Found {$consultations->count()} consultations to clean up.");

        $deletedImages = 0;
        $deletedConsultations = 0;
        $failedImages = 0;

        // Progress bar
        $bar = $this->output->createProgressBar($consultations->count());
        $bar->start();

        foreach ($consultations as $consultation) {
            // Delete associated image file
            if ($consultation->image_path) {
                if ($dryRun) {
                    // Check if file exists
                    if (Storage::disk('public')->exists($consultation->image_path)) {
                        $deletedImages++;
                        $this->newLine();
                        $this->line("Would delete image: {$consultation->image_path}");
                    }
                } else {
                    // Actually delete the file
                    try {
                        if (Storage::disk('public')->exists($consultation->image_path)) {
                            Storage::disk('public')->delete($consultation->image_path);
                            $deletedImages++;
                        }
                    } catch (\Exception $e) {
                        $failedImages++;
                        $this->newLine();
                        $this->error("Failed to delete image {$consultation->image_path}: {$e->getMessage()}");
                    }
                }
            }

            // Force delete the consultation record (permanent deletion)
            if (!$dryRun) {
                try {
                    $consultation->forceDelete();
                    $deletedConsultations++;
                } catch (\Exception $e) {
                    $this->newLine();
                    $this->error("Failed to delete consultation {$consultation->id}: {$e->getMessage()}");
                }
            } else {
                $deletedConsultations++;
                $this->newLine();
                $this->line("Would delete consultation: {$consultation->id}");
            }

            $bar->advance();
        }

        $bar->finish();
        $this->newLine(2);

        // Summary
        $this->info('Cleanup Summary:');
        $this->table(
            ['Item', 'Count'],
            [
                ['Consultations processed', $consultations->count()],
                ['Consultations deleted', $deletedConsultations],
                ['Images deleted', $deletedImages],
                ['Failed image deletions', $failedImages],
            ]
        );

        if ($dryRun) {
            $this->warn('This was a DRY RUN. No data was actually deleted.');
            $this->info('Run without --dry-run to perform actual cleanup.');
        } else {
            $this->info('Cleanup completed successfully!');
        }

        return Command::SUCCESS;
    }
}
