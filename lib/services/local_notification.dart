import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService{
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  void display(RemoteMessage message, {withMeetupAction = true}) async {

    try {
      var id = DateTime.now().millisecondsSinceEpoch ~/1000;

      NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "notification",
          "notification channel",
          channelDescription: "this is our channel",
          importance: Importance.max,
          priority: Priority.high,

          actions: !withMeetupAction ? null : <AndroidNotificationAction>[
            AndroidNotificationAction('id_1', 'MeetupZusagen'),
            AndroidNotificationAction('id_2', 'MeetupAbsagen'),
          ]
        ),
        iOS: DarwinNotificationDetails()
      );

      var typ = jsonEncode(json.decode(message.data.values.last)["typ"]);
      var link = jsonEncode(json.decode(message.data.values.last)["link"]);

      print("show");
      await _notificationsPlugin.show(
          id,
          message.notification!.title,
          message.notification!.body,
          notificationDetails,
          payload: '{"typ": $typ, "link" : $link}'
      );
    } on Exception catch (_) {

    }
  }
}