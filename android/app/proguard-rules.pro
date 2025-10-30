# SOUP Rewards App - ProGuard Rules
# リリースビルド時のコード難読化・最適化設定

## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

## Gson (JSON シリアライゼーション)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## データモデルクラス（必要に応じて追加）
-keep class com.kanamurayusaku.soup_rewards.models.** { *; }

## OkHttp / Retrofit
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

## Kotlin Coroutines
-keepclassmembernames class kotlinx.** { volatile <fields>; }

## R8 フル最適化
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose

## デバッグ情報保持（スタックトレース用）
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
