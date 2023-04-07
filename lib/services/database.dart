import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' as foundation;

import '../auth/secrets.dart';
import '../global/encryption.dart';
import '../global/global_functions.dart' as global_functions;
import 'locationsService.dart';
import 'notification.dart';

var spracheIstDeutsch = kIsWeb
    ? ui.window.locale.languageCode == "de"
    : io.Platform.localeName == "de_DE";

class ProfilDatabase {
  addNewProfil(profilData) async {
    var url = Uri.parse(databaseUrl + databasePathNewProfil);
    var data = {
      "id": profilData["id"],
      "name": profilData["name"],
      "email": profilData["email"],
      "land": profilData["land"],
      "interessen": json.encode(profilData["interessen"]),
      "kinder": json.encode(profilData["kinder"]),
      "latt": profilData["latt"],
      "longt": profilData["longt"],
      "ort": profilData["ort"],
      "reiseart": profilData["reiseart"],
      "sprachen": json.encode(profilData["sprachen"]),
      "token": profilData["token"],
      "lastLogin": profilData["lastLogin"],
      "aboutme": profilData["aboutme"]
    };

    await http.post(url, body: json.encode(data));

    FirebaseAuth.instance.currentUser.updateDisplayName(profilData["name"]);
  }

  updateProfil(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode(
            {"table": "profils", "whatData": whatData, "queryEnd": queryEnd}));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode(
            {"whatData": whatData, "queryEnd": queryEnd, "table": "profils"}));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);
    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  updateProfilName(userId, newName) async {
    FirebaseAuth.instance.currentUser.updateDisplayName(newName);

    updateProfil("name = '$newName'", "WHERE id = '$userId'");
  }

  updateProfilLocation(userId, locationDict) async {
    var url =
        Uri.parse(databaseUrl + databasePathUpdateProfilLocation);

    await http.post(url,
        body: json.encode({
          "id": userId,
          "land": locationDict["countryname"],
          "city": locationDict["city"],
          "longt": locationDict["longt"],
          "latt": locationDict["latt"]
        }));
  }

  deleteProfil(userId) async {
    _deleteInTable("profils", "id", userId);
    _deleteInTable("newsSettings", "id", userId);
    _deleteInTable("news_page", "id", userId);

    updateProfil(
        "friendlist = JSON_REMOVE(friendlist, JSON_UNQUOTE(JSON_SEARCH(friendlist, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(friendlist, '\"$userId\"') > 0");

    var userMeetups = await MeetupDatabase()
        .getData("id", "WHERE erstelltVon = '$userId'", returnList: true);
    if (userMeetups != false) {
      for (var meetupId in userMeetups) {
        _deleteInTable("events", "id", meetupId);
      }
    }

    MeetupDatabase().update(
        "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(interesse, '\"$userId\"') > 0");

    MeetupDatabase().update(
        "zusage = JSON_REMOVE(zusage, JSON_UNQUOTE(JSON_SEARCH(zusage, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(zusage, '\"$userId\"') > 0");

    MeetupDatabase().update(
        "absage = JSON_REMOVE(absage, JSON_UNQUOTE(JSON_SEARCH(absage, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(absage, '\"$userId\"') > 0");

    MeetupDatabase().update(
        "freischalten = JSON_REMOVE(freischalten, JSON_UNQUOTE(JSON_SEARCH(freischalten, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(freischalten, '\"$userId\"') > 0");

    MeetupDatabase().update(
        "freigegeben = JSON_REMOVE(freigegeben, JSON_UNQUOTE(JSON_SEARCH(freigegeben, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(freigegeben, '\"$userId\"') > 0");

    ChatGroupsDatabase().updateChatGroup(
        "users = JSON_REMOVE(users, '\$.$userId')",
        "WHERE JSON_CONTAINS_PATH(users, 'one', '\$.$userId')"
    );

    if(userId == FirebaseAuth.instance.currentUser.uid){
      Hive.box("secureBox").deleteFromDisk();
      try {
        await FirebaseAuth.instance.currentUser.delete();
      } catch (_) {
        return false;
      }
    }


  }
}

