import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:encrypt/encrypt.dart';

import '../auth/secrets.dart';
import '../global/global_functions.dart'as global_functions;


//var databaseUrl = "https://families-worldwide.com/";
var databaseUrl = "http://test.families-worldwide.com/";
var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";



class ProfilDatabase{

  addNewProfil(profilData) async{
    var url = Uri.parse(databaseUrl + "database/profils/newProfil.php");
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
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "profils",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));
  }

  getData(whatData, queryEnd, {returnList = false}) async{
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "profils"
    }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

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
        }catch(_){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(_){}
    }

    return responseBody;

  }

  updateProfilName(userId, oldName, newName) async{
    FirebaseAuth.instance.currentUser.updateDisplayName(newName);

    updateProfil("name = '$newName'", "WHERE id = '$userId'");
  }

  updateProfilLocation(userId, locationDict) async {
    var url = Uri.parse(databaseUrl + "database/profils/updateProfilLocation.php");

    await http.post(url, body: json.encode({
      "id": userId,
      "land": locationDict["land"],
      "city": locationDict["ort"],
      "longt":locationDict["longt"],
      "latt": locationDict["latt"]
    }));
  }

  deleteProfil(userId) async {
    try{
      FirebaseAuth.instance.currentUser.delete();
    }catch(_){
      return false;
    }


    _deleteInTable("profils", userId);

    updateProfil(
        "friendlist = JSON_REMOVE(friendlist, JSON_UNQUOTE(JSON_SEARCH(friendlist, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(friendlist, '\"$userId\"') > 0"
    );

    var userEvents = await EventDatabase().getData("id", "WHERE erstelltVon = '$userId'", returnList: true);
    for(var eventId in userEvents){
      _deleteInTable("events", eventId);
    }

    EventDatabase().update(
        "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(interesse, '\"$userId\"') > 0"
    );

    EventDatabase().update(
        "zusage = JSON_REMOVE(zusage, JSON_UNQUOTE(JSON_SEARCH(zusage, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(zusage, '\"$userId\"') > 0"
    );

    EventDatabase().update(
        "absage = JSON_REMOVE(absage, JSON_UNQUOTE(JSON_SEARCH(absage, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(absage, '\"$userId\"') > 0"
    );

    EventDatabase().update(
        "freischalten = JSON_REMOVE(freischalten, JSON_UNQUOTE(JSON_SEARCH(freischalten, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(freischalten, '\"$userId\"') > 0"
    );

    EventDatabase().update(
        "freigegeben = JSON_REMOVE(freigegeben, JSON_UNQUOTE(JSON_SEARCH(freigegeben, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(freigegeben, '\"$userId\"') > 0"
    );


    Hive.box("ownProfilBox").deleteFromDisk();
    Hive.box("profilBox").deleteFromDisk();
    Hive.box("eventBox").deleteFromDisk();
    Hive.box("myEventsBox").deleteFromDisk();
    Hive.box("interestEventsBox").deleteFromDisk();
    Hive.box("myChatBox").deleteFromDisk();
    Hive.box("stadtinfoUserBox").deleteFromDisk();
    Hive.box("stadtinfoBox").deleteFromDisk();


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
    var url = Uri.parse(databaseUrl + "database/getData2.php");
    //queryEnd = Uri.encodeComponent(queryEnd);

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "chats"
    }));
    dynamic responseBody = res.body;

    responseBody = decrypt(responseBody);

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
        }catch(_){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(_){}
    }

    return responseBody;
  }

  getAllMessages(chatId) async {
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": "*",
      "queryEnd": "WHERE id = '$chatId'",
      "table": "messages"
    }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    return responseBody;

  }

  updateChatGroup(whatData,queryEnd ) async {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "chats",
      "whatData": whatData,
      "queryEnd": queryEnd
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
      ProfilDatabase().updateProfil("newMessages = '${allNewMessages +1}'", "WHERE id ='$chatPartnerId'");

      var chatId = chatData['id'];
      var oldChatNewMessages = await ChatDatabase().getChatData("users", "WHERE id = '$chatId'");

      oldChatNewMessages[chatPartnerId]["newMessages"] = oldChatNewMessages[chatPartnerId]["newMessages"] +1;

      ChatDatabase().updateChatGroup(
          "users = '${json.encode(oldChatNewMessages)}'",
          "WHERE id = '${chatData["id"]}'"
      );

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

  update(whatData, queryEnd) async  {
    var url = Uri.parse(databaseUrl + "database/update.php");

    var test = await http.post(url, body: json.encode({
      "table": "events",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));

    print(test.body);

  }

  updateLocation(id, locationData) async {
    var url = Uri.parse(databaseUrl + "database/events/changeLocation.php");

    await http.post(url, body: json.encode({
      "id": id,
      "stadt": locationData["city"],
      "land": locationData["countryname"],
      "latt": locationData["latt"],
      "longt": locationData["longt"]
    }));
  }

  getData(whatData, queryEnd, {returnList = false}) async{
    var url = Uri.parse(databaseUrl + "database/getData2.php");
    //queryEnd = Uri.encodeComponent(queryEnd);

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "events"
    }));

    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

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
        }catch(_){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(_){}
    }


    return responseBody;
  }

  delete(eventId){
    _deleteInTable("events", eventId);
  }

}

