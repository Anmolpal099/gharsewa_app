# Firebase Authentication Setup Guide

## Overview

This project uses **Firebase Authentication** for:
- ✅ Real-time token generation
- ✅ Automatic token validation
- ✅ Token refresh handling
- ✅ Multi-platform support (Android, iOS, Web)
 Role-based authentication (Customer, Service Provider, Admin)

## Prerequisites

1. Firebase account
2. Firebase project created
3. Firebase CLI installed (optional but recommended)

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
Visit: https://console.firebase.google.com/

### 1.2 Create New Project
1. Click "Add project"
2. Enter project name: `gharsewa-dev` (for development)
3. Enable Google Analytics (recommended)
4. Click "Create project"

### 1.3 Create Additional Projects (Optional)
- `gharsewa-staging` - For staging environment
- `gharsewa-prod` - For production environment

## Step 2: Enable Authentication Methods

### 2.1 Navigate to Authentication
1. In Firebase Console, select your project
2. Click "Authentication" in the left sidebar
3. Click "Get started"

### 2.2 Enable Sign-in Methods
Enable the following methods:

#### Email/Password (Required)
1. Click "Email/Password"
2. Toggle "Enable"
3. Click "Save"

#### Google Sign-In (Optional)
1. Click "Google"
2. Toggle "Enable"
3. Enter support email
4. Click "Save"

#### Phone Authentication (Optional)
1. Click "Phone"
2. Toggle "Enable"
3. Click "Save"

## Step 3: Add Apps to Firebase Project

### 3.1 Add Android App

1. Click the Android icon in Project Overview
2. Enter package name: `com.gharsewa.app`
3. Enter app nickname: `Gharsewa Android`
4. Click "Register app"
5. Download `google-services.json`
6. Place it in: `android/app/google-services.json`

### 3.2 Add iOS App

1. Click the iOS icon in Project Overview
2. Enter bundle ID: `com.gharsewa.app`
3. Enter app nickname: `Gharsewa iOS`
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Place it in: `ios/Runner/GoogleService-Info.plist`

### 3.3 Add Web App

1. Click the Web icon in Project Overview
2. Enter app nickname: `Gharsewa Web`
3. Check "Also set up Firebase Hosting"
4. Click "Register app"
5. Copy the Firebase configuration

## Step 4: Configure Environment Files

### 4.1 Get Firebase Configuration

From Firebase Console → Project Settings → General:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "gharsewa-dev.firebaseapp.com",
  projectId: "gharsewa-dev",
  storageBucket: "gharsewa-dev.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123",
  databaseURL: "https://gharsewa-dev.firebaseio.com"
};
```

### 4.2 Update .env.dev

```env
# Firebase Configuration (Development)
FIREBASE_API_KEY=AIzaSy...
FIREBASE_APP_ID=1:123456789:web:abc123
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_PROJECT_ID=gharsewa-dev
FIREBASE_STORAGE_BUCKET=gharsewa-dev.appspot.com
FIREBASE_AUTH_DOMAIN=gharsewa-dev.firebaseapp.com
FIREBASE_DATABASE_URL=https://gharsewa-dev.firebaseio.com

# Firebase Authentication Settings
FIREBASE_AUTH_ENABLED=true
FIREBASE_TOKEN_REFRESH_INTERVAL=3600
```

### 4.3 Repeat for Staging and Production

Update `.env.staging` and `.env.prod` with their respective Firebase configurations.

## Step 5: Configure Android

### 5.1 Update android/build.gradle

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 5.2 Update android/app/build.gradle

Add at the bottom of the file:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### 5.3 Update AndroidManifest.xml

Add internet permission:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Step 6: Configure iOS

### 6.1 Open Xcode

```bash
open ios/Runner.xcworkspace
```

### 6.2 Add GoogleService-Info.plist

1. Drag `GoogleService-Info.plist` into Runner folder in Xcode
2. Ensure "Copy items if needed" is checked
3. Select Runner target

### 6.3 Update Info.plist

Add URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

## Step 7: Configure Web

### 7.1 Update web/index.html

Add Firebase SDK before `</body>`:

```html
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-auth-compat.js"></script>
<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  firebase.initializeApp(firebaseConfig);
</script>
```

## Step 8: Install Dependencies

```bash
flutter pub get
```

## Step 9: Initialize Firebase in App

### 9.1 Update lib/main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:gharsewa/core/config/firebase_config.dart';
import 'package:gharsewa/core/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Print environment configuration
  EnvConfig.printConfig();
  
  // Initialize Firebase
  await FirebaseConfig.initialize();
  
  runApp(const MyApp());
}
```

