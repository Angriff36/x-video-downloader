# Flutter / Dart core
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.app.** { *; }

# MethodChannel related reflection (keep public classes & methods)
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keepclassmembers class ** {
    @io.flutter.plugin.common.MethodChannel$MethodCallHandler <methods>;
}

# Keep plugin packages used
-keep class dev.fluttercommunity.plus.androidintent.** { *; }
-keep class com.angriff.x_video_downloader.** { *; }

# Avoid stripping enums
-keepclassmembers enum * { *; }

# Do not warn on generated classes
-dontwarn io.flutter.embedding.**
-dontwarn dev.fluttercommunity.plus.androidintent.**

# Optimize but keep line numbers for stack traces
-keepattributes SourceFile,LineNumberTable

# Retain native library loader code
-keep class **.Native* { *; }

# Allow obfuscation of everything else
