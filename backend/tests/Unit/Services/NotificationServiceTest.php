<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Models\User;
use App\Models\Notification;
use App\Services\Notification\NotificationService;
use App\Services\AI\SmartNotificationService;
use App\Events\NotificationCreated;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Mockery;

class NotificationServiceTest extends TestCase
{
    use RefreshDatabase;

    protected NotificationService $service;
    protected $smartNotificationService;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Mock the SmartNotificationService
        $this->smartNotificationService = Mockery::mock(SmartNotificationService::class);
        $this->service = new NotificationService($this->smartNotificationService);
    }

    /** @test */
    public function it_creates_notification_and_dispatches_event_when_sending_notification()
    {
        Event::fake([NotificationCreated::class]);

        $user = User::factory()->create();
        
        $notificationData = [
            'title' => 'Test Notification',
            'message' => 'This is a test notification',
            'data' => ['key' => 'value']
        ];

        $result = $this->service->sendNotification($user, 'test_type', $notificationData);

        // Assert notification was sent successfully
        $this->assertTrue($result);

        // Assert notification was created in database
        $this->assertDatabaseHas('notifications', [
            'user_id' => $user->id,
            'type' => 'test_type',
            'title' => 'Test Notification',
            'body' => 'This is a test notification',
            'is_read' => false,
        ]);

        // Assert NotificationCreated event was dispatched
        Event::assertDispatched(NotificationCreated::class, function ($event) use ($user) {
            return $event->notification->user_id === $user->id
                && $event->notification->type === 'test_type'
                && $event->notification->title === 'Test Notification';
        });
    }

    /** @test */
    public function it_dispatches_event_within_100ms_of_notification_creation()
    {
        Event::fake([NotificationCreated::class]);

        $user = User::factory()->create();
        
        $notificationData = [
            'title' => 'Performance Test',
            'body' => 'Testing event dispatch timing'
        ];

        $startTime = microtime(true);
        $this->service->sendNotification($user, 'performance_test', $notificationData);
        $endTime = microtime(true);

        $executionTime = ($endTime - $startTime) * 1000; // Convert to milliseconds

        // Assert event was dispatched
        Event::assertDispatched(NotificationCreated::class);

        // Assert execution time is within 100ms (requirement 4.4)
        $this->assertLessThan(100, $executionTime, 
            "Notification creation and event dispatch took {$executionTime}ms, which exceeds the 100ms requirement");
    }

    /** @test */
    public function it_uses_default_title_when_not_provided()
    {
        Event::fake([NotificationCreated::class]);

        $user = User::factory()->create();
        
        $notificationData = [
            'message' => 'Message without title'
        ];

        $this->service->sendNotification($user, 'test_type', $notificationData);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $user->id,
            'title' => 'Notification',
            'body' => 'Message without title',
        ]);
    }

    /** @test */
    public function it_handles_body_field_as_alternative_to_message()
    {
        Event::fake([NotificationCreated::class]);

        $user = User::factory()->create();
        
        $notificationData = [
            'title' => 'Test',
            'body' => 'Using body field instead of message'
        ];

        $this->service->sendNotification($user, 'test_type', $notificationData);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $user->id,
            'body' => 'Using body field instead of message',
        ]);
    }

    /** @test */
    public function it_returns_false_when_notification_creation_fails()
    {
        Event::fake([NotificationCreated::class]);

        // Create a user with invalid ID to trigger failure
        $user = new User();
        $user->id = 'invalid-uuid-that-does-not-exist';
        
        $notificationData = [
            'title' => 'Test',
            'message' => 'This should fail'
        ];

        $result = $this->service->sendNotification($user, 'test_type', $notificationData);

        // Assert notification sending failed
        $this->assertFalse($result);

        // Assert event was not dispatched
        Event::assertNotDispatched(NotificationCreated::class);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }
}