## Step 10: Set Up Custom Claims for Roles

### 10.1 Create Cloud Function

Create `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Set custom claims for user roles
exports.setUserRole = functions.https.onCall(async (data, context) => {
  // Check if request is made by an admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can set user roles'
    );
  }

  const { uid, role } = data;
  
  // Validate role
  const validRoles = ['customer', 'serviceProvider', 'admin'];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid role specified'
    );
  }

  // Set custom claims
  await admin.auth().setCustomUserClaims(uid, { role });
  
  return { message: `Role ${role} set for user ${uid}` };
});

// Automatically set 'customer' role for new users
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  await admin.auth().setCustomUserClaims(user.uid, { role: 'customer' });
  return null;
});
```

### 10.2 Deploy Cloud Functions

```bash
firebase deploy --only functions
```

## Step 11: Test Authentication

### 11.1 Run the App

```bash
flutter run --dart-define-from-file=.env.dev
```

### 11.2 Test Sign Up

Create a test user through your app or Firebase Console.

### 11.3 Verify Token

Check that Firebase generates and validates tokens automatically.

## Authentication Flow

### 1. User Sign Up/Sign In
```dart
import 'package:firebase_auth/firebase_auth.dart';

// Sign up
final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Sign in
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

### 2. Get ID Token (Automatic)
```dart
final user = FirebaseAuth.instance.currentUser;
final idToken = await user?.getIdToken();
```

### 3. Token Refresh (Automatic)
Firebase automatically refreshes tokens every hour.

### 4. Validate Token (Backend)
```javascript
// In your Laravel backend
const admin = require('firebase-admin');

async function verifyToken(idToken) {
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    throw new Error('Invalid token');
  }
}
```

### 5. Get User Role
```dart
final user = FirebaseAuth.instance.currentUser;
final idTokenResult = await user?.getIdTokenResult();
final role = idTokenResult?.claims?['role'];
```

## Security Rules

### Firestore Rules (if using Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check user role
    function hasRole(role) {
      return request.auth != null && request.auth.token.role == role;
    }
    
    // Customers can read/write their own data
    match /customers/{userId} {
      allow read, write: if request.auth.uid == userId || hasRole('admin');
    }
    
    // Service providers can read/write their own data
    match /providers/{userId} {
      allow read, write: if request.auth.uid == userId || hasRole('admin');
    }
    
    // Only admins can access admin data
    match /admin/{document=**} {
      allow read, write: if hasRole('admin');
    }
  }
}
```

## Troubleshooting

### Issue: Firebase not initialized

**Solution:** Ensure `FirebaseConfig.initialize()` is called before `runApp()`.

### Issue: google-services.json not found

**Solution:** Verify the file is in `android/app/` directory.

### Issue: Token expired

**Solution:** Firebase automatically refreshes tokens. Ensure you're using the latest token:

```dart
final token = await user?.getIdToken(true); // Force refresh
```

### Issue: Custom claims not working

**Solution:** 
1. Verify Cloud Functions are deployed
2. Check that claims are set correctly
3. Force token refresh after setting claims

## Best Practices

1. **Never expose Firebase config in public repos** - Use environment variables
2. **Use custom claims for roles** - Don't store roles in Firestore
3. **Validate tokens on backend** - Always verify tokens server-side
4. **Handle token refresh** - Firebase does this automatically
5. **Use security rules** - Protect your data with proper Firestore rules
6. **Monitor authentication** - Use Firebase Console to monitor auth activity

## Resources

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Flutter Firebase Setup](https://firebase.google.com/docs/flutter/setup)
- [Custom Claims](https://firebase.google.com/docs/auth/admin/custom-claims)
- [Security Rules](https://firebase.google.com/docs/rules)

---

**Last Updated:** 2026-05-20
