import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import '../auth/secrets.dart';
import '../global/global_functions.dart'as global_functions;


//var databaseUrl = "https://families-worldwide.com/";
var databaseUrl = "http://test.families-worldwide.com/";
var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";

class AllgemeinDatabase{

  getData(whatData, queryEnd, {returnList = false}) async {
    //neue Datenabfrage um alle get zu ersetzen
    queryEnd = Uri.encodeComponent(queryEnd);
    var url = databaseUrl + "database/getData.php";
    var data = "?param1=$whatData&param2=$queryEnd&param3=allgemein";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    dynamic responseBody = res.body;

    responseBody = jsonDecode(responseBody);
    if(responseBody.isEmpty) return false;

    for(var i = 0; i < responseBody.length; i++){

      if(responseBody[i].keys.toList().length == 1){
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for(var key in responseBody[i].keys.toList()){
        try{
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        }catch(error){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(error){}
    }

    return responseBody;
  }

  getOneData(what, queryEnd) async{
    var url = databaseUrl + "database/allgemein/getOneData.php";
    var data = "?param1=$what";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    dynamic responseBody = res.body;

    try{
      responseBody = jsonDecode(responseBody);
    }catch(error){

    }


    return responseBody;
  }

}

class ProfilDatabase{

  addNewProfil(profilData) async{
    var url = Uri.parse(databaseUrl + "database/profils/newProfil.php");
    await http.post(url, body: json.encode({
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
    }));

    FirebaseAuth.instance.currentUser.updateDisplayName(profilData["name"]);
  }

  updateProfil(userId, change,  data) async {
    var url = Uri.parse(databaseUrl + "database/profils/changeProfil.php");

    if(data is List){
      data = json.encode(data);
    }

    await http.post(url, body: json.encode({
      "id": userId,
      "change": change,
      "data": data
    }));
  }

  getData(whatData, queryEnd, {returnList = false}) async{
    //neue Datenabfrage um alle get zu ersetzen
    queryEnd = Uri.encodeComponent(queryEnd);
    var url = databaseUrl + "database/getData.php";
    var data = "?param1=$whatData&param2=$queryEnd&param3=profils";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    dynamic responseBody = res.body;

    responseBody = jsonDecode(responseBody);
    if(responseBody.isEmpty) return false;

    for(var i = 0; i < responseBody.length; i++){

      if(responseBody[i].keys.toList().length == 1){
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for(var key in responseBody[i].keys.toList()){
        try{
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        }catch(error){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(error){}
    }

    return responseBody;
  }

  updateProfilName(userId, oldName, newName) async{
    FirebaseAuth.instance.currentUser.updateDisplayName(newName);

    updateProfil(userId, "name", newName);
  }

  updateProfilLocation(userId, locationDict) {
    var url = Uri.parse(databaseUrl + "database/profils/updateProfilLocation.php");

    http.post(url, body: json.encode({
      "id": userId,
      "land": locationDict["land"],
      "city": locationDict["ort"],
      "longt":locationDict["longt"],
      "latt": locationDict["latt"]
    }));
  }

  deleteProfil(userId) async {
    FirebaseAuth.instance.currentUser.delete();

    _deleteInTable("profils", userId);

    var allChatGroups = await ChatDatabase().getChatData("*", "WHERE id like '%$userId%'");
    for (var chat in allChatGroups){
      var chatId = chat["id"];
      _deleteInTable("messages", chatId);
      _deleteInTable("chats", chatId);
    }

  }

}

class ChatDatabase{

  addNewChatGroup(users, messageData)async {
    var userKeysList = users.keys.toList();
    var usersList = users.values.toList();
    var chatID = global_functions.getChatID(userKeysList);
    var date = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    var newChatGroup = {
      "id": chatID,
      "date": date,
      "users": json.encode({
        userKeysList[0] : {"name": usersList[0], "newMessages": 0},
        userKeysList[1] : {"name": usersList[1], "newMessages": 0},
      }),
      "lastMessage": messageData["message"],
    };

    var url = Uri.parse(databaseUrl + "database/chats/newChatGroup.php");
    await http.post(url, body: json.encode(newChatGroup));


    messageData = {
      "id": chatID,
      "date": date,
      "message": messageData["message"],
      "von": messageData["von"],
      "zu": messageData["zu"]
    };

    await addNewMessageAndSendNotification(newChatGroup, messageData);

    return newChatGroup;
  }

  getChatData(whatData, queryEnd, {returnList = false}) async{
    //neue Datenabfrage um alle chat get zu ersetzen

    queryEnd = Uri.encodeComponent(queryEnd);
    var url = databaseUrl + "database/getData.php";
    var data = "?param1=$whatData&param2=$queryEnd&param3=chats";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    dynamic responseBody = res.body;

    responseBody = jsonDecode(responseBody);
    if(responseBody.isEmpty) return false;

    for(var i = 0; i < responseBody.length; i++){

      if(responseBody[i].keys.toList().length == 1){
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for(var key in responseBody[i].keys.toList()){

        try{
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        }catch(error){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(error){}
    }

    return responseBody;
  }

  getAllMessages(chatId) async {
    var url = databaseUrl + "database/chats/getAllMessages.php";
    var data = "?param1=$chatId";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});

    var responseBody = json.decode(res.body);

    return responseBody;
  }

  updateChatGroup(chatId, change, data)async{
    var url = Uri.parse(databaseUrl + "database/chats/updateChat.php");

    if(data is Map){
      data = json.encode(data);
    }

    await http.post(url, body: json.encode({
      "id": chatId,
      "change": change,
      "data": data
    }));

  }

  addNewMessageAndSendNotification(chatgroupData, messageData)async {
    var users = chatgroupData["users"];
    if(users is String) users = jsonDecode(chatgroupData["users"]);
    users = users.keys.toList();
    var chatID = global_functions.getChatID(users);
    var date = DateTime.now().millisecondsSinceEpoch;

    messageData["message"] = messageData["message"].replaceAll("'" , "\\'");

    var url = Uri.parse(databaseUrl + "database/chats/newMessage.php");
    await http.post(url, body: json.encode({
      "id": chatID,
      "date": date,
      "message": messageData["message"],
      "von": messageData["von"],
      "zu": messageData["zu"]
    }));


    _changeNewMessageCounter(messageData["zu"], chatgroupData);

    sendChatNotification(chatID, messageData);
  }

  _changeNewMessageCounter(chatPartnerId, chatData) async{
    var dbData = await ProfilDatabase().getData("activeChat, newMessages", "WHERE id = '$chatPartnerId'");
    var activeChat = dbData["activeChat"];
    var allNewMessages = dbData["newMessages"];


    if(chatData["id"] != activeChat){
      ProfilDatabase().updateProfil(chatPartnerId, "newMessages", allNewMessages +1);

      var chatId = chatData['id'];
      var oldChatNewMessages = await ChatDatabase().getChatData("users", "WHERE id = '$chatId'");

      oldChatNewMessages[chatPartnerId]["newMessages"] = oldChatNewMessages[chatPartnerId]["newMessages"] +1;

      ChatDatabase().updateChatGroup(chatData["id"], "users", oldChatNewMessages);

    }

  }

  addAdminMessage(message, user) {
    var url = Uri.parse(databaseUrl + "database/chats/addAdminMessage.php");
    http.post(url, body: json.encode({
      "message": message,
      "user": user
    }));

    url = Uri.parse(databaseUrl + "services/sendEmail.php");
    http.post(url, body: json.encode({
      "to": "dominik.mast.11@gmail.com",
      "title": "Feedback zu families worldwide",
      "inhalt": message
    }));

  }

}

class EventDatabase{

  addNewEvent(eventData) async {
    var url = Uri.parse(databaseUrl + "database/events/newEvent.php");
    await http.post(url, body: json.encode(eventData));

  }

  update(id, changes) async  {
    var url = Uri.parse(databaseUrl + "database/events/updateEvent.php");

    await http.post(url, body: json.encode({
      "id": id,
      "changes": changes
    }));
  }

  updateLocation(id, locationData) {
    var url = Uri.parse(databaseUrl + "database/events/changeLocation.php");

    http.post(url, body: json.encode({
      "id": id,
      "stadt": locationData["city"],
      "land": locationData["countryname"],
      "latt": locationData["latt"],
      "longt": locationData["longt"]
    }));
  }

  getData(whatData, queryEnd, {returnList = false}) async{
    //neue Datenabfrage um alle get zu ersetzen
    queryEnd = Uri.encodeComponent(queryEnd);
    var url = databaseUrl + "database/getData.php";
    var data = "?param1=$whatData&param2=$queryEnd&param3=events";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});

    dynamic responseBody = res.body;
    responseBody = jsonDecode(responseBody);

    if(responseBody.isEmpty) return false;

    for(var i = 0; i < responseBody.length; i++){

      if(responseBody[i].keys.toList().length == 1){
        var key = responseBody[i].keys.toList()[0];
        responseBody[i] = responseBody[i][key];
        continue;
      }

      for(var key in responseBody[i].keys.toList()){

        try{
          responseBody[i][key] = jsonDecode(responseBody[i][key]);
        }catch(error){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(error){}
    }


    return responseBody;
  }

  delete(eventId){
    _deleteInTable("events", eventId);
  }

}

class ReportsDatabase{

  add(von, title, beschreibung){
    var url = Uri.parse(databaseUrl + "database/reports/addReport.php");
    http.post(url, body: json.encode({
      "von": von,
      "title": title,
      "beschreibung": beschreibung ,
    }));
  }

}


sendChatNotification(chatId, messageData) async {
  var toActiveChat = await ProfilDatabase()
      .getData("activeChat", "WHERE id = '${messageData["zu"]}'");

  if(toActiveChat == chatId) return;


  var fromName = await ProfilDatabase()
      .getData("name", "WHERE id = '${messageData["von"]}'");
  var toToken = await ProfilDatabase()
      .getData("token", "WHERE id = '${messageData["zu"]}'");
  var chatPartnerName = await ProfilDatabase()
      .getData("name", "WHERE id = '${messageData["zu"]}'");


  var notificationInformation = {
    "toId": messageData["zu"],
    "toName": chatPartnerName,
    "typ" : "chat",
    "title": fromName,
    "inhalt": messageData["message"],
    "changePageId": chatId,
    "token": toToken,
  };

  sendNotification(notificationInformation);


}

sendNotification(notificationInformation) async {
    var notificationsAllowed = await ProfilDatabase()
        .getData("notificationstatus", "WHERE id = '${notificationInformation["toId"]}'");

    if(notificationsAllowed == 0) return;

    if(notificationInformation["token"] == "" || notificationInformation["token"] == null){
      var emailAdresse = await ProfilDatabase()
          .getData("email", "WHERE id = '${notificationInformation["toId"]}'");

      if(notificationInformation["typ"] == "chat"){
        var url = Uri.parse(databaseUrl + "services/sendEmail.php");
        http.post(url, body: json.encode({
          "to": emailAdresse,
          "title": notificationInformation["title"] + (spracheIstDeutsch ?
          " hat dir eine Nachricht geschrieben": " has written you a message"),
          "inhalt": "Hi ${notificationInformation["toName"]},\n\n" +
              (spracheIstDeutsch ?
              "du hast in der families worldwide App folgende Nachricht von "
                  "${notificationInformation["title"]} erhalten: \n\n" :
              "you have received the following message from "
                  "${notificationInformation["title"]} in the families worldwide app: \n\n"
              ) +
              "${notificationInformation["inhalt"]}"
        }));
      }else if(notificationInformation["typ"] == "event"){
        var url = Uri.parse(databaseUrl + "services/sendEmail.php");
        http.post(url, body: json.encode({
          "to": emailAdresse,
          "title": notificationInformation["title"],
          "inhalt": notificationInformation["inhalt"]
        }));
      }
    }else{
      var url = Uri.parse(databaseUrl + "services/sendNotification.php");
      http.post(url, body: json.encode({
        "to": notificationInformation["token"],
        "title": notificationInformation["title"],
        "inhalt": notificationInformation["inhalt"],
        "changePageId": notificationInformation["changePageId"],
        "apiKey": firebaseWebKey,
        "typ": notificationInformation["typ"]
      }));
    }

}

_deleteInTable(table, id) {
  var url = Uri.parse(databaseUrl + "database/deleteAll.php");

  http.post(url, body: json.encode({
    "id": id,
    "table": table
  }));
}