class ChatDatabase {
  addNewChatGroup(chatPartner) {
    var userId = FirebaseAuth.instance.currentUser.uid;
    var userKeysList = [userId, chatPartner];
    var chatID = global_functions.getChatID(chatPartner);
    var date = DateTime.now().millisecondsSinceEpoch;
    var userData = {
      userKeysList[0]: {"newMessages": 0},
      userKeysList[1]: {"newMessages": 0},
    };

    var newChatGroup = {
      "id": chatID,
      "date": date,
      "users": json.encode(userData),
      "lastMessage": "",
    };

    var url = Uri.parse(databaseUrl + databasePathNewPersonalChat);
    http.post(url, body: json.encode(newChatGroup));

    newChatGroup["users"] = userData;

    return newChatGroup;
  }

  getChatData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode(
            {"whatData": whatData, "queryEnd": queryEnd, "table": "chats"}));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);
    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  getAllChatMessages(chatId) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": "*",
          "queryEnd": "WHERE chatId = '$chatId'",
          "table": "messages"
        }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    return responseBody;
  }

  updateChatGroup(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode(
            {"table": "chats", "whatData": whatData, "queryEnd": queryEnd}));
  }

  updateMessage(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode(
            {"table": "messages", "whatData": whatData, "queryEnd": queryEnd}));
  }

  addNewMessageAndSendNotification(chatId, messageData, isBlocked) async {
    var chatgroupData = await getChatData("*", "WHERE id = '$chatId'");
    var date = DateTime.now().millisecondsSinceEpoch;

    if(chatId == null || chatId.isEmpty) chatId = global_functions.getChatID(messageData["zu"]);

    messageData["message"] = messageData["message"].replaceAll("'", "\\'");

    if (isBlocked) return;

    var url = Uri.parse(databaseUrl + databasePathPersonChatNewMessages);
    await http.post(url,
        body: json.encode({
          "chatId": chatId,
          "date": date,
          "message": messageData["message"],
          "von": messageData["von"],
          "zu": messageData["zu"],
          "responseId": messageData["responseId"],
          "forward": messageData["forward"]
        }));

    _changeNewMessageCounter(messageData["zu"], chatgroupData);

    var isMute = chatgroupData["users"][messageData["zu"]]["mute"] ?? false;
    var isActive =
        chatgroupData["users"][messageData["zu"]]["isActive"] ?? false;
    isActive = isActive == 1 ? true : false;

    if (!isMute && !isActive) {
      prepareChatNotification(
          chatId: chatId,
          vonId: messageData["von"],
          toId: messageData["zu"],
          inhalt: messageData["message"]);
    }
  }

  _changeNewMessageCounter(chatPartnerId, chatData) async {
    var chatId = chatData['id'];
    var activeChat = await ProfilDatabase()
        .getData("activeChat", "WHERE id = '$chatPartnerId'");

    if (chatId != activeChat) {

      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$chatPartnerId.newMessages', JSON_VALUE(users, '\$.$chatPartnerId.newMessages') + 1)",
          "WHERE id = '${chatData["id"]}'");

    }
  }

  addAdminMessage(message, user) {
    var url = Uri.parse(databaseUrl + databasePathNewAdminMessage);
    http.post(url, body: json.encode({"message": message, "user": user}));

    url = Uri.parse(databaseUrl + "services/sendEmail.php");
    http.post(url,
        body: json.encode({
          "to": "dominik.mast.11@gmail.com",
          "title": "Feedback zu families worldwide",
          "inhalt": message
        }));
  }

  deleteChat(chatId) {
    _deleteInTable("chats", "id", chatId);
  }

  deleteMessages(messageId) {
    _deleteInTable("messages", "id", messageId);
  }

  deleteAllMessages(chatId) {
    _deleteInTable("messages", "chatId", chatId);
  }
}

class ChatGroupsDatabase {
  addNewChatGroup(user, connectedString) async {
    var date = DateTime.now().millisecondsSinceEpoch;
    var groupData = {
      "lastMessageDate": date,
      "lastMessage": "</neuer Chat",
      "users": json.encode(user == null
          ? {}
          : {
              user: {"newMessages": 0}
            }),
      "connected": connectedString ?? ""
    };

    var url = Uri.parse(databaseUrl + databasePathNewChatGroup);
    var response = await http.post(url, body: json.encode(groupData));
    var chatGroupId = response.body;

    if (chatGroupId.isEmpty) return null;

    groupData["id"] = chatGroupId;
    groupData["users"] = user == null
        ? {}
        : {
            user: {"newMessages": 0}
          };

    var chatGroups = Hive.box("secureBox").get("chatGroups") ?? [];
    chatGroups.add(groupData);
    var myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
    myGroupChats.add(groupData);

    return groupData;
  }

