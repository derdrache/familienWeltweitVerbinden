import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:encrypt/encrypt.dart';

import '../auth/secrets.dart';
import '../global/global_functions.dart'as global_functions;
import 'locationsService.dart';
import 'notification.dart';

//var databaseUrl = "https://families-worldwide.com/";
var databaseUrl = "http://test.families-worldwide.com/";
var spracheIstDeutsch = kIsWeb ? ui.window.locale.languageCode == "de" : io.Platform.localeName == "de_DE";


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
      "land": locationDict["countryname"],
      "city": locationDict["city"],
      "longt":locationDict["longt"],
      "latt": locationDict["latt"]
    }));
  }

  deleteProfil(userId) async {
    try{
      await FirebaseAuth.instance.currentUser.delete();
    }catch(_){
      return false;
    }
    
    _deleteInTable("profils", "id", userId);
    _deleteInTable("newsSettings", "id",  userId);
    _deleteInTable("news_page", "id", userId);

    updateProfil(
        "friendlist = JSON_REMOVE(friendlist, JSON_UNQUOTE(JSON_SEARCH(friendlist, 'one', '$userId')))",
        "WHERE JSON_CONTAINS(friendlist, '\"$userId\"') > 0"
    );

    var userEvents = await EventDatabase().getData("id", "WHERE erstelltVon = '$userId'", returnList: true);
    if(userEvents != false){
      for(var eventId in userEvents){
        _deleteInTable("events", "id",  eventId);
      }
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

    Hive.box("secureBox").deleteFromDisk();

  }

}

class ChatDatabase{

  addNewChatGroup(chatPartner) {
    var userId = FirebaseAuth.instance.currentUser.uid;
    var userKeysList = [userId, chatPartner];
    var chatID = global_functions.getChatID(chatPartner);
    var date = DateTime.now().millisecondsSinceEpoch;
    var userData = {
      userKeysList[0] : {"newMessages": 0},
      userKeysList[1] : {"newMessages": 0},
    };

    var newChatGroup = {
      "id": chatID,
      "date": date,
      "users": json.encode(userData),
      "lastMessage": "",
    };

    var url = Uri.parse(databaseUrl + "database/chats/newChatGroup.php");
    http.post(url, body: json.encode(newChatGroup));

    newChatGroup["users"] = userData;

    return newChatGroup;
  }

  getChatData(whatData, queryEnd, {returnList = false}) async{
    var url = Uri.parse(databaseUrl + "database/getData2.php");

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

  getAllChatMessages(chatId) async {
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": "*",
      "queryEnd": "WHERE chatId = '$chatId'",
      "table": "messages"
    }));
    dynamic responseBody = res.body;
    responseBody = decrypt(responseBody);

    responseBody = jsonDecode(responseBody);

    return responseBody;

  }

  updateChatGroup(whatData,queryEnd) async {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "chats",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));
  }

  updateMessage(whatData,queryEnd) async{
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "messages",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));

  }

  addNewMessageAndSendNotification(chatgroupData, messageData, isBlocked)async {
    var chatID = chatgroupData["id"];
    var date = DateTime.now().millisecondsSinceEpoch;

    messageData["message"] = messageData["message"].replaceAll("'" , "\\'");

    var url = Uri.parse(databaseUrl + "database/chats/newMessage2.php");
    await http.post(url, body: json.encode({
      "chatId": chatID,
      "date": date,
      "message": messageData["message"],
      "von": messageData["von"],
      "zu": messageData["zu"],
      "responseId": messageData["responseId"],
      "forward": messageData["forward"]
    }));

    if(isBlocked) return;

    _changeNewMessageCounter(messageData["zu"], chatgroupData);

    prepareChatNotification(
      chatId: chatID,
      vonId: messageData["von"],
      toId: messageData["zu"],
      inhalt: messageData["message"]
    );
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
          "users = JSON_SET(users, '\$.$chatPartnerId.newMessages',${oldChatNewMessages[chatPartnerId]["newMessages"]})",
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

  deleteChat(chatId){
    _deleteInTable("chats", "id", chatId);
  }

  deleteMessages(messageId){
    _deleteInTable("messages", "id", messageId);
  }

  deleteAllMessages(chatId){
    _deleteInTable("messages", "chatId", chatId);
  }

}

class EventDatabase{

