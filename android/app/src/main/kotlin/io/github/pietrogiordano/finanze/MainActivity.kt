package io.github.pietrogiordano.finanze

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
// local_auth mostra il dialog della biometria con un Fragment: serve FlutterFragmentActivity.
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Nessun importo nell'anteprima delle app recenti.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+: niente anteprima, ma gli screenshot restano possibili.
            setRecentsScreenshotEnabled(false)
        } else {
            // Prima di Android 13 l'unico modo affidabile: blocca anche screenshot e registrazioni.
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
