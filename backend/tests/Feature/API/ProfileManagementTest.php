<?php

namespace Tests\Feature\API;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class ProfileManagementTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test authenticated user can get their profile
     */
    public function test_authenticated_user_can_get_profile()
    {
        // Create a user
        $user = User::factory()->create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'role' => 'customer',
            'phone_number' => '1234567890',
        ]);

        // Authenticate as the user
        $this->actingAs($user);

        // Make request
        $response = $this->getJson('/api/v1/profile');

        // Assert response
        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Profile retrieved successfully',
                'data' => [
                    'id' => $user->id,
                    'name' => 'John Doe',
                    'email' => 'john@example.com',
                    'role' => 'customer',
                    'phone_number' => '1234567890',
                ],
            ]);
    }

    /**
     * Test unauthenticated user cannot get profile
     */
    public function test_unauthenticated_user_cannot_get_profile()
    {
        $response = $this->getJson('/api/v1/profile');

        $response->assertStatus(401);
    }

    /**
     * Test authenticated user can update their profile
     */
    public function test_authenticated_user_can_update_profile()
    {
        // Create a user
        $user = User::factory()->create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'phone_number' => '1234567890',
        ]);

        // Authenticate as the user
        $this->actingAs($user);

        // Update data
        $updateData = [
            'name' => 'Jane Doe',
            'phone_number' => '9876543210',
            'address' => '123 Main St, City',
        ];

        // Make request
        $response = $this->putJson('/api/v1/profile', $updateData);

        // Assert response
        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Profile updated successfully',
                'data' => [
                    'name' => 'Jane Doe',
                    'phone_number' => '9876543210',
                ],
            ]);

        // Assert database was updated
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Jane Doe',
            'phone_number' => '9876543210',
        ]);

        // Assert address was stored in metadata
        $user->refresh();
        $this->assertEquals('123 Main St, City', $user->metadata['address']);
    }

    /**
     * Test profile update validation - name too long
     */
    public function test_profile_update_fails_with_invalid_name()
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        $response = $this->putJson('/api/v1/profile', [
            'name' => str_repeat('a', 256), // 256 characters, exceeds max 255
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    /**
     * Test profile update validation - phone number too long
     */
    public function test_profile_update_fails_with_invalid_phone()
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        $response = $this->putJson('/api/v1/profile', [
            'phone_number' => str_repeat('1', 21), // 21 characters, exceeds max 20
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['phone_number']);
    }

    /**
     * Test profile update validation - address too long
     */
    public function test_profile_update_fails_with_invalid_address()
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        $response = $this->putJson('/api/v1/profile', [
            'address' => str_repeat('a', 501), // 501 characters, exceeds max 500
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['address']);
    }

    /**
     * Test authenticated user can upload profile image
     */
    public function test_authenticated_user_can_upload_profile_image()
    {
        Storage::fake('public');

        // Create a user
        $user = User::factory()->create();
        $this->actingAs($user);

        // Create a fake image
        $image = UploadedFile::fake()->image('profile.jpg', 600, 600);

        // Make request
        $response = $this->postJson('/api/v1/profile/image', [
            'image' => $image,
        ]);

        // Assert response
        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Profile image uploaded successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'image_url',
                    'path',
                ],
            ]);

        // Assert file was stored
        $user->refresh();
        Storage::disk('public')->assertExists($user->profile_image_url);
    }

    /**
     * Test profile image upload validation - missing image
     */
    public function test_profile_image_upload_fails_without_image()
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        $response = $this->postJson('/api/v1/profile/image', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['image']);
    }

    /**
     * Test profile image upload validation - invalid file type
     */
    public function test_profile_image_upload_fails_with_invalid_file_type()
    {
        Storage::fake('public');

        $user = User::factory()->create();
        $this->actingAs($user);

        // Create a fake PDF file
        $file = UploadedFile::fake()->create('document.pdf', 100);

        $response = $this->postJson('/api/v1/profile/image', [
            'image' => $file,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['image']);
    }

    /**
     * Test profile image upload validation - file too large
     */
    public function test_profile_image_upload_fails_with_large_file()
    {
        Storage::fake('public');

        $user = User::factory()->create();
        $this->actingAs($user);

        // Create a fake image larger than 2MB
        $image = UploadedFile::fake()->image('large.jpg')->size(3000);

        $response = $this->postJson('/api/v1/profile/image', [
            'image' => $image,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['image']);
    }

    /**
     * Test old profile image is deleted when uploading new one
     */
    public function test_old_profile_image_is_deleted_when_uploading_new_one()
    {
        Storage::fake('public');

        // Create a user with existing profile image
        $user = User::factory()->create();
        $this->actingAs($user);

        // Upload first image
        $firstImage = UploadedFile::fake()->image('first.jpg');
        $this->postJson('/api/v1/profile/image', ['image' => $firstImage]);

        $user->refresh();
        $firstImagePath = $user->profile_image_url;

        // Assert first image exists
        Storage::disk('public')->assertExists($firstImagePath);

        // Upload second image
        $secondImage = UploadedFile::fake()->image('second.jpg');
        $this->postJson('/api/v1/profile/image', ['image' => $secondImage]);

        $user->refresh();
        $secondImagePath = $user->profile_image_url;

        // Assert first image was deleted
        Storage::disk('public')->assertMissing($firstImagePath);

        // Assert second image exists
        Storage::disk('public')->assertExists($secondImagePath);
    }
}
