<?php

namespace App\Services\Auth;

use App\Models\User;
use Kreait\Firebase\Auth as FirebaseAuth;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;
use Illuminate\Support\Str;

class FirebaseAuthService
{
    public function __construct(private FirebaseAuth $auth) {}

    /**
     * Verify Firebase ID token and sync user to database
     */
    public function loginWithFirebaseToken(string $idToken): User
    {
        $verifiedToken = $this->auth->verifyIdToken($idToken);

        $uid   = $verifiedToken->claims()->get('sub');
        $email = $verifiedToken->claims()->get('email');
        $role  = $verifiedToken->claims()->get('role', 'customer');

        // Sync user to local DB
        $user = User::updateOrCreate(
            ['firebase_uid' => $uid],
            [
                'email'         => $email,
                'role'          => $role,
                'last_login_at' => now(),
                'is_active'     => true,
            ]
        );

        return $user;
    }

    /**
     * Register new user and set custom claims
     */
    public function registerUser(string $idToken, string $name, string $role): User
    {
        $verifiedToken = $this->auth->verifyIdToken($idToken);

        $uid   = $verifiedToken->claims()->get('sub');
        $email = $verifiedToken->claims()->get('email');

        // Set custom claims (role) on Firebase
        $this->auth->setCustomUserClaims($uid, ['role' => $role]);

        // Create user in local DB
        $user = User::create([
            'id'           => Str::uuid(),
            'firebase_uid' => $uid,
            'email'        => $email,
            'name'         => $name,
            'role'         => $role,
            'is_active'    => true,
        ]);

        return $user;
    }

    /**
     * Verify token and return claims
     */
    public function verifyToken(string $idToken): array
    {
        $verifiedToken = $this->auth->verifyIdToken($idToken);

        return [
            'uid'   => $verifiedToken->claims()->get('sub'),
            'email' => $verifiedToken->claims()->get('email'),
            'role'  => $verifiedToken->claims()->get('role', 'customer'),
        ];
    }
}
