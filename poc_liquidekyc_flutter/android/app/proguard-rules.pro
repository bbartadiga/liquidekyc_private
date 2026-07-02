# ProGuard rules for Liquid SDK eKYC
# Exclude ML/LiteRT models that cause errors in demo mode

# Exclude LiquidPluginMl (ML Kit / LiteRT)
-keep class asia.liquidinc.ekyc.plugin.** { *; }
-dontwarn asia.liquidinc.ekyc.plugin.**

# Exclude ML Kit classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_vision.**

# Exclude LiteRT classes
-keep class com.google.ai.edge.litert.** { *; }
-dontwarn com.google.ai.edge.litert.**
-dontwarn org.tensorflow.lite.**

# Exclude TensorFlow Lite models
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Keep Liquid SDK core classes
-keep class asia.liquidinc.ekyc.applicant.** { *; }
-keep class asia.liquidinc.ekyc.sdk.** { *; }

# Keep Flutter plugin
-keep class com.example.poc_liquidekyc_flutter.plugins.** { *; }

# Print warnings for excluded classes
-printmapping proguard-mapping.txt
-dontwarn !asia.liquidinc.ekyc.plugin.**
-dontwarn !com.google.mlkit.**
-dontwarn !com.google.ai.edge.litert.**
-dontwarn !org.tensorflow.lite.**