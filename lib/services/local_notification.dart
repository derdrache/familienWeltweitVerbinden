
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService{
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

/*
  static void initialize(){
    var initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher')
    );

    _notificationsPlugin.initialize(initializationSettings, onSelectNotification: (payload) async {print("test");});
  }

 */



  void display(RemoteMessage message) async {

    try {
      var id = DateTime.now().millisecondsSinceEpoch ~/1000;

      NotificationDetails notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          "notification",
          "notification channel",
          channelDescription: "this is our channel",
          importance: Importance.max,
          priority: Priority.high,
        ),
      );
      
      await _notificationsPlugin.show(
          id,
          message.notification.title,
          message.notification.body,
          notificationDetails,
        payload: message.data["chatId"]
      );
    } on Exception catch (e) {
      // TODO
    }
    
    
  }
}