  addNewEvent(eventData) async {
    var url = Uri.parse(databaseUrl + "database/events/newEvent.php");
    await http.post(url, body: json.encode(eventData));
  }

  update(whatData, queryEnd) async  {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "events",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));

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
    _deleteInTable("events", "id", eventId);
  }

}

class CommunityDatabase{
  addNewCommunity(communityData) async {
    var url = Uri.parse(databaseUrl + "database/communities/newCommunity.php");
    await http.post(url, body: json.encode(communityData));
  }

  update(whatData, queryEnd) async  {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "communities",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));

  }

  updateLocation(id, locationData) async {
    var url = Uri.parse(databaseUrl + "database/communities/changeLocation.php");

    await http.post(url, body: json.encode({
      "id": id,
      "ort": locationData["city"],
      "land": locationData["countryname"],
      "latt": locationData["latt"],
      "longt": locationData["longt"]
    }));
  }

  getData(whatData, queryEnd, {returnList = false}) async{
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "communities"
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

  delete(communityId) async {
    await _deleteInTable("communities","id", communityId);
  }
}

class StadtinfoDatabase{

  addNewCity(city) async {
    if(city["ort"] == null ){
      city["ort"] = city["city"];
      city["land"] = city["countryname"];
    }

    if(! await _checkIfNew(city)) return false;

    var url = Uri.parse(databaseUrl + "database/stadtinfo/newCity.php");
    await http.post(url, body: json.encode(city));

    return true;
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
    _deleteInTable("stadtinfo_user","id", informationId);
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

    sendEmail({
      "title": "Eine Meldung ist eingegangen",
      "inhalt": """
      $title \n
      $beschreibung
      """
    });
  }


}

class FamiliesDatabase{
  addNewFamily(familyData) async {
    var url = Uri.parse(databaseUrl + "database/families/newFamily.php");
    await http.post(url, body: json.encode(familyData));
  }

  update(whatData, queryEnd) async  {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "families",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));

  }

  getData(whatData, queryEnd, {returnList = false}) async{
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "families"
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

  delete(familyId){
    _deleteInTable("families","id", familyId);
  }
}

class NewsPageDatabase{
  addNewNews(news) async{
    var url = Uri.parse(databaseUrl + "database/newsPage/newNews.php");
    news["erstelltAm"] = DateTime.now().toString();
    news["erstelltVon"] = FirebaseAuth.instance.currentUser.uid;

    await http.post(url, body: json.encode(news));
  }

  update(whatData, queryEnd) async  {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "news_page",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));

  }

  getData(whatData, queryEnd, {returnList = false}) async{
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "news_page"
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

  delete(newsId){
    _deleteInTable("news_page","id", newsId);
  }
}

class NewsSettingsDatabase{

  newProfil() async{
    var url = Uri.parse(databaseUrl + "database/newsSettings/newProfil.php");
    var userId = FirebaseAuth.instance.currentUser.uid;

    await http.post(url, body: json.encode({
      "userId" : userId
    }));

  }

  update(whatData, queryEnd) async  {
    var url = Uri.parse(databaseUrl + "database/update.php");

    await http.post(url, body: json.encode({
      "table": "news_settings",
      "whatData": whatData,
      "queryEnd": queryEnd
    }));
  }

