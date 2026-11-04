# GrowLog release shrink rules.
# flutter_local_notifications stores scheduled notifications with Gson; keep its classes
# so release builds do not strip them (rule recommended in that plugin's documentation).
-keep class com.dexterous.** { *; }

# Room and WorkManager. Google Mobile Ads pulls in WorkManager, which starts at app launch and
# creates its Room database by reflection. Without these rules the release build crashed on
# start ("Failed to create an instance of androidx.work.impl.WorkDatabase").
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.room.paging.**

# ONNX Runtime: its native code looks Java classes up by name, so they must not be renamed or removed.
-keep class ai.onnxruntime.** { *; }
-keep class com.masicai.** { *; }
