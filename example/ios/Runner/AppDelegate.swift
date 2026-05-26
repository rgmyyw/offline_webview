import Flutter
import UIKit
import Network

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var browser: NWBrowser?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    triggerLocalNetworkPermission()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func triggerLocalNetworkPermission() {
    let parameters = NWParameters()
    parameters.includePeerToPeer = true
    let descriptor = NWBrowser.Descriptor.bonjour(type: "_http._tcp", domain: "local.")
    browser = NWBrowser(for: descriptor, using: parameters)
    browser?.stateUpdateHandler = { [weak self] state in
      if case .ready = state {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          self?.browser?.cancel()
          self?.browser = nil
        }
      }
    }
    browser?.start(queue: .main)
  }
}
