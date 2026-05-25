<?php

namespace Tests\Feature;

use App\Services\NodemailerService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NodemailerServiceTest extends TestCase
{
    /**
     * Test that NodemailerService can be instantiated
     */
    public function test_nodemailer_service_can_be_instantiated(): void
    {
        $service = new NodemailerService();
        $this->assertInstanceOf(NodemailerService::class, $service);
    }

    /**
     * Test that send-email.js script exists
     */
    public function test_send_email_script_exists(): void
    {
        $scriptPath = base_path('scripts/send-email.js');
        $this->assertFileExists($scriptPath);
    }

    /**
     * Test that email templates exist
     */
    public function test_email_templates_exist(): void
    {
        $templates = [
            'otp-verification',
            'welcome',
            'password-reset',
            'password-changed',
        ];

        foreach ($templates as $template) {
            $templatePath = resource_path("views/emails/{$template}.blade.php");
            $this->assertFileExists($templatePath, "Email template {$template} does not exist");
        }
    }

    /**
     * Test that NodemailerService validates email addresses
     */
    public function test_nodemailer_service_validates_email_addresses(): void
    {
        $service = new NodemailerService();

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Invalid recipient email address');

        $service->sendEmail(
            'invalid-email',
            'Test Subject',
            '<p>Test HTML</p>'
        );
    }

    /**
     * Test that NodemailerService validates subject
     */
    public function test_nodemailer_service_validates_subject(): void
    {
        $service = new NodemailerService();

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Email subject cannot be empty');

        $service->sendEmail(
            'test@example.com',
            '',
            '<p>Test HTML</p>'
        );
    }

    /**
     * Test that NodemailerService validates HTML content
     */
    public function test_nodemailer_service_validates_html_content(): void
    {
        $service = new NodemailerService();

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Email HTML content cannot be empty');

        $service->sendEmail(
            'test@example.com',
            'Test Subject',
            ''
        );
    }

    /**
     * Test that package.json exists and has nodemailer dependency
     */
    public function test_package_json_has_nodemailer_dependency(): void
    {
        $packageJsonPath = base_path('package.json');
        $this->assertFileExists($packageJsonPath);

        $packageJson = json_decode(file_get_contents($packageJsonPath), true);
        $this->assertArrayHasKey('dependencies', $packageJson);
        $this->assertArrayHasKey('nodemailer', $packageJson['dependencies']);
    }

    /**
     * Test that SMTP configuration is available in environment
     */
    public function test_smtp_configuration_is_available(): void
    {
        $this->assertNotEmpty(env('MAIL_HOST'), 'MAIL_HOST is not configured');
        $this->assertNotEmpty(env('MAIL_PORT'), 'MAIL_PORT is not configured');
        $this->assertNotEmpty(env('MAIL_FROM_ADDRESS'), 'MAIL_FROM_ADDRESS is not configured');
    }
}
