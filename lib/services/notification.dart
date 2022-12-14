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

sendNotification(notificationInformation) async {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var url = Uri.parse(databaseUrl + "services/sendNotification.php");

  if (userId == "BUw5puWtumVtAa8mpnDmhBvwdJo1") return;
  //notificationInformation["token"] ="c_gFGMBEQPK5Hmf8nuT7Cf:APA91bFANXzk1lBUuHDWMi_tw-XuL650fYJbUzSmKVoaKK8-vlwdzAC9sEYeNIUHHAyavqP9QW8ndyzQ8pW7R3-FTj_Je_92okkxd0-KOdRtfqEYPM8I9s5hhpjCnuMQQuqdKsjGN880";

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
    "token": "c8nNn3Zd0U_uvQjfikOhAt:APA91bEFZQCuweeVXlrtol2k-H8oBYu3D3jAkCRQZq_Tf-kMIKBR3R8ocN5G9JRrHYq-nxvPMoBHEkFosTE4aO78IZUOQyiUI5rzydnCHLAC09onQuqSSSE0zTlMChcCurhve2ty2t_1",
    "title": "Test2",
    "inhalt": "Families worldwide notifikation test\n Siehst du diese Notification? Und kannst landest du beim draufklicken in unserem Chat?",
    "zu": "vtp97dpVxVZimnyLAdrorgSPUMI3",
    "changePageId": "vtp97dpVxVZimnyLAdrorgSPUMI3_w9yxDHP3W8dVGoYpBCrLWlufJ0s2",
    "typ": "chat",
  };

  sendNotification(notificationInformation);
  print("send");
}

testNotification2(){
  var notificationInformation = {
    "token": "doiVpA5tyE3zisAeXer5aV:APA91bE7MnfLrkRQz1cCpEeVJuwi3mRcyjg5oWeS_d8pPKT4FxEL4eETFYCQAgtQVJ2sqfjWoZwtjzuiUnirk4JLzG61P7pfW9PYCLuRrI1Lbgej0yWVr0tcTLw_2aV9Gyi7e2qhY3Un",
    "title": "Test2",
    "inhalt": "Families worldwide notifikation test\n Siehst du diese Notification? Und kannst landest du beim draufklicken in unserem Chat?",
    "zu": "9o2RieiDLXczqOuoELSxcMjdYX23",
    "changePageId": "9o2RieiDLXczqOuoELSxcMjdYX23_w9yxDHP3W8dVGoYpBCrLWlufJ0s2",
    "typ": "chat",
  };

  sendNotification(notificationInformation);
  print("send");
}
