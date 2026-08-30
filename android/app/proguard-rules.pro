# Flutter embedding (n�o remover: R8 n�o v� uso reflexivo do engine)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.plugins.** { *; }

# media_kit: natives carregados via loadLibrary; sem regras especiais,
# mas mant�m os bindings Java seguros.
-keep class com.ryanheise.** { *; }

# flutter_secure_storage (JNI)
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Play Core deferred components referenciados pelo engine Flutter - usados
# apenas para app bundles na Play Store (AAB + on-demand). APK sideload nao
# usa; R8 so precisa nao falhar pelas classes ausentes.
-dontwarn com.google.android.play.core.**
