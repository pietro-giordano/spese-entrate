# Regole R8 per la build release. I plugin Flutter includono già le proprie
# consumer rules: qui solo ciò che serve in più.

# Flutter fa riferimento a classi Play Core (deferred components) che l'app non usa.
-dontwarn com.google.android.play.core.**
