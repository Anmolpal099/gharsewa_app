<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tymon\JWTAuth\Facades\JWTAuth;

class ProfileManagementTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $token;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a test user
        $this->user = User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'role' => 'customer',
            'phone_number' => '1234567890',
            'is_active' => true,
        ]);

        // Generate JWT token
        $this->token = JWTAuth::fromUser($this->user);
    }

    /** @test */
    public function it_can_get_user_profile()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson('/api/v1/profile');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Profile retrieved successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'id',
                    'name',
                    'email',
                    'role',
                    'phone_number',
                    'profile_image_url',
                    'is_active',
                    'email_verified_at',
                    'last_login_at',
                ],
            ]);

        $this->assertEquals($this->user->id, $response->json('data.id'));
        $this->assertEquals($this->user->name, $response->json('data.name'));
        $this->assertEquals($this->user->email, $response->json('data.email'));
    }

    /** @test */
    public function it_requires_authentication_to_get_profile()
    {
        $response = $this->getJson('/api/v1/profile');

        $response->assertStatus(401);
    }

    /** @test */
    public function it_can_update_user_profile()
    {
        $updateData = [
            'name' => 'Updated Name',
            'phone_number' => '9876543210',
            'address' => '123 Test Street',
        ];

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->putJson('/api/v1/profile', $updateData);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Profile updated successfully',
            ]);

        // Verify database was updated
        $this->user->refresh();
        $this->assertEquals('Updated Name', $this->user->name);
        $this->assertEquals('9876543210', $this->user->phone_number);
        $this->assertEquals('123 Test Street', $this->user->metadata['address'] ?? null);
    }

    /** @test */
    public function it_can_update_partial_profile_fields()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->putJson('/api/v1/profile', [
            'name' => 'Only Name Updated',
        ]);

        $response->assertStatus(200);

        $this->user->refresh();
        $this->assertEquals('Only Name Updated', $this->user->name);
        $this->assertEquals('1234567890', $this->user->phone_number); // Unchanged
    }

    /** @test */
    public function it_validates_profile_update_data()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->putJson('/api/v1/profile', [
            'name' => str_repeat('a', 256), // Too long
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed',
            ]);
    }

    /** @test */
    public function it_can_upload_profile_image()
    {
        Storage::fake('public');

        $file = UploadedFile::fake()->image('profile.jpg', 500, 500)->size(1024); // 1MB

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson('/api/v1/profile/image', [
            'image' => $file,
        ]);

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

        // Verify file was stored
        $path = $response->json('data.path');
        Storage::disk('public')->assertExists($path);

        // Verify user record was updated
        $this->user->refresh();
        $this->assertEquals($path, $this->user->profile_image_url);
    }

    /** @test */
    public function it_deletes_old_profile_image_when_uploading_new_one()
    {
        Storage::fake('public');

        // Upload first image
        $oldFile = UploadedFile::fake()->image('old.jpg');
        $oldPath = $oldFile->store('profile-images', 'public');
        $this->user->update(['profile_image_url' => $oldPath]);

        // Upload new image
        $newFile = UploadedFile::fake()->image('new.jpg');
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson('/api/v1/profile/image', [
            'image' => $newFile,
        ]);

        $response->assertStatus(200);

        // Verify old image was deleted
        Storage::disk('public')->assertMissing($oldPath);

        // Verify new image exists
        $newPath = $response->json('data.path');
        Storage::disk('public')->assertExists($newPath);
    }

    /** @test */
    public function it_validates_profile_image_upload()
    {
        Storage::fake('public');

        // Test missing image
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson('/api/v1/profile/image', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['image']);

        // Test invalid file type
        $file = UploadedFile::fake()->create('document.pdf', 1024);
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson('/api/v1/profile/image', [
            'image' => $file,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['image']);

        // Test file too large (over 2MB)
        $file = UploadedFile::fake()->image('large.jpg')->size(3000); // 3MB
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson('/api/v1/profile/image', [
            'image' => $file,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['image']);
    }

    /** @test */
    public function it_accepts_valid_image_formats()
    {
        Storage::fake('public');

        $formats = ['jpg', 'jpeg', 'png'];

        foreach ($formats as $format) {
            $file = UploadedFile::fake()->image("profile.{$format}");
            
            $response = $this->withHeaders([
                'Authorization' => 'Bearer ' . $this->token,
            ])->postJson('/api/v1/profile/image', [
                'image' => $file,
            ]);

            $response->assertStatus(200);
        }
    }

    /** @test */
    public function it_requires_authentication_to_update_profile()
    {
        $response = $this->putJson('/api/v1/profile', [
            'name' => 'Test',
        ]);

        $response->assertStatus(401);
    }

    /** @test */
    public function it_requires_authentication_to_upload_image()
    {
        Storage::fake('public');

        $file = UploadedFile::fake()->image('profile.jpg');
        
        $response = $this->postJson('/api/v1/profile/image', [
            'image' => $file,
        ]);

        $response->assertStatus(401);
    }

    /** @test */
    public function profile_works_for_all_user_roles()
    {
        $roles = ['customer', 'serviceProvider', 'admin'];

        foreach ($roles as $role) {
            $user = User::factory()->create(['role' => $role]);
            $token = JWTAuth::fromUser($user);

            $response = $this->withHeaders([
                'Authorization' => 'Bearer ' . $token,
            ])->getJson('/api/v1/profile');

            $response->assertStatus(200)
                ->assertJson([
                    'success' => true,
                    'data' => [
                        'role' => $role,
                    ],
                ]);
        }
    }
}
