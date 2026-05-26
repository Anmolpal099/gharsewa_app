<?php

namespace App\Services\AI;

use Illuminate\Support\Facades\File;
use InvalidArgumentException;

class PromptBuilder
{
    private const TEMPLATE_PATH = 'resources/prompts';
    private const MAX_CONTEXT_LENGTH = 8000; // Conservative limit for context window

    private string $template = '';
    private array $variables = [];

    /**
     * Load template from file
     */
    public function loadTemplate(string $templateName): self
    {
        $templatePath = base_path(self::TEMPLATE_PATH . '/' . $templateName);

        if (!File::exists($templatePath)) {
            throw new InvalidArgumentException("Template not found: {$templateName}");
        }

        $this->template = File::get($templatePath);

        return $this;
    }

    /**
     * Set template content directly
     */
    public function setTemplate(string $template): self
    {
        $this->template = $template;

        return $this;
    }

    /**
     * Set a variable value
     */
    public function setVariable(string $key, mixed $value): self
    {
        $this->variables[$key] = $value;

        return $this;
    }

    /**
     * Set multiple variables at once
     */
    public function setVariables(array $variables): self
    {
        $this->variables = array_merge($this->variables, $variables);

        return $this;
    }

    /**
     * Build the final prompt with variable substitution
     */
    public function build(): string
    {
        $prompt = $this->template;

        // Replace variables in {{variable}} format
        foreach ($this->variables as $key => $value) {
            $placeholder = '{{' . $key . '}}';
            $replacement = $this->formatValue($value);
            $prompt = str_replace($placeholder, $replacement, $prompt);
        }

        // Validate prompt
        $this->validatePrompt($prompt);

        return $prompt;
    }

    /**
     * Format value for prompt insertion
     */
    private function formatValue(mixed $value): string
    {
        if (is_array($value) || is_object($value)) {
            return json_encode($value, JSON_PRETTY_PRINT);
        }

        if (is_bool($value)) {
            return $value ? 'true' : 'false';
        }

        if (is_null($value)) {
            return 'null';
        }

        return (string) $value;
    }

    /**
     * Validate the built prompt
     */
    private function validatePrompt(string $prompt): void
    {
        // Check for unreplaced variables
        if (preg_match('/\{\{[^}]+\}\}/', $prompt, $matches)) {
            throw new InvalidArgumentException(
                "Unreplaced variable found in prompt: {$matches[0]}"
            );
        }

        // Check context window limit
        $length = mb_strlen($prompt);
        if ($length > self::MAX_CONTEXT_LENGTH) {
            throw new InvalidArgumentException(
                "Prompt exceeds maximum context length: {$length} > " . self::MAX_CONTEXT_LENGTH
            );
        }
    }

    /**
     * Get current template
     */
    public function getTemplate(): string
    {
        return $this->template;
    }

    /**
     * Get current variables
     */
    public function getVariables(): array
    {
        return $this->variables;
    }

    /**
     * Reset builder state
     */
    public function reset(): self
    {
        $this->template = '';
        $this->variables = [];

        return $this;
    }

    /**
     * Create a new instance with a template
     */
    public static function fromTemplate(string $templateName): self
    {
        return (new self())->loadTemplate($templateName);
    }

    /**
     * Create a new instance with direct template content
     */
    public static function fromString(string $template): self
    {
        return (new self())->setTemplate($template);
    }
}
