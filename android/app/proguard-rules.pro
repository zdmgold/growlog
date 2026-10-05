# GrowLog release shrink rules.
# flutter_local_notifications stores scheduled notifications with Gson; keep its classes
# so release builds do not strip them (rule recommended in that plugin's documentation).
-keep class com.dexterous.** { *; }