  getChatData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": whatData,
          "queryEnd": queryEnd,
          "table": "chat_groups"
        }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);
    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  updateChatGroup(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode({
          "table": "chat_groups",
          "whatData": whatData,
          "queryEnd": queryEnd
        }));
  }

  getAllChatMessages(chatId) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": "*",
          "queryEnd": "WHERE chatId = '$chatId'",
          "table": "group_messages"
        }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    return responseBody;
  }

  updateMessage(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode({
          "table": "group_messages",
          "whatData": whatData,
          "queryEnd": queryEnd
        }));
  }

  addNewMessageAndNotification(chatId, messageData, chatGroupName) async {
    var chatgroupData = await getChatData("*", "WHERE id = '$chatId'");
    var date = DateTime.now().millisecondsSinceEpoch;

    messageData["message"] = messageData["message"].replaceAll("'", "\\'");

    var url = Uri.parse(databaseUrl + databasePathChatGroupNewMessage);
    await http.post(url,
        body: json.encode({
          "chatId": chatId,
          "date": date,
          "message": messageData["message"],
          "von": messageData["von"],
          "responseId": messageData["responseId"],
          "forward": messageData["forward"],
          "language": messageData["language"]
        }));

    _addNotificationCounterAndSendNotification(
        messageData, chatgroupData, chatGroupName);
  }

  _addNotificationCounterAndSendNotification(
      message, chatData, chatGroupName) async {
    var allUser = chatData["users"];
    var whatQuery = "users = JSON_SET(users";
    List notificationList = [];

    allUser.forEach((userId, data) {
      var isActive = data["isActive"] ?? false;
      isActive = isActive == 1 ? true : false;
      var isMute = chatData["users"][userId]["mute"] ?? false;

      if (!isActive) {
        chatData["users"][userId]["newMessages"] += 1;
        whatQuery +=
            ",'\$.$userId.newMessages', JSON_VALUE(users, '\$.$userId.newMessages') + 1)";

        if(!isMute) notificationList.add(userId);
      }
    });

    prepareChatGroupNotification(
        chatId: chatData["id"],
        idList: notificationList,
        inhalt: message["message"],
        chatGroup: chatGroupName);

    whatQuery += ")";
    ChatGroupsDatabase()
        .updateChatGroup(whatQuery, "WHERE id = '${chatData["id"]}'");
  }

  deleteChat(chatId) {
    _deleteInTable("chat_groups", "id", chatId);
    _deleteInTable("group_messages", "chatId", chatId);

    var chatGroups = Hive.box("secureBox").get("chatGroups") ?? [];
    chatGroups.removeWhere((chatGroup) => chatGroup["id"] == chatId);

    var myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
    myGroupChats.removeWhere((chatGroup) => chatGroup["id"] == chatId);
  }

  deleteMessages(messageId) {
    _deleteInTable("group_messages", "id", messageId);
  }

  deleteAllMessages(chatId) {
    _deleteInTable("group_messages", "chatId", chatId);
  }

  joinAndCreateCityChat(cityName) async {
    var userId = FirebaseAuth.instance.currentUser.uid;

    var city = getCityFromHive(cityName: cityName);

    if (city == null) return;

    var cityId = city["id"];
    var chatGroupData = getChatGroupFromHive("</stadt=$cityId");

    if (chatGroupData == null) {
      chatGroupData = await ChatGroupsDatabase()
          .getChatData("*", "WHERE connected = '</stadt=$cityId'");
      if (chatGroupData == false) {
        chatGroupData =
            await ChatGroupsDatabase().addNewChatGroup(null, "</stadt=$cityId");
      }
    }

    var newUserInformation = {"newMessages": 0};
    chatGroupData["users"][userId] = newUserInformation;

    await ChatGroupsDatabase().updateChatGroup(
        "users = JSON_MERGE_PATCH(users, '${json.encode({
              userId: newUserInformation
            })}')",
        "WHERE id = ${chatGroupData["id"]}");

    var myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
    myGroupChats.add(chatGroupData);
  }

  leaveChat(connectedId) {
    var myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
    var userId = FirebaseAuth.instance.currentUser.uid;

    myGroupChats.removeWhere(
        (chat) => chat["connected"].split("=")[1] == connectedId.toString());

    ChatGroupsDatabase().updateChatGroup(
        "users = JSON_REMOVE(users, '\$.$userId')",
        "WHERE connected LIKE '%$connectedId'");
  }
}

