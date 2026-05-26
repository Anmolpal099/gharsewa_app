<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\AI\AnalyticsService;
use Illuminate\Support\Facades\Log;
use Exception;

class GenerateAIAnalytics extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'ai:generate-analytics 
                            {--type= : Type of analytics to generate (booking_volume, revenue_forecast, churn_risk, trend, all)}
                            {--days=7 : Number of days for forecast}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate AI analytics predictions for the platform';

    protected AnalyticsService $analyticsService;

    /**
     * Create a new command instance.
     */
    public function __construct(AnalyticsService $analyticsService)
    {
        parent::__construct();
        $this->analyticsService = $analyticsService;
    }

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $type = $this->option('type') ?? 'all';
        $days = (int) $this->option('days');

        $this->info('Starting AI analytics generation...');
        $this->info("Type: {$type}");
        $this->info("Days: {$days}");
        $this->newLine();

        try {
            $results = [];

            // Generate booking volume prediction
            if ($type === 'all' || $type === 'booking_volume') {
                $this->info('Generating booking volume prediction...');
                $startTime = microtime(true);
                
                try {
                    $prediction = $this->analyticsService->predictBookingVolume($days);
                    $duration = round((microtime(true) - $startTime) * 1000);
                    
                    $this->line("✓ Booking volume prediction generated");
                    $this->line("  Confidence: {$prediction['confidence_score']}%");
                    $this->line("  Duration: {$duration}ms");
                    $results['booking_volume'] = 'success';
                } catch (Exception $e) {
                    $this->error("✗ Failed: {$e->getMessage()}");
                    $results['booking_volume'] = 'failed';
                }
                
                $this->newLine();
            }

            // Generate revenue forecast
            if ($type === 'all' || $type === 'revenue_forecast') {
                $this->info('Generating revenue forecast...');
                $startTime = microtime(true);
                
                try {
                    $prediction = $this->analyticsService->forecastRevenue($days);
                    $duration = round((microtime(true) - $startTime) * 1000);
                    
                    $this->line("✓ Revenue forecast generated");
                    $this->line("  Confidence: {$prediction['confidence_score']}%");
                    $this->line("  Duration: {$duration}ms");
                    $results['revenue_forecast'] = 'success';
                } catch (Exception $e) {
                    $this->error("✗ Failed: {$e->getMessage()}");
                    $results['revenue_forecast'] = 'failed';
                }
                
                $this->newLine();
            }

            // Generate churn risk prediction
            if ($type === 'all' || $type === 'churn_risk') {
                $this->info('Generating churn risk prediction...');
                $startTime = microtime(true);
                
                try {
                    $prediction = $this->analyticsService->predictChurnRisk();
                    $duration = round((microtime(true) - $startTime) * 1000);
                    
                    $atRiskCount = count($prediction['prediction_data'] ?? []);
                    $this->line("✓ Churn risk prediction generated");
                    $this->line("  At-risk users: {$atRiskCount}");
                    $this->line("  Confidence: {$prediction['confidence_score']}%");
                    $this->line("  Duration: {$duration}ms");
                    $results['churn_risk'] = 'success';
                } catch (Exception $e) {
                    $this->error("✗ Failed: {$e->getMessage()}");
                    $results['churn_risk'] = 'failed';
                }
                
                $this->newLine();
            }

            // Identify trends
            if ($type === 'all' || $type === 'trend') {
                $this->info('Identifying trends...');
                $startTime = microtime(true);
                
                try {
                    $prediction = $this->analyticsService->identifyTrends();
                    $duration = round((microtime(true) - $startTime) * 1000);
                    
                    $trendCount = count($prediction['prediction_data'] ?? []);
                    $this->line("✓ Trends identified");
                    $this->line("  Trends found: {$trendCount}");
                    $this->line("  Confidence: {$prediction['confidence_score']}%");
                    $this->line("  Duration: {$duration}ms");
                    $results['trend'] = 'success';
                } catch (Exception $e) {
                    $this->error("✗ Failed: {$e->getMessage()}");
                    $results['trend'] = 'failed';
                }
                
                $this->newLine();
            }

            // Summary
            $successCount = count(array_filter($results, fn($r) => $r === 'success'));
            $totalCount = count($results);
            
            $this->newLine();
            $this->info("Analytics generation completed!");
            $this->line("Success: {$successCount}/{$totalCount}");
            
            if ($successCount === $totalCount) {
                $this->info('All analytics generated successfully ✓');
                return Command::SUCCESS;
            } else {
                $this->warn('Some analytics failed to generate');
                return Command::FAILURE;
            }

        } catch (Exception $e) {
            $this->error('Analytics generation failed');
            $this->error($e->getMessage());
            
            Log::error('AI analytics generation command failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return Command::FAILURE;
        }
    }
}
