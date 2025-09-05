# Flutter-specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# General rules for ML Kit Vision
-keep public class com.google.mlkit.** {*;}
-keep public class com.google.android.gms.vision.** {*;}

# Keep models and internal classes to prevent them from being removed by R8
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** {*;}
-keep class com.google.android.gms.internal.mlkit_vision_text.** {*;}

# Keep specific language recognizer options that were being stripped
-keep class com.google.mlkit.vision.text.chinese.** {*;}
-keep class com.google.mlkit.vision.text.devanagari.** {*;}
-keep class com.google.mlkit.vision.text.japanese.** {*;}
-keep class com.google.mlkit.vision.text.korean.** {*;}

# Keep Google Play Core classes required by ML Kit for dynamic features
-keep class com.google.android.play.core.splitcompat.** {*;}
-keep class com.google.android.play.core.splitinstall.** {*;}
-keep class com.google.android.play.core.tasks.** {*;}

