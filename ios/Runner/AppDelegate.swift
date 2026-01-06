import UIKit
import Flutter
import GoogleMaps 

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // THIS IS THE CRITICAL LINE FOR IOS
    GMSServices.provideAPIKey("AIzaSyDU8sGgEgDQdxI-kkG4pvNKxaCz-RLwrxk") 
    // ^ REPLACE WITH YOUR ACTUAL IOS KEY IF DIFFERENT, BUT USE THE VALUE

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}