import Cocoa
import FlutterMacOS
import FlutterAnglePlugin // Import the plugin header

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Manually register the EGLGLESPlugin to ensure it's available
    FlutterAnglePlugin.register(with: flutterViewController.registrar(forPlugin: "FlutterAnglePlugin"))
    
    // Still call RegisterGeneratedPlugins for any other plugins
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}