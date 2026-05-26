<?php

namespace App\DTOs\AI;

use JsonSerializable;

class AIResponse implements JsonSerializable
{
    public function __construct(
        public readonly string $content,
        public readonly bool $success,
        public readonly ?string $error = null,
        public readonly array $metadata = []
    ) {}

    /**
     * Create a successful response
     */
    public static function success(string $content, array $metadata = []): self
    {
        return new self(
            content: $content,
            success: true,
            error: null,
            metadata: $metadata
        );
    }

    /**
     * Create a failed response
     */
    public static function failure(string $error, array $metadata = []): self
    {
        return new self(
            content: '',
            success: false,
            error: $error,
            metadata: $metadata
        );
    }

    /**
     * Check if response is valid and has content
     */
    public function isValid(): bool
    {
        return $this->success && !empty($this->content);
    }

    /**
     * Get response as array
     */
    public function toArray(): array
    {
        return [
            'content' => $this->content,
            'success' => $this->success,
            'error' => $this->error,
            'metadata' => $this->metadata,
        ];
    }

    /**
     * Get response as JSON
     */
    public function toJson(int $options = 0): string
    {
        return json_encode($this->toArray(), $options);
    }

    /**
     * JsonSerializable implementation
     */
    public function jsonSerialize(): array
    {
        return $this->toArray();
    }

    /**
     * Validate response structure
     */
    public function validate(): bool
    {
        if (!$this->success) {
            return !empty($this->error);
        }

        return !empty($this->content);
    }

    /**
     * Get metadata value by key
     */
    public function getMetadata(string $key, mixed $default = null): mixed
    {
        return $this->metadata[$key] ?? $default;
    }
}
