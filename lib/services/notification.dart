import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/secrets.dart';
import '../global/global_functions.dart' as global_funcs;
import 'database.dart';


sendNotification(notificationInformation, {isGroupNotification = false}) async {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var groupLists = [];

  var url = Uri.parse(databaseUrl + (isGroupNotification
      ? phpSendGroupNotification
      : phpSendNotification));

  if (userId == "appStoreViewAccount") return;

  if(isGroupNotification){
    var allSendIds = notificationInformation["toList"];

    if(allSendIds.isEmpty) return;

    while (allSendIds.length > 1000){
      groupLists.add(notificationInformation["toList"].sublist(0,1000));
      allSendIds = allSendIds.sublist(1001);
    }
    groupLists.add(notificationInformation["toList"].sublist(0));

    for(var sendGroup in groupLists){
      await http.post(url,
          body: json.encode({
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

  sendNotification(notificationInformation);

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

    if (notificationsAllowed == 0 ||
        chatNotificationOn == 0 ||
        toActiveChat == chatId || blockList.contains(userId)) continue;

    confirmNotificationList.add(toProfil["token"]);
  }

  notificationInformation["toList"] = confirmNotificationList;

  sendNotification(notificationInformation, isGroupNotification: true);

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

  sendNotification(notificationInformation);
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
      meetupText["inhalt"] ="Du hast jetzt Zugriff auf folgendes Meetup: $meetupName";
    }else{
      meetupText["title"] = "Meetup release";
      meetupText["inhalt"] = "You now have access to the following meetup: $meetupName";
    }
  } else if(typ == "takePart"){
    if(sprache == "ger"){
      meetupText["title"] = "$meetupName - Neuer Teilnehmer";
      meetupText["inhalt"] ="";
    }else{
      meetupText["title"] = "$meetupName - New participant";
      meetupText["inhalt"] = "";
    }
  }

  return meetupText;
}

prepareFriendNotification({newFriendId, toId, toCanGerman}) async {
  var toProfil = getProfilFromHive(profilId: toId);
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

  sendNotification(notificationInformation);
}

prepareNewLocationNotification(){
  Map ownProfil = Hive.box('secureBox').get("ownProfil") ?? [];
  List allProfils = Hive.box('secureBox').get("profils") ?? [];
  List friendTokenListGer = [];
  List friendTokenListEng = [];
  List newFamilieTokenListGer = [];
  List newFamilieTokenListEng = [];

  for(Map profil in allProfils){
    double profilFamiliesRange = profil["familiesDistance"].toDouble();
    bool notificationAllowed = profil["notificationstatus"] == 1;
    bool rangeNotificationAllowed = profilFamiliesRange > 0;
    bool isOwnProfil = profil["id"] == ownProfil["id"];
    var profilToken = profil["token"];
    bool canGerman = profil["sprachen"].contains("Deutsch") || profil["sprachen"].contains("german");
    bool isFriend = profil["friendlist"].contains(ownProfil["id"]);

    if(!rangeNotificationAllowed
        || !notificationAllowed
        || isOwnProfil
        || profilToken == null
        || profilToken.isEmpty) continue;


    if(isFriend){
      if(canGerman){
        friendTokenListGer.add(profilToken);
      }else{
        friendTokenListEng.add(profilToken);
      }
    }else{
      var ownLatt = ownProfil["latt"];
      var ownLongt = ownProfil["longt"];
      var profilLatt = profil["latt"];
      var profilLongt = profil["longt"];
      bool inRange = global_funcs.calculateDistance(
          ownLatt, ownLongt, profilLatt, profilLongt) <= profilFamiliesRange;

      if(!inRange) continue;

      if(canGerman){
        newFamilieTokenListGer.add(profilToken);
      }else{
        newFamilieTokenListEng.add(profilToken);
      }
    }
  }
  var friendNotificationInformationGer = {
    "title": "Ein Freund hat seinen Standort gewechselt",
    "inhalt": "",
    "toList": friendTokenListGer,
    "changePageId": ownProfil["id"],
    "typ": "newFriend"
  };
  var friendNotificationInformationEng = {
    "title": "A friend has changed his location",
    "inhalt": "",
    "toList": friendTokenListEng,
    "changePageId": ownProfil["id"],
    "typ": "newFriend"
  };
  sendNotification(friendNotificationInformationGer, isGroupNotification: true);
  sendNotification(friendNotificationInformationEng, isGroupNotification: true);

  var newFamilieNotificationInformationGer = {
    "title": "Neue Familie in deiner Nähe",
    "inhalt": "Es gibt eine neue Familie in oder um deinen Ort",
    "toList": newFamilieTokenListGer,
    "changePageId": ownProfil["id"],
    "typ": "newFriend"
  };
  var newFamilieNotificationInformationEng = {
    "title": "New Familie near you",
    "inhalt": "There is a new family in or around your location",
    "toList": newFamilieTokenListEng,
    "changePageId": ownProfil["id"],
    "typ": "newFriend"
  };
  sendNotification(newFamilieNotificationInformationGer, isGroupNotification: true);
  sendNotification(newFamilieNotificationInformationEng, isGroupNotification: true);
}

prepareNewTravelPlanNotification(){
  Map ownProfil = Hive.box('secureBox').get("ownProfil") ?? [];
  List allProfils = Hive.box('secureBox').get("profils") ?? [];
  List notificationTokenListGer = [];
  List notificationTokenListEng = [];

  for(Map profil in allProfils){
    bool travelPlanNotificationAllowed = profil["travelPlanNotification"] == 1;
    bool notificationAllowed = profil["notificationstatus"] == 1;
    bool isFriend = profil["friendlist"].contains(ownProfil["id"]);
    var profilToken = profil["token"];
    bool canGerman = profil["sprachen"].contains("Deutsch") || profil["sprachen"].contains("german");

    if(!travelPlanNotificationAllowed
        || !notificationAllowed
        || !isFriend
        || profilToken == null
        || profilToken.isEmpty) continue;

    if(canGerman){
      notificationTokenListGer.add(profilToken);
    }else{
      notificationTokenListEng.add(profilToken);
    }
  }

  var notificationInformationGer = {
    "title": "Neue Reiseplanung von einem Freund",
    "inhalt": "Ein Freund von dir hat eine neue Reiseplanung erstellt",
    "toList": notificationTokenListGer,
    "changePageId": ownProfil["id"],
    "typ": "newFriend"
  };
  var notificationInformationEng = {
    "title": "New travel plan from friend",
    "inhalt": "A friend of yours has made a new travel plan",
    "toList": notificationTokenListEng,
    "changePageId": ownProfil["id"],
    "typ": "newFriend"
  };

  sendNotification(notificationInformationGer, isGroupNotification: true);
  sendNotification(notificationInformationEng, isGroupNotification: true);
}

prepareAddMemberNotification(community, userId){
  Map userProfil = getProfilFromHive(profilId: userId);
  String profilToken = userProfil["token"];
  bool notificationAllowed = userProfil["notificationstatus"] == 1;
  bool speakGerman = userProfil["sprachen"].contains("Deutsch") || userProfil["sprachen"].contains("german");
  var notificationInformation = {
    "token": profilToken,
    "zu": userId,
    "changePageId": community["id"],
    "typ": "community"
  };

  if(!notificationAllowed || profilToken == null) return;

  if(speakGerman){
    notificationInformation["title"] = "Einladung zur Gemeinschaft";
    notificationInformation["inhalt"] = "Du wurdest eingeladen, der Gemeinschaft ${community["name"]} beizutreten";
  }else{
    notificationInformation["title"] = "Community invitation";
    notificationInformation["inhalt"] = "You have been invited to join the ${community["name"]} community";
  }

  sendNotification(notificationInformation);
}
