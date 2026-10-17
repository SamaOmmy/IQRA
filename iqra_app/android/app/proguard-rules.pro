# flutter_local_notifications stores its schedule with Gson: without these rules a release build loses the notification types
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