class MeetupDatabase {
  addNewMeetup(meetupData) async {
    var url = Uri.parse(databaseUrl + databasePathNewMeetUp);
    await http.post(url, body: json.encode(meetupData));

    meetupData["freischalten"] = [];
    meetupData["eventInterval"] = meetupData["interval"];
    meetupData["bis"] = meetupData["bis"] == "null" ? null : meetupData["bis"];
    meetupData["absage"] = [];
    meetupData["zusage"] = [];
    meetupData["freigegeben"] = [];
    meetupData["sprache"] = jsonDecode(meetupData["sprache"]);
    meetupData["interesse"] = jsonDecode(meetupData["interesse"]);
    meetupData["tags"] = [];

    var myOwnMeetups = Hive.box('secureBox').get("myEvents") ?? [];
    myOwnMeetups.add(meetupData);
    var meetups = Hive.box('secureBox').get("events") ?? [];
    meetups.add(meetupData);
  }

  update(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode(
            {"table": "events", "whatData": whatData, "queryEnd": queryEnd}));
  }

  updateLocation(id, locationData) async {
    var url = Uri.parse(databaseUrl + databasePathMeetupLocationUpdate);

    await http.post(url,
        body: json.encode({
          "id": id,
          "stadt": locationData["city"],
          "land": locationData["countryname"],
          "latt": locationData["latt"],
          "longt": locationData["longt"]
        }));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode(
            {"whatData": whatData, "queryEnd": queryEnd, "table": "events"}));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);
    responseBody = jsonDecode(responseBody);

    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  delete(meetupId) {
    _deleteInTable("events", "id", meetupId);

    List myMeetups = Hive.box('secureBox').get("myEvents") ?? [];
    myMeetups.removeWhere((meetup) => meetup["id"] == meetupId);
  }
}

class CommunityDatabase {
  addNewCommunity(communityData) async {
    var url = Uri.parse(databaseUrl + databasePathNewCommunity);
    await http.post(url, body: json.encode(communityData));

    communityData["bild"] = "assets/bilder/village.jpg";
    communityData["interesse"] = [];
    communityData["members"] = [];
    communityData["einladung"] = [];

    var allCommunities = Hive.box('secureBox').get("communities") ?? [];
    allCommunities.add(communityData);
  }

  update(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode({
          "table": "communities",
          "whatData": whatData,
          "queryEnd": queryEnd
        }));
  }

  updateLocation(id, locationData) async {
    var url =
        Uri.parse(databaseUrl + databasePathCommunityLocationUpdate);

    await http.post(url,
        body: json.encode({
          "id": id,
          "ort": locationData["city"],
          "land": locationData["countryname"],
          "latt": locationData["latt"],
          "longt": locationData["longt"]
        }));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": whatData,
          "queryEnd": queryEnd,
          "table": "communities"
        }));

    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  delete(communityId) async {
    await _deleteInTable("communities", "id", communityId);
  }
}

class StadtinfoDatabase {
  addNewCity(city) async {
    if (city["ort"] == null) {
      city["ort"] = city["city"];
      city["land"] = city["countryname"];
    }

    if (!await _checkIfNew(city)) return false;

    var url = Uri.parse(databaseUrl + databasePathNewCity);
    var cityId = await http.post(url, body: json.encode(city));
    var newCityInfo = {
      "id": cityId.body,
      "ort": city["ort"],
      "land": city["land"],
      "latt": city["latt"],
      "longt": city["longt"],
      "isCity": 1,
      "familien": []
    };

    var stadtInfos = Hive.box('secureBox').get("stadtinfo");
    stadtInfos.add(newCityInfo);

    return newCityInfo;
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": whatData,
          "queryEnd": queryEnd,
          "table": "stadtinfo"
        }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);
    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  update(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode({
          "table": "stadtinfo",
          "whatData": whatData,
          "queryEnd": queryEnd
        }));
  }

  _checkIfNew(city) async {
    var allCities = await getData("*", "", returnList: true);

    for (var cityDB in allCities) {
      if (cityDB["ort"].contains(city["ort"])) return false;

      if (cityDB["latt"] == city["latt"] && cityDB["longt"] == city["longt"]) {
        var name = cityDB["ort"] + " / " + city["ort"];
        var id = cityDB["id"];

        update("ort = '$name'", "WHERE id = '$id'");
        return false;
      }
    }

    return true;
  }
}

