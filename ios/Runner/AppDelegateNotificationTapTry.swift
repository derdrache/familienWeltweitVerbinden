import UIKit
import Flutter
import FirebaseCore
import Firebase
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {


  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
  FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
    GeneratedPluginRegistrant.register(with: registry)
  }
    FirebaseApp.configure()
   FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
     GeneratedPluginRegistrant.register(with: registry)
   }

        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: {_, _ in })
        }


        application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}