#!/bin/bash
# Gharsewa Backend Setup Script
# Run this inside the Docker container to initialize Laravel

echo "🚀 Setting up Gharsewa Backend..."

# Create Laravel project
composer create-project laravel/laravel . --prefer-dist

# Install required packages
echo "📦 Installing packages..."
composer require \
    kreait/laravel-firebase \
    beyondcode/laravel-websockets \
    predis/predis \
    spatie/laravel-permission \
    tymon/jwt-auth \
    stripe/stripe-php \
    twilio/sdk \
    openai-php/laravel

# Copy env file
cp .env.example .env

# Generate app key
php artisan key:generate

# Run migrations
php artisan migrate

# Publish configs
php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="migrations"
php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="config"
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"

echo "✅ Backend setup complete!"