class StadtinfoUserDatabase {
  addNewInformation(stadtinformation) async {
    var userId = FirebaseAuth.instance.currentUser.uid;
    var url =
        Uri.parse(databaseUrl + databasePathNewCityInformation);
    stadtinformation["erstelltVon"] = userId;

    await http.post(url, body: json.encode(stadtinformation));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": whatData,
          "queryEnd": queryEnd,
          "table": "stadtinfo_user"
        }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);
    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  update(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode({
          "table": "stadtinfo_user",
          "whatData": whatData,
          "queryEnd": queryEnd
        }));
  }

  delete(informationId) {
    _deleteInTable("stadtinfo_user", "id", informationId);
  }
}

class AllgemeinDatabase {
  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": whatData,
          "queryEnd": queryEnd,
          "table": "allgemein"
        }));

    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);
    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }
}

class ReportsDatabase {
  add(von, title, beschreibung) async {
    var url = Uri.parse(databaseUrl + databasePathAddReport);
    await http.post(url,
        body: json.encode({
          "von": von,
          "title": title,
          "beschreibung": beschreibung,
        }));

    sendEmail({
      "title": "Eine Meldung ist eingegangen",
      "inhalt": """
      $title \n
      $beschreibung
      """
    });
  }
}

class FamiliesDatabase {
  addNewFamily(familyData) async {
    var url = Uri.parse(databaseUrl + databasePathNewFamily);
    await http.post(url, body: json.encode(familyData));
  }

  update(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode(
            {"table": "families", "whatData": whatData, "queryEnd": queryEnd}));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode(
            {"whatData": whatData, "queryEnd": queryEnd, "table": "families"}));

    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  delete(familyId) {
    _deleteInTable("families", "id", familyId);
  }
}

class NewsPageDatabase {
  addNewNews(news) async {
    var alreadyAvailable = await _checkIfInDatabase(news);
    if (alreadyAvailable) return false;

    var url = Uri.parse(databaseUrl + databasePathNewNews);
    news["erstelltAm"] = DateTime.now().toString();
    news["erstelltVon"] = FirebaseAuth.instance.currentUser.uid;

    await http.post(url, body: json.encode(news));

    return true;
  }

  _checkIfInDatabase(newNews) async {
    var userId = FirebaseAuth.instance.currentUser.uid;
    var allMyNews = await getData("*", "WHERE erstelltVon = '$userId'", returnList: true);
    if (allMyNews == false) allMyNews = [];

    for (var news in allMyNews) {
      var dateDifference =
          DateTime.now().difference(DateTime.parse(news["erstelltAm"])).inDays;
      news.removeWhere((key, value) =>
          key == "id" || key == "erstelltAm" || key == "erstelltVon");
      var checkNewNews = Map<String, dynamic>.of(newNews);
      var equality;

      try {
        checkNewNews["information"] = json.decode(checkNewNews["information"]);
        equality = foundation.mapEquals(
            news["information"], checkNewNews["information"]);
      } catch (_) {
        equality = checkNewNews["information"] == news["information"];
      }

      if (equality && dateDifference < 2) return true;
    }


    return false;
  }

  update(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode({
          "table": "news_page",
          "whatData": whatData,
          "queryEnd": queryEnd
        }));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": whatData,
          "queryEnd": queryEnd,
          "table": "news_page"
        }));

    dynamic responseBody = res.body;

    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  delete(newsId) {
    _deleteInTable("news_page", "id", newsId);
  }
}