class StadtinfoDatabase{
  addNewCity(city) async {
    if(city["ort"] == null ){
      city["ort"] = city["city"];
      city["land"] = city["countryname"];
    }

    if(! await _checkIfNew(city)) return;

    var url = Uri.parse(databaseUrl + "database/stadtinfo/newCity.php");
    http.post(url, body: json.encode(city));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "stadtinfo"
    }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);


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
        }catch(_){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(_){}
    }

    return responseBody;
  }

  update(whatData, queryEnd) async  {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "stadtinfo",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));

  }

  _checkIfNew(city) async {
    var allCities = await getData("*", "", returnList: true);

    for(var cityDB in allCities){
      if(cityDB["ort"].contains(city["ort"])) return false;

      if(cityDB["latt"] == city["latt"] && cityDB["longt"] == city["longt"]){
        var name = cityDB["ort"] + " / " + city["ort"];
        var id = cityDB["id"];

        update("ort = '$name'", "WHERE id = '$id'");
        return false;
      }
    }


    return true;

  }
}

class StadtinfoUserDatabase{

  addNewInformation(stadtinformation) async {
    var userId = FirebaseAuth.instance.currentUser.uid;

    var url = Uri.parse(databaseUrl + "database/stadtinfoUser/newInformation.php");
    stadtinformation["erstelltVon"] = userId;

    await http.post(url, body: json.encode(stadtinformation));
  }

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "stadtinfo_user"
    }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

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
        }catch(_){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(_){}
    }

    return responseBody;
  }

  update(whatData, queryEnd) async  {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "stadtinfo_user",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));

  }


  delete(informationId){
    _deleteInTable("stadtinfo_user", informationId);
  }


}

class AllgemeinDatabase{

  getData(whatData, queryEnd, {returnList = false}) async {
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "allgemein"
    }));

    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

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
        }catch(_){

        }

      }
    }

    if(responseBody.length == 1 && !returnList){
      responseBody = responseBody[0];
      try{
        responseBody = jsonDecode(responseBody);
      }catch(_){}
    }

    return responseBody;
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
              "du hast in der families worldwide App eine neue Nachricht von "
                  "${notificationInformation["title"]} erhalten \n\n" :
              "you have received a new message from "
                  "${notificationInformation["title"]} in the families worldwide app \n\n"
              )
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


String decrypt(String encrypted) {
  final key = Key.fromUtf8(phpCryptoKey);
  final iv = IV.fromUtf8(phpCryptoIV);

  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  Encrypted enBase64 = Encrypted.from64(encrypted);
  final decrypted = encrypter.decrypt(enBase64, iv: iv);
  return decrypted;
}

