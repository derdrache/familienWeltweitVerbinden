import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../auth/secrets.dart';
import '../global/global_functions.dart' as global_funcs;
import 'database.dart';
import 'package:firebase_auth/firebase_auth.dart';

sendEmail(notificationInformation, {targetEmail}) async {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == "appStoreViewAccount") return;

  var url = Uri.parse(databaseUrl + phpSendEmail);
  targetEmail ??= await ProfilDatabase()
      .getData("email", "WHERE id = '${notificationInformation["zu"]}'");

  http.post(url,
      body: json.encode({
        "to": targetEmail,
        "title": notificationInformation["title"],
        "inhalt": notificationInformation["inhalt"]
      }));
}

sendNotification(notificationInformation, {isGroup = false}) async {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var groupLists = [];

  var url = Uri.parse(databaseUrl + (isGroup
      ? phpSendGroupNotification
      : phpSendNotification));

  if (userId == "appStoreViewAccount") return;

  if(isGroup){
    var allSendIds = notificationInformation["toList"];

    while (allSendIds.length > 1000){
      groupLists.add(notificationInformation["toList"].sublist(0,1000));
      allSendIds = allSendIds.sublist(1001);
    }
    groupLists.add(notificationInformation["toList"].sublist(0));

    for(var sendGroup in groupLists){
      await http.post(url,
          body: json.encode({
            "to": notificationInformation["token"],
            "toList": sendGroup,
            "title": notificationInformation["title"],
            "inhalt": notificationInformation["inhalt"],
            "changePageId": notificationInformation["changePageId"],
            "apiKey": firebaseWebKey,
            "typ": notificationInformation["typ"]
          }));
    }
  }else{
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

prepareChatGroupNotification({chatId, idList, inhalt, chatGroup = ""}) async {
  List confirmNotificationList = [];
  String ownName = Hive.box('secureBox').get("ownProfil")["name"];
  if(chatGroup.isNotEmpty) chatGroup += " - ";
  var title = chatGroup + ownName;
  var notificationInformation = {
    "title": title,
    "inhalt": inhalt,
    "changePageId": chatId,
    "typ": "chat",
  };

  for(var userId in idList){
    var toProfil = getProfilFromHive(profilId: userId);

    if(toProfil == null) continue;

    var blockList = Hive.box('secureBox').get("ownProfil")["geblocktVon"];
    var toActiveChat = toProfil["activeChat"];
    var notificationsAllowed = toProfil["notificationstatus"];
    var chatNotificationOn = toProfil["chatNotificationOn"];
    bool targetCanGerman = toProfil["sprachen"].contains("Deutsch") || toProfil["sprachen"].contains("german");

    if (notificationsAllowed == 0 ||
        chatNotificationOn == 0 ||
        toActiveChat == chatId || blockList.contains(userId)) continue;

    if (toProfil["token"] == "" ||
        toProfil["token"] == null) {
      var copyNotificationInformation = Map.of(notificationInformation);
      var chatPartnerName = toProfil["name"];

      copyNotificationInformation["title"] = title +
          (targetCanGerman
              ? " hat dir eine Nachricht geschrieben"
              : " has written you a message");

      copyNotificationInformation["inhalt"] = """
      <p>Hi $chatPartnerName, </p>
      <p> ${(targetCanGerman ? "du hast in der <a href='https://families-worldwide.com/'>Families worldwide App</a> eine neue Nachricht von "
          "$title erhalten" : "you have received a new message from "
          "$title in the <a href='https://families-worldwide.com/'>Families worldwide App</a>")} </p>
    """;

      sendEmail(copyNotificationInformation);
    } else {
      confirmNotificationList.add(toProfil["token"]);
    }
  }

  notificationInformation["toList"] = confirmNotificationList;

  sendNotification(notificationInformation, isGroup: true);

}

prepareMeetupNotification({meetupId, toId, meetupName, typ}) async {
  var dbData = await ProfilDatabase().getData(
      "notificationstatus, eventNotificationOn, token, name, sprachen",
      "WHERE id = '$toId'");
  var notificationsAllowed = dbData["notificationstatus"];
  var meetupNotificationOn = dbData["eventNotificationOn"];
  var toCanGerman = dbData["sprachen"].contains("Deutsch") || dbData["sprachen"].contains("german");

  var meetupText = createMeetupText(typ,meetupName,toCanGerman ? "ger" : "eng");


  if (notificationsAllowed == 0 || meetupNotificationOn == 0) return;

  var notificationInformation = {
    "zu": toId,
    "toName": dbData["name"],
    "typ": "event",
    "title": meetupText["title"],
    "inhalt": meetupText["inhalt"],
    "changePageId": meetupId,
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

createMeetupText(typ, meetupName, sprache){
  var meetupText = {
    "title": "",
    "inhalt": ""
  };

  if(typ == "freigeben"){
    if(sprache == "ger"){
      meetupText["title"] = "Meetup - Familie freigaben";
      meetupText["inhalt"] = "Eine Familie möchte für das Meetup $meetupName freigeschaltet werden";
    }else{
      meetupText["title"] = "Meetup familie release";
      meetupText["inhalt"] = "A family wants to be unlocked for the meetup $meetupName";
    }
  }else if(typ == "freigegeben"){
    if(sprache == "ger"){
      meetupText["title"] = "Meetup Freigabe";
      meetupText["inhalt"] ="Du hast jetzt Zugriff auf folgendes Meetup: " + meetupName;
    }else{
      meetupText["title"] = "Meetup release";
      meetupText["inhalt"] = "You now have access to the following meetup: " + meetupName;
    }
  }

  return meetupText;
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

prepareFamilieAroundNotification(){
  Map ownProfil = Hive.box('secureBox').get("ownProfil") ?? [];
  List allProfils = Hive.box('secureBox').get("profils") ?? [];

  for(Map profil in allProfils){
    double profilFamiliesRange = profil["familiesDistance"];
    bool notificationAllowed = profilFamiliesRange > 0;

    if(!notificationAllowed) continue;

    var ownLatt = ownProfil["latt"];
    var ownLongt = ownProfil["longt"];
    var profilLatt = profil["latt"];
    var profilLongt = profil["longt"];
    bool inRange = global_funcs.calculateDistance(
        ownLatt, ownLongt, profilLatt, profilLongt) <= profilFamiliesRange;

    if(!inRange) continue;

    String profilId = profil["id"];
    String ownProfilId = ownProfil["id"];
    var profilToken = profil["token"];
    bool canGerman = profil["sprachen"].contains("Deutsch") || profil["sprachen"].contains("german");
    var notificationInformation = {
      "token": profilToken,
      "title": "",
      "inhalt": "",
      "zu": profilId,
      "changePageId": ownProfilId,
      "typ": "newFriend"
    };

    if(profilToken != "" && profilToken != null){
      if(canGerman){
        notificationInformation["title"] = "Neue Familie in deiner Nähe";
        notificationInformation["inhalt"] = "Es gibt eine neue Familie in oder um deinen Ort";
      }else{
        notificationInformation["title"] = "New Familie near you";
        notificationInformation["inhalt"] = "There is a new family in or around your location";
      }
      sendNotification(notificationInformation);
    }
  }

}
