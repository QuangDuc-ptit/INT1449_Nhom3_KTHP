package com.example.karvocab_flutter

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // true khi Flutter đã vẽ frame đầu tiên (màn Splash Flutter đã có logo)
    private var flutterUiDisplayed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Màn 01: splash native (Android SplashScreen API). Phải gọi trước super.onCreate.
        // Giữ splash đến khi Flutter hiện frame đầu → chuyển tiếp liền mạch, không nháy.
        installSplashScreen().setKeepOnScreenCondition { !flutterUiDisplayed }
        super.onCreate(savedInstanceState)
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        flutterUiDisplayed = true
    }
}