class NewsSettingsDatabase {
  newProfil() async {
    var url = Uri.parse(databaseUrl + databasePathNewNewsProfil);
    var userId = FirebaseAuth.instance.currentUser.uid;

    await http.post(url, body: json.encode({"userId": userId}));
  }

  update(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode({
          "table": "news_settings",
          "whatData": whatData,
          "queryEnd": queryEnd
        }));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": whatData,
          "queryEnd": queryEnd,
          "table": "news_settings"
        }));

    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }

  delete(profilId) {
    _deleteInTable("news_settings", "id", profilId);
  }
}

class NotizDatabase{
  newNotize() async {
    var url = Uri.parse(databaseUrl + databasePathNewNotize);
    var userId = FirebaseAuth.instance.currentUser.uid;

    await http.post(url, body: json.encode({"id": userId}));
  }

  update(whatData, queryEnd) async {
    var url = Uri.parse(databaseUrl + databasePathUpdate);

    await http.post(url,
        body: json.encode({
          "table": "notizen",
          "whatData": whatData,
          "queryEnd": queryEnd
        }));

  }

  getData(whatData, queryEnd, {returnList = false}) async{
    var url = Uri.parse(databaseUrl + databasePathGetData);

    var res = await http.post(url,
        body: json.encode({
          "whatData": whatData,
          "queryEnd": queryEnd,
          "table": "notizen"
        }));

    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    if (responseBody.isEmpty) return false;

    for (var i = 0; i < responseBody.length; i++) {
      if (responseBody[i].keys.toList().length == 1) {
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for (var key in responseBody[i].keys.toList()) {
        try {
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        } catch (_) {}
      }
    }

    if (responseBody.length == 1 && !returnList) {
      responseBody = responseBody[0];
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {}
    }

    return responseBody;
  }
}

uploadImage(imagePath, imageName, image) async {
  var url = Uri.parse(databasePathUploadImage);
  var data = {
    "imagePath": imagePath,
    "imageName": imageName,
    "image": base64Encode(image),
  };

  try {
    await http.post(url, body: json.encode(data));
  } catch (_) {}
}

DbDeleteImage(imageName) async {
  var url = Uri.parse(databasePathDeleteImage);
  imageName = imageName.split("/").last;
  var data = {
    "imageName": imageName,
  };

  await http.post(url, body: json.encode(data));
}

_deleteInTable(table, whereParameter, whereValue) async {
  var url = Uri.parse(databaseUrl + databasePathDelete);

  await http.post(url,
      body: json.encode({
        "whereParameter": whereParameter,
        "whereValue": whereValue,
        "table": table
      }));
}


sortProfils(profils) {
  var allCountries = LocationService().getAllCountryNames();

  profils.sort((a, b) {
    var profilALand = a['land'];
    var profilBLand = b['land'];

    if (allCountries["eng"].contains(profilALand)) {
      var index = allCountries["eng"].indexOf(profilALand);
      profilALand = allCountries["ger"][index];
    }
    if (allCountries["eng"].contains(profilBLand)) {
      var index = allCountries["eng"].indexOf(profilBLand);
      profilBLand = allCountries["ger"][index];
    }

    int compareCountry = (profilBLand).compareTo(profilALand) as int;

    if (compareCountry != 0) return compareCountry;

    return b["ort"].compareTo(a["ort"]) as int;
  });

  return profils;
}

getAllActiveProfilsHive(){
  var allProfils = Hive.box('secureBox').get("profils");
  List allActiveProfils = [];

  for(var profil in allProfils){
    profil["lastLogin"] = profil["lastLogin"] ?? DateTime.parse("2022-02-13");
    var monthsUntilInactive = 3;
    var timeDifference = Duration(
        microseconds: (DateTime.now().microsecondsSinceEpoch -
            DateTime.parse(profil["lastLogin"].toString())
                .microsecondsSinceEpoch)
            .abs());
    var monthDifference = timeDifference.inDays / 30.44;

    if(monthDifference < monthsUntilInactive) allActiveProfils.add(profil);
  }

  return allActiveProfils;
}

getProfilFromHive(
    {profilId, profilName, getNameOnly = false, getIdOnly = false, onlyActive = false}) {
  var allProfils = onlyActive ? getAllActiveProfilsHive() : Hive.box('secureBox').get("profils");

  if (profilId != null) {
    for (var profil in allProfils) {
      if (profilId == profil["id"]) {
        if (getNameOnly) return profil["name"];
        return profil;
      }
    }
  } else if (profilName != null) {
    for (var profil in allProfils) {
      if (profilName == profil["name"]) {
        if (getIdOnly) return profil["id"];
        return profil;
      }
    }
  }
}

getAllProfilNames() {
  var allNames = [];

  var allProfils = Hive.box('secureBox').get("profils");
  for (var profil in allProfils) {
    allNames.add(profil["name"]);
  }

  return allNames;
}

getChatFromHive(chatId) {
  var myChats = Hive.box('secureBox').get("myChats");
  var myChatGroups = Hive.box('secureBox').get("myGroupChats");

  for (var myChat in myChats) {
    if (myChat["id"] == chatId) return myChat;
  }

  for (var myChatGroup in myChatGroups) {
    if (myChatGroup["id"] == chatId) return myChatGroup;
  }
}

getChatGroupFromHive(connectedId) {
  var chatGroups = Hive.box('secureBox').get("chatGroups") ?? [];

  if (connectedId.isEmpty) {
    var worldChat = chatGroups.singleWhere((chatGroup) => chatGroup["id"] == 1);
    return worldChat;
  }

  for (var chatGroup in chatGroups) {
    if (chatGroup["connected"].isEmpty) continue;
    if (chatGroup["connected"].split("=")[1] == connectedId) return chatGroup;
  }
}

getMeetupFromHive(meetupId) {
  var meetups = Hive.box('secureBox').get("events");

  for (var meetup in meetups) {
    if (meetup["id"] == meetupId) return meetup;
  }

  return {};
}

getCommunityFromHive(communityId) {
  var communities = Hive.box('secureBox').get("communities");

  for (var community in communities) {
    if (community["id"] == communityId) return community;
  }

  return {};
}

getCityFromHive({cityId, cityName, getName = false}) {
  var stadtInfos = Hive.box('secureBox').get("stadtinfo");
  cityName ??= "XXXXXX";

  for (var stadtInfo in stadtInfos) {
    if (stadtInfo["id"].toString() == cityId ||
        stadtInfo["ort"].contains(cityName)) {
      if (getName) {
        return stadtInfo["ort"];
      }

      return stadtInfo;
    }
  }
}

getCityUserInfoFromHive(cityName) {
  var stadtUserInfos = Hive.box('secureBox').get("stadtinfoUser");
  var infos = [];

  for (var info in stadtUserInfos) {
    if (cityName.contains(info["ort"])) infos.add(info);
  }

  return infos;
}

getFamilyProfil({familyId, familyMember}) {
  var familyProfils = Hive.box('secureBox').get("familyProfils") ?? [];

  for (var familyProfil in familyProfils) {
    if(familyProfil["name"].isEmpty) continue;

    if (familyId != null && familyId == familyProfil["id"]){
      return familyProfil;
    }

    if (familyMember != null && familyProfil["members"].contains(familyMember)) {
      return familyProfil;
    }
  }
}

getNewsId(information) {
  var newsFeedData = Hive.box('secureBox').get("newsFeed") ?? [];

  for (var news in newsFeedData) {
    if (news["information"] == information) return news["id"];
  }
}


updateHiveOwnProfil(changeTyp, changeData) {
  var ownProfil = Hive.box("secureBox").get("ownProfil");
  ownProfil[changeTyp] = changeData;
}

updateHiveCommunity(id, changeTyp, changeData) {
  var community = getCommunityFromHive(id);
  community[changeTyp] = changeData;
}

updateHiveMeetup(id, changeTyp, changeData) {
  var meetup = getMeetupFromHive(id);
  meetup[changeTyp] = changeData;
}


refreshHiveAllgemein() async {
  var dbAllgemein = await AllgemeinDatabase().getData("*", "WHERE id ='1'");
  if (dbAllgemein == false) dbAllgemein = [];

  Hive.box('secureBox').put("allgemein", dbAllgemein);

  return dbAllgemein;
}

refreshHiveChats() async {
  String userId = FirebaseAuth.instance.currentUser?.uid;

  var myChatData = await ChatDatabase().getChatData(
      "*", "WHERE id like '%$userId%' ORDER BY lastMessageDate DESC",
      returnList: true);
  if (myChatData == false) myChatData = [];

  Hive.box("secureBox").put("myChats", myChatData);

  var chatGroups = await ChatGroupsDatabase()
      .getChatData("*", "ORDER BY lastMessageDate DESC", returnList: true);
  if (chatGroups == false) chatGroups = [];

  Hive.box("secureBox").put("chatGroups", chatGroups);

  var myGroupChats = [];

  if (userId == null) return;

  for (var chat in chatGroups) {
    if (chat["users"].keys.contains(userId)) myGroupChats.add(chat);
  }

  Hive.box("secureBox").put("myGroupChats", myGroupChats);
}

refreshHiveMeetups() async {
  var meetups =
      await MeetupDatabase().getData("*", "ORDER BY wann ASC", returnList: true);
  if (meetups == false) meetups = [];
  Hive.box("secureBox").put("events", meetups);

  var userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  var ownMeetups = [];
  var myInterestedMeetups = [];
  for (var meetup in meetups) {
    if (meetup["erstelltVon"] == userId) ownMeetups.add(meetup);
    if (meetup["interesse"].contains(userId) && meetup["erstelltVon"] != userId) {
      myInterestedMeetups.add(meetup);
    }
  }

  Hive.box('secureBox').put("myEvents", ownMeetups);
  Hive.box('secureBox').put("interestEvents", myInterestedMeetups);
}

refreshHiveProfils() async {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var ownProfil = {};

  List<dynamic> dbProfils = await ProfilDatabase()
      .getData("*", "WHERE name != 'googleView' ORDER BY ort ASC");
  if (dbProfils == false) dbProfils = [];
  dbProfils = sortProfils(dbProfils);

  for (var profil in dbProfils) {
    profil = decryptProfil(profil);
    if (profil["id"] == userId) ownProfil = profil;
  }

  Hive.box('secureBox').put("profils", dbProfils);

  if (userId != null && userId.isNotEmpty){
    Hive.box('secureBox').put("ownProfil", ownProfil);
  }


}

refreshHiveCommunities() async {
  dynamic dbCommunities = await CommunityDatabase()
      .getData("*", "ORDER BY ort ASC", returnList: true);
  if (dbCommunities == false) dbCommunities = [];

  dbCommunities.sort((m1, m2) {
    DateTime dt1 = DateTime.parse(m1["erstelltAm"]);
    DateTime dt2 = DateTime.parse(m2["erstelltAm"]);

    var r = dt2.compareTo(dt1);
    if (r != 0) return r;
    return dt2.compareTo(dt1);
  });

  Hive.box('secureBox').put("communities", dbCommunities);
}

refreshHiveNewsPage() async {
  List<dynamic> dbNewsData = await NewsPageDatabase()
      .getData("*", "ORDER BY erstelltAm ASC", returnList: true);
  if (dbNewsData == false) dbNewsData = [];

  Hive.box('secureBox').put("newsFeed", dbNewsData);

  refreshHiveNewsSetting();

}

refreshHiveNewsSetting() async{
  var userId = FirebaseAuth.instance.currentUser?.uid;
  if(userId == null) return;
  var ownNewsSetting = await NewsSettingsDatabase().getData("*", "WHERE id = '$userId'");

  Hive.box('secureBox').put("ownNewsSetting", ownNewsSetting);
}

refreshHiveStadtInfo() async {
  var stadtinfo = await StadtinfoDatabase()
      .getData("*", "ORDER BY ort ASC", returnList: true);
  Hive.box("secureBox").put("stadtinfo", stadtinfo);
}

refreshHiveStadtInfoUser() async {
  var stadtinfoUser =
      await StadtinfoUserDatabase().getData("*", "", returnList: true);
  Hive.box("secureBox").put("stadtinfoUser", stadtinfoUser);
}

refreshHiveFamilyProfils() async {
  var familyProfils =
      await FamiliesDatabase().getData("*", "", returnList: true);
  if (familyProfils == false) familyProfils = [];
  Hive.box("secureBox").put("familyProfils", familyProfils);
}

decryptProfil(profil){
  try{
    profil["email"] = decrypt(profil["email"]);
  }catch(_){

  }

  return profil;
}