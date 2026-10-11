import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    observePrivacyCover()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - Privacy nel selettore delle app

  /// Etichetta della vista che copre l'app quando non è attiva.
  private static let privacyCoverTag = 0x5E5E

  /// iOS fotografa la finestra per il selettore delle app subito dopo che la scena smette di essere
  /// attiva: una vista nativa copre gli importi in modo sincrono, senza aspettare un fotogramma
  /// di Flutter. Si usano le notifiche di UIScene per non toccare i metodi di FlutterSceneDelegate,
  /// che inoltrano il ciclo di vita al motore di Flutter.
  private func observePrivacyCover() {
    let center = NotificationCenter.default
    center.addObserver(forName: UIScene.willDeactivateNotification, object: nil, queue: .main) { note in
      guard let scene = note.object as? UIWindowScene else { return }
      for window in scene.windows where window.viewWithTag(Self.privacyCoverTag) == nil {
        let cover = UIView(frame: window.bounds)
        cover.tag = Self.privacyCoverTag
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Token background dell'app (chiaro #F7F7F5, scuro #111316).
        cover.backgroundColor = UIColor { traits in
          traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x11 / 255, green: 0x13 / 255, blue: 0x16 / 255, alpha: 1)
            : UIColor(red: 0xF7 / 255, green: 0xF7 / 255, blue: 0xF5 / 255, alpha: 1)
        }
        window.addSubview(cover)
      }
    }
    center.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: .main) { note in
      guard let scene = note.object as? UIWindowScene else { return }
      for window in scene.windows {
        window.viewWithTag(Self.privacyCoverTag)?.removeFromSuperview()
      }
    }
  }
}
