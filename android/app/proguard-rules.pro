# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Keep model classes
-keep class com.gharsewa.app.models.** { *; }

# Stripe
-keep class com.stripe.android.** { *; }

# Prevent obfuscation of classes used in reflection
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions
