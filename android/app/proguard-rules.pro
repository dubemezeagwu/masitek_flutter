# flutter_blue_plus - prevent crashes in release builds
-keep class com.lib.flutter_blue_plus.* { *; }

# camera - prevent crashes in release builds (comprehensive rules for CameraX)
-keep class io.flutter.plugins.camera.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# CameraX core dependencies
-keep class androidx.camera.core.** { *; }
-keep class androidx.camera.camera2.** { *; }
-keep class androidx.camera.lifecycle.** { *; }
-keep class androidx.camera.video.** { *; }
-keep class androidx.camera.view.** { *; }

# Keep all native methods (camera uses JNI)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep camera metadata
-keep class androidx.camera.core.internal.compat.quirk.** { *; }
-keep class androidx.camera.camera2.internal.compat.quirk.** { *; }
