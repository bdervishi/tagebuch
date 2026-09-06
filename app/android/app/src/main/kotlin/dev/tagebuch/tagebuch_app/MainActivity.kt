package dev.tagebuch.tagebuch_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE (D5, docs/05 Abschnitt 3.2): leere Kachel im App-Switcher,
        // keine Screenshots und keine Bildschirmaufnahme von Tagebuchinhalten.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
