<?php

namespace Tests\Feature\AI;

use App\Http\Requests\AI\CreateConsultationRequest;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class CreateConsultationRequestTest extends TestCase
{
    /**
     * Create a valid base64 encoded image for testing.
     */
    private function createValidBase64Image(int $sizeKb = 500): string
    {
        // Calculate dimensions to achieve target size
        $targetBytes = $sizeKb * 1024;
        $pixelsNeeded = $targetBytes / 4;
        $dimension = (int) sqrt($pixelsNeeded);
        
        $width = max($dimension, 400);
        $height = max($dimension, 400);
        
        $image = imagecreatetruecolor($width, $height);
        
        // Fill with random colors to prevent compression
        for ($x = 0; $x < $width; $x += 10) {
            for ($y = 0; $y < $height; $y += 10) {
                $color = imagecolorallocate($image, rand(0, 255), rand(0, 255), rand(0, 255));
                imagefilledrectangle($image, $x, $y, $x + 10, $y + 10, $color);
            }
        }
        
        ob_start();
        imagepng($image, null, 0);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        return base64_encode($imageData);
    }

    /**
     * Create valid marker data for testing.
     */
    private function createValidMarkers(): array
    {
        return [
            [
                'x' => 0.45,
                'y' => 0.32,
                'description' => 'Water leaking from pipe joint',
            ],
            [
                'x' => 0.67,
                'y' => 0.58,
                'description' => 'Rust visible on metal surface',
            ],
        ];
    }

    /**
     * Test that validation passes with valid data.
     */
    public function test_validation_passes_with_valid_data(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => $this->createValidMarkers(),
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that image is required.
     */
    public function test_image_is_required(): void
    {
        $data = [
            'markers' => $this->createValidMarkers(),
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('image', $validator->errors()->toArray());
        $this->assertEquals('An image is required to create a consultation.', $validator->errors()->first('image'));
    }

    /**
     * Test that markers are required.
     */
    public function test_markers_are_required(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('markers', $validator->errors()->toArray());
        $this->assertEquals('At least one defect marker is required.', $validator->errors()->first('markers'));
    }

    /**
     * Test that at least one marker is required.
     */
    public function test_at_least_one_marker_is_required(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('markers', $validator->errors()->toArray());
        $this->assertEquals('At least one defect marker is required.', $validator->errors()->first('markers'));
    }

    /**
     * Test that maximum 10 markers are allowed.
     */
    public function test_maximum_10_markers_allowed(): void
    {
        $markers = [];
        for ($i = 0; $i < 11; $i++) {
            $markers[] = [
                'x' => 0.5,
                'y' => 0.5,
                'description' => 'Marker ' . ($i + 1),
            ];
        }
        
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => $markers,
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('markers', $validator->errors()->toArray());
        $this->assertEquals('You cannot add more than 10 defect markers.', $validator->errors()->first('markers'));
    }

    /**
     * Test that marker X coordinate is required.
     */
    public function test_marker_x_coordinate_is_required(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'y' => 0.5,
                    'description' => 'Test marker',
                ],
            ],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('Each marker must have an X coordinate', $validator->errors()->first('markers.0.x'));
    }

    /**
     * Test that marker Y coordinate is required.
     */
    public function test_marker_y_coordinate_is_required(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'x' => 0.5,
                    'description' => 'Test marker',
                ],
            ],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('Each marker must have a Y coordinate', $validator->errors()->first('markers.0.y'));
    }

    /**
     * Test that marker coordinates must be between 0 and 1.
     */
    public function test_marker_coordinates_must_be_between_0_and_1(): void
    {
        // Test X coordinate > 1
        $data1 = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'x' => 1.5,
                    'y' => 0.5,
                    'description' => 'Test marker',
                ],
            ],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator1 = Validator::make(
            $data1,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator1->fails());
        $this->assertStringContainsString('between 0 and 1', $validator1->errors()->first('markers.0.x'));
        
        // Test Y coordinate < 0
        $data2 = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'x' => 0.5,
                    'y' => -0.1,
                    'description' => 'Test marker',
                ],
            ],
        ];
        
        $validator2 = Validator::make(
            $data2,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator2->fails());
        $this->assertStringContainsString('between 0 and 1', $validator2->errors()->first('markers.0.y'));
    }

    /**
     * Test that marker description is required.
     */
    public function test_marker_description_is_required(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'x' => 0.5,
                    'y' => 0.5,
                ],
            ],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('Each marker must have a description', $validator->errors()->first('markers.0.description'));
    }

    /**
     * Test that marker description must be at least 2 characters.
     */
    public function test_marker_description_minimum_length(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'A',
                ],
            ],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('at least 2 characters', $validator->errors()->first('markers.0.description'));
    }

    /**
     * Test that marker description cannot exceed 500 characters.
     */
    public function test_marker_description_maximum_length(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => str_repeat('A', 501),
                ],
            ],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules(),
            $request->messages()
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('cannot exceed 500 characters', $validator->errors()->first('markers.0.description'));
    }

    /**
     * Test that validation accepts exactly 10 markers.
     */
    public function test_validation_accepts_exactly_10_markers(): void
    {
        $markers = [];
        for ($i = 0; $i < 10; $i++) {
            $markers[] = [
                'x' => 0.5,
                'y' => 0.5,
                'description' => 'Marker ' . ($i + 1),
            ];
        }
        
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => $markers,
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules()
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that validation accepts boundary coordinate values.
     */
    public function test_validation_accepts_boundary_coordinate_values(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'x' => 0.0,
                    'y' => 0.0,
                    'description' => 'Top left corner',
                ],
                [
                    'x' => 1.0,
                    'y' => 1.0,
                    'description' => 'Bottom right corner',
                ],
            ],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules()
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that validation accepts description with exactly 500 characters.
     */
    public function test_validation_accepts_description_with_exactly_500_characters(): void
    {
        $data = [
            'image' => $this->createValidBase64Image(500),
            'markers' => [
                [
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => str_repeat('A', 500),
                ],
            ],
        ];
        
        $request = new CreateConsultationRequest();
        
        $validator = Validator::make(
            $data,
            $request->rules()
        );
        
        $this->assertFalse($validator->fails());
    }
}
