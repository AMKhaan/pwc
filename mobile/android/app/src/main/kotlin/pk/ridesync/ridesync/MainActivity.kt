package pk.ridesync.ridesync

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Move app to background on back press instead of finishing the Activity.
    // This prevents the "restart from scratch" issue when reopening from recents.
    override fun finish() {
        moveTaskToBack(true)
    }
}
