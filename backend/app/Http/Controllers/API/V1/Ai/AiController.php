<?php

namespace App\Http\Controllers\API\V1\Ai;

use App\Http\Controllers\API\V1\BaseController;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AiController extends BaseController
{
    /**
     * Generate a safety SOP for a job type.
     * POST /api/v1/ai/safety-sop
     */
    public function safetySop(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'job_type' => 'required|string|min:2|max:120',
            ]);

            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }

            $jobType = trim($request->input('job_type'));
            $sop = $this->buildSop($jobType);

            Log::info('Safety SOP generated', [
                'user_id' => auth()->id(),
                'job_type' => $jobType,
            ]);

            return $this->success($sop, 'Safety SOP generated successfully');
        } catch (\Exception $e) {
            Log::error('Failed to generate safety SOP', [
                'exception' => $e->getMessage(),
            ]);

            return $this->error('Failed to generate safety SOP. Please try again.', 500);
        }
    }

    private function buildSop(string $jobType): array
    {
        $hazards = [
            'Slip, trip, and fall hazards in the work area',
            'Exposure to electrical components (if applicable)',
            'Chemical, dust, or fume exposure',
            'Manual handling and ergonomic strain',
        ];

        $ppe = [
            'Safety gloves',
            'Safety goggles or face shield',
            'Closed-toe safety footwear',
            'Mask/respirator when dust or fumes are present',
        ];

        $procedures = [
            'Inspect the work area and remove obstacles before starting',
            'Verify tools and equipment are in safe working condition',
            'Follow manufacturer instructions for all products and equipment',
            'Keep walkways clear and cordon off the work zone if needed',
            'Communicate hazards to the customer before beginning work',
        ];

        $emergency = [
            'Stop work immediately if unsafe conditions appear',
            'Call local emergency services (100/101/102) for serious injury',
            'Notify the customer and platform support',
            'Document the incident and preserve the work area if required',
        ];

        $content = "# Safety SOP: {$jobType}\n\n"
            . "## Hazards\n- " . implode("\n- ", $hazards) . "\n\n"
            . "## Required PPE\n- " . implode("\n- ", $ppe) . "\n\n"
            . "## Procedures\n- " . implode("\n- ", $procedures) . "\n\n"
            . "## Emergency Protocols\n- " . implode("\n- ", $emergency);

        return [
            'id' => (string) Str::uuid(),
            'job_type' => $jobType,
            'content' => $content,
            'hazards' => $hazards,
            'required_ppe' => $ppe,
            'procedures' => $procedures,
            'emergency_protocols' => $emergency,
            'generated_at' => now()->toIso8601String(),
            'is_saved' => false,
        ];
    }
}
