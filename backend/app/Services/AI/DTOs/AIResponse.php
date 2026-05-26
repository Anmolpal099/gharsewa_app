<?php

namespace App\Services\AI\DTOs;

use JsonSerializable;

class AIResponse implements JsonSerializable
{
    public function __construct(
        public readonly string $content,
        public readonly array $metadata,
        public readonly bool $success,
        public readonly ?string $error = null
    ) {}

    /**
     * Create a successful response
     *
     * @param string $content
     * @param array $metadata
     * @return self
     */
    public static function success(string $content, array $metadata = []): self
    {
        return new self(
            content: $content,
            metadata: $metadata,
            success: true,
            error: null
        );
    }

    /**
     * Create an error response
     *
     * @param string $error
     * @param array $metadata
     * @return self
     */
    public static function error(string $error, array $metadata = []): self
    {
        return new self(
            content: '',
            metadata: $metadata,
            success: false,
            error: $error
        );
    }

    /**
     * Create from array
     *
     * @param array $data
     * @return self
     */
    public static function fromArray(array $data): self
    {
        return new self(
            content: $data['content'] ?? '',
            metadata: $data['metadata'] ?? [],
            success: $data['success'] ?? false,
            error: $data['error'] ?? null
        );
    }

    /**
     * Check if response is successful
     *
     * @return bool
     */
    public function isSuccess(): bool
    {
        return $this->success;
    }

    /**
     * Check if response is an error
     *
     * @return bool
     */
    public function isError(): bool
    {
        return !$this->success;
    }

    /**
     * Get content or throw exception if error
     *
     * @return string
     * @throws \Exception
     */
    public function getContentOrFail(): string
    {
        if ($this->isError()) {
            throw new \Exception($this->error ?? 'Unknown AI error');
        }

        return $this->content;
    }

    /**
     * Get metadata value
     *
     * @param string $key
     * @param mixed $default
     * @return mixed
     */
    public function getMetadata(string $key, mixed $default = null): mixed
    {
        return $this->metadata[$key] ?? $default;
    }

    /**
     * Convert to array
     *
     * @return array
     */
    public function toArray(): array
    {
        return [
            'content' => $this->content,
            'metadata' => $this->metadata,
            'success' => $this->success,
            'error' => $this->error,
        ];
    }

    /**
     * Convert to JSON
     *
     * @return string
     */
    public function toJson(): string
    {
        return json_encode($this->toArray());
    }

    /**
     * JSON serialize
     *
     * @return array
     */
    public function jsonSerialize(): array
    {
        return $this->toArray();
    }

    /**
     * Validate response structure
     *
     * @return bool
     */
    public function validate(): bool
    {
        if ($this->isError()) {
            return !empty($this->error);
        }

        return !empty($this->content);
    }
}
