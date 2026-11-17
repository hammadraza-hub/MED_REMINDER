package com.medreminder.app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// FragmentActivity is required by local_auth (biometric app lock, M13 step 6).
//
// M21 step 4: the "recent apps" screen must not show health data. While the
// app is not in front, the window is marked secure, so the system draws a blank
// thumbnail instead of a screenshot of the current screen. In front, screenshots
// still work (a person may want to show a screen to their doctor).
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 13+: no screenshot in the recents list at all.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setRecentsScreenshotEnabled(false)
        }
    }

    override fun onPause() {
        // Before the system takes the recents snapshot.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
