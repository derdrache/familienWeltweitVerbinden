import 'dart:convert';
import 'package:http/http.dart' as http;

import '../auth/secrets.dart';
import 'database.dart';

var databaseUrl = "https://families-worldwide.com/";

_sendEmail(notificationInformation) async {
  var url = Uri.parse(databaseUrl + "services/sendEmail.php");
  var emailAdresse = await ProfilDatabase()
      .getData("email", "WHERE id = '${notificationInformation["zu"]}'");

  http.post(url,
      body: json.encode({
        "to": emailAdresse,
        "title": notificationInformation["title"],
        "inhalt": notificationInformation["inhalt"]
      }));
}

_sendNotification(notificationInformation) async {
  var url = Uri.parse(databaseUrl + "services/sendNotification.php");

  http.post(url,
      body: json.encode({
        "to": notificationInformation["token"],
        "title": notificationInformation["title"],
        "inhalt": notificationInformation["inhalt"],
        "changePageId": notificationInformation["changePageId"],
        "apiKey": firebaseWebKey,
        "typ": notificationInformation["typ"]
      }));
}

prepareChatNotification({chatId, vonId, toId, title, inhalt}) async {
  var dbData = await ProfilDatabase().getData(
      "activeChat, notificationstatus, chatNotificationOn, token,",
      "WHERE id = '$toId'");
  var toActiveChat = dbData["activeChat"];
  var notificationsAllowed = dbData["notificationstatus"];
  var chatNotificationOn = dbData["chatNotificationOn"];

  if (notificationsAllowed == 0 ||
      chatNotificationOn == 0 ||
      toActiveChat == chatId) return;

  title = await ProfilDatabase().getData("name", "WHERE id = '$vonId'");

  var notificationInformation = {
    "token": dbData["token"],
    "title": title,
    "inhalt": inhalt,
    "zu": toId,
    "changePageId": chatId,
    "typ": "chat",
  };

  if (notificationInformation["token"] == "" ||
      notificationInformation["token"] == null) {
    var chatPartnerName =
        await ProfilDatabase().getData("name", "WHERE id = '$toId'");

    notificationInformation["title"] = title +
        (spracheIstDeutsch
            ? " hat dir eine Nachricht geschrieben"
            : " has written you a message");
    notificationInformation["inhalt"] = "Hi $chatPartnerName,\n\n" +
        (spracheIstDeutsch
            ? "du hast in der families worldwide App eine neue Nachricht von "
                "$title erhalten \n\n"
            : "you have received a new message from "
                "$title in the families worldwide app \n\n");

    _sendEmail(notificationInformation);
  } else {
    _sendNotification(notificationInformation);
  }
}

prepareEventNotification({eventId, toId, title, inhalt}) async {
  var dbData = await ProfilDatabase().getData(
      "notificationstatus, eventNotificationOn, token, name",
      "WHERE id = '$toId'");
  var notificationsAllowed = dbData["notificationstatus"];
  var eventNotificationOn = dbData["eventNotificationOn"];

  if (notificationsAllowed == 0 || eventNotificationOn == 0) return;

  var notificationInformation = {
    "toId": toId,
    "toName": dbData["name"],
    "typ": "event",
    "title": title,
    "inhalt": inhalt,
    "changePageId": eventId,
    "token": dbData["token"]
  };

  notificationInformation["token"] = "1";

  if (notificationInformation["token"] == "" ||
      notificationInformation["token"] == null) {
    _sendEmail(notificationInformation);
  } else {
    _sendNotification(notificationInformation);
  }
}

prepareFriendNotification({newFriendId, toId, title, inhalt}) async {
  var dbData = await ProfilDatabase().getData(
      "notificationstatus, newFriendNotificationOn, token",
      "WHERE id = '$toId'");
  var notificationsAllowed = dbData["notificationstatus"];
  var newFriendNotificationOn = dbData["newFriendNotificationOn"];
  var token = dbData["token"];

  if (notificationsAllowed == 0 || newFriendNotificationOn == 0) return;

  var notificationInformation = {
    "token": token,
    "title": title,
    "inhalt": inhalt,
    "zu": toId,
    "changePageId": newFriendId,
    "typ": "newFriend"
  };

  if (notificationInformation["token"] == "" ||
      notificationInformation["token"] == null) {
    _sendEmail(notificationInformation);
  } else {
    _sendNotification(notificationInformation);
  }
}
