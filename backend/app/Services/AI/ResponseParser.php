<?php

namespace App\Services\AI;

use Illuminate\Support\Facades\Log;
use JsonException;

class ResponseParser
{
    /**
     * Parse JSON response from AI
     */
    public function parseJson(string $response): ?array
    {
        try {
            // Try to extract JSON from response (AI might add extra text)
            $jsonString = $this->extractJson($response);

            if (empty($jsonString)) {
                Log::warning('No JSON found in AI response', ['response' => $response]);
                return null;
            }

            $data = json_decode($jsonString, true, 512, JSON_THROW_ON_ERROR);

            return $this->sanitizeData($data);
        } catch (JsonException $e) {
            Log::error('Failed to parse AI JSON response', [
                'response' => $response,
                'error' => $e->getMessage()
            ]);

            return null;
        }
    }

    /**
     * Extract JSON from response text
     */
    private function extractJson(string $response): ?string
    {
        // Try to find JSON object or array
        if (preg_match('/\{(?:[^{}]|(?R))*\}|\[(?:[^\[\]]|(?R))*\]/s', $response, $matches)) {
            return $matches[0];
        }

        // If response is already clean JSON
        $trimmed = trim($response);
        if (str_starts_with($trimmed, '{') || str_starts_with($trimmed, '[')) {
            return $trimmed;
        }

        return null;
    }

    /**
     * Sanitize parsed data
     */
    private function sanitizeData(mixed $data): mixed
    {
        if (is_array($data)) {
            return array_map([$this, 'sanitizeData'], $data);
        }

        if (is_string($data)) {
            // Remove potentially harmful content
            $data = strip_tags($data);
            $data = htmlspecialchars($data, ENT_QUOTES, 'UTF-8');
        }

        return $data;
    }

    /**
     * Validate response structure against expected schema
     */
    public function validate(array $data, array $requiredFields): bool
    {
        foreach ($requiredFields as $field) {
            if (!isset($data[$field])) {
                Log::warning('Missing required field in AI response', [
                    'field' => $field,
                    'data' => $data
                ]);
                return false;
            }
        }

        return true;
    }

    /**
     * Parse response with fallback
     */
    public function parseWithFallback(string $response, array $fallback = []): array
    {
        $parsed = $this->parseJson($response);

        if ($parsed === null) {
            Log::info('Using fallback data for malformed AI response');
            return $fallback;
        }

        return $parsed;
    }

    /**
     * Extract specific field from response
     */
    public function extractField(string $response, string $field, mixed $default = null): mixed
    {
        $data = $this->parseJson($response);

        if ($data === null) {
            return $default;
        }

        return $data[$field] ?? $default;
    }

    /**
     * Parse array of items from response
     */
    public function parseArray(string $response, string $arrayKey = null): array
    {
        $data = $this->parseJson($response);

        if ($data === null) {
            return [];
        }

        if ($arrayKey !== null) {
            return $data[$arrayKey] ?? [];
        }

        // If data is already an array, return it
        if (isset($data[0])) {
            return $data;
        }

        // Otherwise wrap in array
        return [$data];
    }

    /**
     * Clean and normalize text response
     */
    public function cleanText(string $response): string
    {
        // Remove extra whitespace
        $cleaned = preg_replace('/\s+/', ' ', $response);

        // Trim
        $cleaned = trim($cleaned);

        // Remove markdown formatting if present
        $cleaned = preg_replace('/[*_`#]/', '', $cleaned);

        return $cleaned;
    }

    /**
     * Extract confidence score from response
     */
    public function extractConfidence(string $response): ?float
    {
        $data = $this->parseJson($response);

        if ($data === null) {
            return null;
        }

        // Try common confidence field names
        $confidenceFields = ['confidence', 'confidence_score', 'score', 'probability'];

        foreach ($confidenceFields as $field) {
            if (isset($data[$field])) {
                return (float) $data[$field];
            }
        }

        return null;
    }
}
