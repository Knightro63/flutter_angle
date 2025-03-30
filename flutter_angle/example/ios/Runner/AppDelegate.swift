import Flutter
import UIKit
import FlutterAnglePlugin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Fix the unwrapping issue - the registrar is optional and needs to be unwrapped
    if let registrar = self.registrar(forPlugin: "FlutterAnglePlugin") {
      FlutterAnglePlugin.register(with: registrar)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
