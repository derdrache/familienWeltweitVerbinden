import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../auth/secrets.dart';
import 'database.dart';

var databaseUrl = "https://families-worldwide.com/";

sendEmail(notificationInformation) async {
  return;
  var url = Uri.parse(databaseUrl + "services/sendEmail2.php");
  var emailAdresse = await ProfilDatabase()
      .getData("email", "WHERE id = '${notificationInformation["zu"]}'");

  if(emailAdresse == false) emailAdresse = "dominik.mast.11@gmail.com";

  http.post(url,
      body: json.encode({
        "to": emailAdresse,
        "title": notificationInformation["title"],
        "inhalt": notificationInformation["inhalt"]
      }));
}

_sendNotification(notificationInformation) async {
  return;
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

prepareChatNotification({chatId, vonId, toId, inhalt}) async {
  var dbData = await ProfilDatabase().getData(
      "activeChat, notificationstatus, chatNotificationOn, token",
      "WHERE id = '$toId'");
  var blockList = Hive.box('secureBox').get("ownProfil")["geblocktVon"];
  var toActiveChat = dbData["activeChat"];
  var notificationsAllowed = dbData["notificationstatus"];
  var chatNotificationOn = dbData["chatNotificationOn"];

  if (notificationsAllowed == 0 ||
      chatNotificationOn == 0 ||
      toActiveChat == chatId || blockList.contains(toId)) return;



  var title = await ProfilDatabase().getData("name", "WHERE id = '$vonId'");

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
    var dbData =
        await ProfilDatabase().getData("name,sprachen", "WHERE id = '$toId'");
    var chatPartnerName = dbData["name"];
    var toCanGerman = dbData["sprachen"].contains("Deutsch") || dbData["sprachen"].contains("german");

    notificationInformation["title"] = title +
        (toCanGerman
            ? " hat dir eine Nachricht geschrieben"
            : " has written you a message");

    notificationInformation["inhalt"] = """
      <p>Hi $chatPartnerName, </p>
      <p> ${(toCanGerman ? "du hast in der <a href='https://families-worldwide.com/'>Families worldwide App</a> eine neue Nachricht von "
            "$title erhalten" : "you have received a new message from "
            "$title in the <a href='https://families-worldwide.com/'>Families worldwide App</a>")} </p>
    """;

    sendEmail(notificationInformation);
  } else {
    _sendNotification(notificationInformation);
  }
}

prepareEventNotification({eventId, toId, eventName}) async {
  var dbData = await ProfilDatabase().getData(
      "notificationstatus, eventNotificationOn, token, name, sprachen",
      "WHERE id = '$toId'");
  var notificationsAllowed = dbData["notificationstatus"];
  var eventNotificationOn = dbData["eventNotificationOn"];
  var toCanGerman = dbData["sprachen"].contains("Deutsch") || dbData["sprachen"].contains("german");
  String title;
  String inhalt;

  if(toCanGerman){
    title = "Event Freigabe";
    inhalt ="Du hast jetzt Zugriff auf folgendes Event: " + eventName;
  }else{
    title = "Event release";
    inhalt = "You now have access to the following event: " + eventName;
  }

  if (notificationsAllowed == 0 || eventNotificationOn == 0) return;

  var notificationInformation = {
    "zu": toId,
    "toName": dbData["name"],
    "typ": "event",
    "title": title,
    "inhalt": inhalt,
    "changePageId": eventId,
    "token": dbData["token"]
  };

  if (notificationInformation["token"] == "" ||
      notificationInformation["token"] == null) {
    var chatPartnerName =
        await ProfilDatabase().getData("name", "WHERE id = '$toId'");

    notificationInformation["inhalt"] = """
      <p>Hi $chatPartnerName, </p>
      <p>${notificationInformation["inhalt"]}</p>
      <p><a href="https://families-worldwide.com/">Families worldwide App</a> </p>
    """;

    sendEmail(notificationInformation);
  } else {
    _sendNotification(notificationInformation);
  }
}

prepareFriendNotification({newFriendId, toId, toCanGerman}) async {
  var dbData = await ProfilDatabase().getData(
      "notificationstatus, newFriendNotificationOn, token",
      "WHERE id = '$toId'");
  var notificationsAllowed = dbData["notificationstatus"];
  var newFriendNotificationOn = dbData["newFriendNotificationOn"];
  var token = dbData["token"];
  var title ="";
  var inhalt = "";

  if(toCanGerman){
    title = "Neuer Freund";
    inhalt = FirebaseAuth.instance.currentUser.displayName +" hat dich als Freund hinzugefügt";
  }else {
    title = "new friend";
    inhalt = FirebaseAuth.instance.currentUser.displayName +" has added you as friend";
  }

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
    var chatPartnerName =
        await ProfilDatabase().getData("name", "WHERE id = '$toId'");
    var friendName = FirebaseAuth.instance.currentUser.displayName;

    notificationInformation["inhalt"] = """
      <p>Hi $chatPartnerName, </p>
      ${(toCanGerman ? "<p> $friendName hat dich als Freund hinzugefügt. </p>" : "<p> $friendName added you as a friend. </p>")}
        <p><a href="https://families-worldwide.com/">Families worldwide App</a> </p>
    """;

    sendEmail(notificationInformation);
  } else {
    _sendNotification(notificationInformation);
  }
}
