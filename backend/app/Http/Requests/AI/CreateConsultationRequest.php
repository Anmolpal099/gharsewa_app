<?php

namespace App\Http\Requests\AI;

use App\Rules\Base64Image;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class CreateConsultationRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Only authenticated users can create consultations
        return $this->user() !== null;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'image' => [
                'required',
                'string',
                new Base64Image(maxSizeKb: 10240),
            ],
            'markers' => [
                'required',
                'array',
                'min:1',
                'max:10',
            ],
            'markers.*.x' => [
                'required',
                'numeric',
                'between:0,1',
            ],
            'markers.*.y' => [
                'required',
                'numeric',
                'between:0,1',
            ],
            'markers.*.description' => [
                'required',
                'string',
                'min:2',
                'max:500',
            ],
        ];
    }

    /**
     * Get custom error messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            // Image validation messages
            'image.required' => 'An image is required to create a consultation.',
            'image.string' => 'The image must be a valid base64 encoded string.',
            
            // Markers array validation messages
            'markers.required' => 'At least one defect marker is required.',
            'markers.array' => 'Markers must be provided as an array.',
            'markers.min' => 'At least one defect marker is required.',
            'markers.max' => 'You cannot add more than 10 defect markers.',
            
            // Marker X coordinate validation messages
            'markers.*.x.required' => 'Each marker must have an X coordinate.',
            'markers.*.x.numeric' => 'Marker X coordinate must be a number.',
            'markers.*.x.between' => 'Marker X coordinate must be between 0 and 1.',
            
            // Marker Y coordinate validation messages
            'markers.*.y.required' => 'Each marker must have a Y coordinate.',
            'markers.*.y.numeric' => 'Marker Y coordinate must be a number.',
            'markers.*.y.between' => 'Marker Y coordinate must be between 0 and 1.',
            
            // Marker description validation messages
            'markers.*.description.required' => 'Each marker must have a description.',
            'markers.*.description.string' => 'Marker description must be text.',
            'markers.*.description.min' => 'Marker description must be at least 2 characters.',
            'markers.*.description.max' => 'Marker description cannot exceed 500 characters.',
        ];
    }

    /**
     * Get custom attributes for validator errors.
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'image' => 'image',
            'markers' => 'defect markers',
            'markers.*.x' => 'marker X coordinate',
            'markers.*.y' => 'marker Y coordinate',
            'markers.*.description' => 'marker description',
        ];
    }

    /**
     * Handle a failed validation attempt.
     *
     * @param Validator $validator
     * @throws HttpResponseException
     */
    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422)
        );
    }
}