  getData(whatData, queryEnd, {returnList = false}) async{
    var url = Uri.parse(databaseUrl + "database/getData2.php");

    var res = await http.post(url, body: json.encode({
      "whatData": whatData,
      "queryEnd": queryEnd,
      "table": "news_settings"
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

  delete(profilId){
    _deleteInTable("news_settings","id", profilId);
  }
}


uploadImage(imagePath, imageName, image) async{
  var url = Uri.parse("https://families-worldwide.com/database/uploadImage.php");
  var data = {
    "imagePath": imagePath,
    "imageName": imageName,
    "image": base64Encode(image),
  };

  try{
    //Web Version wirft nach vollendung ein Fehler auf => funktioniert aber ohne Probleme
    await http.post(url, body: json.encode(data));
  }catch(_){

  }

}

DbDeleteImage(imageName) async{
  var url = Uri.parse("https://families-worldwide.com/database/deleteImage.php");
  imageName = imageName.split("/").last;
  var data = {
    "imageName": imageName,
  };

  await http.post(url, body: json.encode(data));
}

_deleteInTable(table, whereParameter, whereValue) async {
  var url = Uri.parse(databaseUrl + "database/deleteAll2.php");

  await http.post(url, body: json.encode({
    "whereParameter": whereParameter,
    "whereValue": whereValue,
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

sortProfils(profils) {
  var allCountries = LocationService().getAllCountries();

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

getProfilFromHive({profilId, profilName, getNameOnly = false, getIdOnly = false}){
  var allProfils = Hive.box('secureBox').get("profils");

  if(profilId != null){
    for(var profil in allProfils){
      if(profilId == profil["id"]){
        if(getNameOnly) return profil["name"];
        return profil;
      }
    }
  }
  else if(profilName != null){
    for(var profil in allProfils){
      if(profilName == profil["name"]){
        if(getIdOnly) return profil["id"];
        return profil;
      }
    }
  }

}

getChatFromHive(chatId){
  var myChats = Hive.box('secureBox').get("myChats");

  for(var myChat in myChats){
    if(myChat["id"] == chatId) return myChat;
  }
}

getEventFromHive(eventId){
  var events = Hive.box('secureBox').get("events");

  for(var event in events){
    if(event["id"] == eventId) return event;
  }
}

refreshHiveChats() async {
  String userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) return;

  var myChatData = await ChatDatabase().getChatData(
      "*", "WHERE id like '%$userId%' ORDER BY lastMessageDate DESC",
      returnList: true);
  if(myChatData == false) myChatData = [];

  Hive.box("secureBox").put("myChats", myChatData);
}

refreshHiveEvents() async{
  var events = await EventDatabase().getData("*", "ORDER BY wann ASC", returnList: true);
  if (events == false) events = [];
  Hive.box("secureBox").put("events", events);

  var userId = FirebaseAuth.instance.currentUser?.uid;
  if(userId == null) return;

  var ownEvents = [];
  var myInterestedEvents = [];
  for(var event in events){
    if(event["erstelltVon"] == userId) ownEvents.add(event);
    if(event["interesse"].contains(userId) && event["erstelltVon"] != userId) myInterestedEvents.add(event);
  }

  Hive.box('secureBox').put("myEvents", ownEvents);
  Hive.box('secureBox').put("interestEvents", myInterestedEvents);
}

refreshHiveProfils() async{
  List<dynamic> dbProfils =
  await ProfilDatabase().getData("*", "WHERE name != 'googleView' ORDER BY ort ASC");
  if (dbProfils == false) dbProfils = [];

  dbProfils = sortProfils(dbProfils);


  Hive.box('secureBox').put("profils", dbProfils);

  var userId = FirebaseAuth.instance.currentUser?.uid;
  var ownProfil = {};

  if(userId == null || userId.isEmpty) return;

  for(var profil in dbProfils){
    if(profil["id"] == userId) ownProfil = profil;
  }
  Hive.box('secureBox').put("ownProfil", ownProfil);
}

refreshHiveCommunities() async {
  dynamic dbCommunities = await CommunityDatabase()
      .getData("*", "ORDER BY ort ASC", returnList: true);
  if (dbCommunities == false) dbCommunities = [];

  Hive.box('secureBox').put("communities", dbCommunities);
}

refreshHiveNewsPage() async {
  List<dynamic> dbNewsData = await NewsPageDatabase()
      .getData("*", "ORDER BY erstelltAm ASC", returnList: true);
  if (dbNewsData == false) dbNewsData = [];

  Hive.box('secureBox').put("newsFeed", dbNewsData);
}

refreshHiveStadtInfo() async{
  var stadtinfo = await StadtinfoDatabase()
      .getData("*", "ORDER BY ort ASC", returnList: true);
  Hive.box("secureBox").put("stadtinfo", stadtinfo);
}

refreshHiveStadtInfoUser() async {
  var stadtinfoUser =
  await StadtinfoUserDatabase().getData("*", "", returnList: true);
  Hive.box("secureBox").put("stadtinfoUser", stadtinfoUser);
}

refreshHiveFamilyProfils() async{
  var familyProfils =
  await FamiliesDatabase().getData("*", "", returnList: true);
  if (familyProfils == false) familyProfils = [];
  Hive.box("secureBox").put("familyProfils", familyProfils);
}

