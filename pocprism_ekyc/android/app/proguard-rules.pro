# ML Kit — keep all text recognition language models
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }

# ML Kit — general
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# BouncyCastle — prevent R8 from stripping crypto classes
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# libjeid
-keep class jp.co.osstech.** { *; }
-dontwarn jp.co.osstech.**