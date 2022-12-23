import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../auth/secrets.dart';
import 'database.dart';
import 'package:firebase_auth/firebase_auth.dart';

var databaseUrl = "https://families-worldwide.com/";

sendEmail(notificationInformation) async {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == "BUw5puWtumVtAa8mpnDmhBvwdJo1") return;

  var url = Uri.parse(databaseUrl + "services/sendEmail2.php");
  var emailAdresse = await ProfilDatabase()
      .getData("email", "WHERE id = '${notificationInformation["zu"]}'");

  http.post(url,
      body: json.encode({
        "to": emailAdresse,
        "title": notificationInformation["title"],
        "inhalt": notificationInformation["inhalt"]
      }));
}

sendNotification(notificationInformation, {isGroup = false}) async {
  var userId = FirebaseAuth.instance.currentUser?.uid;

  var url = Uri.parse(databaseUrl + (isGroup
      ? "services/sendGroupNotification.php"
      : "services/sendNotification.php"));

  if (userId == "BUw5puWtumVtAa8mpnDmhBvwdJo1") return;
  //notificationInformation["token"] ="c_gFGMBEQPK5Hmf8nuT7Cf:APA91bFANXzk1lBUuHDWMi_tw-XuL650fYJbUzSmKVoaKK8-vlwdzAC9sEYeNIUHHAyavqP9QW8ndyzQ8pW7R3-FTj_Je_92okkxd0-KOdRtfqEYPM8I9s5hhpjCnuMQQuqdKsjGN880";

  await http.post(url,
      body: json.encode({
        "to": notificationInformation["token"],
        "toList": notificationInformation["toList"],
        "title": notificationInformation["title"],
        "inhalt": notificationInformation["inhalt"],
        "changePageId": notificationInformation["changePageId"],
        "apiKey": firebaseWebKey,
        "typ": notificationInformation["typ"]
      }));
}

prepareChatNotification({chatId, vonId, toId, inhalt, chatGroup = ""}) async {
  var toProfil = getProfilFromHive(profilId: toId);
  var blockList = Hive.box('secureBox').get("ownProfil")["geblocktVon"];
  var toActiveChat = toProfil["activeChat"];
  var notificationsAllowed = toProfil["notificationstatus"];
  var chatNotificationOn = toProfil["chatNotificationOn"];

  if (notificationsAllowed == 0 ||
      chatNotificationOn == 0 ||
      toActiveChat == chatId || blockList.contains(toId)) return;

  if(chatGroup.isNotEmpty) chatGroup += " - ";
  var title = chatGroup + getProfilFromHive(profilId: vonId, getNameOnly: true);

  var notificationInformation = {
    "token": toProfil["token"],
    "title": title,
    "inhalt": inhalt,
    "zu": toId,
    "changePageId": chatId,
    "typ": "chat",
  };


  if (notificationInformation["token"] == "" ||
      notificationInformation["token"] == null) {
    var dbData = getProfilFromHive(profilId: toId);
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
    sendNotification(notificationInformation);
  }
}

prepareChatGroupNotification({chatId, vonId, idList, inhalt, chatGroup = ""}) async {
  List confirmNotificationList = [];
  if(chatGroup.isNotEmpty) chatGroup += " - ";
  var title = chatGroup + getProfilFromHive(profilId: vonId, getNameOnly: true);
  var notificationInformation = {
    "title": title,
    "inhalt": inhalt,
    "changePageId": chatId,
    "typ": "chat",
  };

  for(var userId in idList){
    var toProfil = getProfilFromHive(profilId: userId);
    var blockList = Hive.box('secureBox').get("ownProfil")["geblocktVon"];
    var toActiveChat = toProfil["activeChat"];
    var notificationsAllowed = toProfil["notificationstatus"];
    var chatNotificationOn = toProfil["chatNotificationOn"];

    if (notificationsAllowed == 0 ||
        chatNotificationOn == 0 ||
        toActiveChat == chatId || blockList.contains(userId)) continue;

    if (toProfil["token"] == "" ||
        toProfil["token"] == null) {
      var chatPartnerName = toProfil["name"];
      var toCanGerman = toProfil["sprachen"].contains("Deutsch") || toProfil["sprachen"].contains("german");

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
      confirmNotificationList.add(toProfil["token"]);
    }
  }

  notificationInformation["toList"] = confirmNotificationList;

  sendNotification(notificationInformation, isGroup: true);

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
    var chatPartnerProfil = getProfilFromHive(profilId: toId, getNameOnly: true);
    var chatPartnerName = chatPartnerProfil["name"];

    var wantNotifikations = chatPartnerProfil["eventNotificationOn"] == 1 ? true : false;

    if(!wantNotifikations) return;

    notificationInformation["inhalt"] = """
      <p>Hi $chatPartnerName, </p>
      <p>${notificationInformation["inhalt"]}</p>
      <p><a href="https://families-worldwide.com/">Families worldwide App</a> </p>
    """;

    sendEmail(notificationInformation);
  } else {
    sendNotification(notificationInformation);
  }
}

prepareFriendNotification({newFriendId, toId, toCanGerman}) async {
  var toProfil = getProfilFromHive(profilId: toId);
  var toProfilName = toProfil["name"];
  var notificationsAllowed = toProfil["notificationstatus"];
  var newFriendNotificationOn = toProfil["newFriendNotificationOn"];
  var token = toProfil["token"];
  var ownName = Hive.box('secureBox').get("ownProfil")["name"];

  var title ="";
  var inhalt = "";

  if(toCanGerman){
    title = "Neuer Freund";
    inhalt = ownName +" hat dich als Freund hinzugefügt";
  }else {
    title = "new friend";
    inhalt = ownName +" has added you as friend";
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
    var wantNotifikations = toProfil["newFriendNotificationOn"] == 1 ? true : false;

    if(!wantNotifikations) return;

    notificationInformation["inhalt"] = """
      <p>Hi $toProfilName, </p>
      ${(toCanGerman ? "<p> $ownName hat dich als Freund hinzugefügt. </p>" : "<p> $ownName added you as a friend. </p>")}
        <p><a href="https://families-worldwide.com/">Families worldwide App</a> </p>
    """;

    sendEmail(notificationInformation);
  } else {
    sendNotification(notificationInformation);
  }
}

testNotification1(){
  var notificationInformation = {
    "token": "eZUKnENOT0FInvtvnWUfoJ:APA91bHQz6v3dMcsBqzFAK83zU2HnV2Up3j4jtiONe6PyS9M0o5g6incza-h9VANRCzSDvhzKtP0ySGaVbXGlzOeLKs_PLWyacm7sL25y528sYLKr3nB3IyMcujga4ewPLzRQRY5ZNRg",
    "title": "Test2 Families worldwide",
    "inhalt": "Siehst du diese Benachrichtigung?\n Es wird keine Nachricht im Chat geben",
    "zu": "",
    "changePageId": "",
    "typ": "chat",
  };

  sendNotification(notificationInformation);
  print("send");
}
