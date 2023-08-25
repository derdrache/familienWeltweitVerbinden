import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })

    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  override func application(_ application: UIApplication,
  didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

   Messaging.messaging().apnsToken = deviceToken
   super.application(application,
   didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
 }
}
