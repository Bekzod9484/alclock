import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 🔹 Flutter plug-inlarni ro‘yxatdan o‘tkazamiz
    GeneratedPluginRegistrant.register(with: self)

    // 🔹 Hech qanday qo‘shimcha CallKit / notifications / method channel YO‘Q
    // faqat Flutter engine va UI

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}