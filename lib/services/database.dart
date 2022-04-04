import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../auth/secrets.dart';
import '../global/global_functions.dart'as global_functions;


//var databaseUrl = "https://families-worldwide.com/";
var databaseUrl = "http://test.families-worldwide.com/";

class AllgemeinDatabase{

  getOneData(what) async{
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

  getAllProfils() async{
    var url = Uri.parse(databaseUrl + "database/profils/getAllProfils.php");
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var responseBody = json.decode(res.body);

    for(var body in responseBody){
      body["kinder"] = json.decode(body["kinder"]);
      body["sprachen"] = json.decode(body["sprachen"]);
      body["interessen"] = json.decode(body["interessen"]);
      body["friendlist"] = body["friendlist"] == ""? []: json.decode(body["friendlist"]);
      body["emailAnzeigen"] = body["emailAnzeigen"] == "0"? false : true;
      body["notificationstatus"] = body["notificationstatus"] == "0"? false : true;
    }

    return responseBody;
  }

  getProfil(look, inhalt) async{
    var url = databaseUrl + "database/profils/getProfil.php";
    var data = "?param1=$look&param2=$inhalt";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});

    var responseBody = json.decode(res.body);
    responseBody["kinder"] = json.decode(responseBody["kinder"]);
    responseBody["sprachen"] = json.decode(responseBody["sprachen"]);
    responseBody["interessen"] = json.decode(responseBody["interessen"]);
    if(responseBody["friendlist"] != "") responseBody["friendlist"] = json.decode(responseBody["friendlist"]);
    responseBody["emailAnzeigen"] = responseBody["emailAnzeigen"] == "0"? false : true;
    responseBody["notificationstatus"] = responseBody["notificationstatus"] == "0"? false : true;
    responseBody["chatNotificationOn"] = responseBody["chatNotificationOn"] == "0"? false : true;
    responseBody["eventNotificationOn"] = responseBody["eventNotificationOn"] == "0"? false : true;

    return responseBody;

  }

  getOneData(what, look, inhalt) async {
    var url = databaseUrl + "database/profils/getOneData.php";
    var data = "?param1=$what&param2=$look&param3=$inhalt";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    dynamic responseBody = res.body;

    try{
      responseBody = jsonDecode(responseBody);
      responseBody = jsonDecode(responseBody[responseBody.keys.toList()[0]]);
    }catch(error){

    }

    try{
      responseBody = responseBody[responseBody.keys.toList()[0]];
    }catch(error){

    }

    return responseBody;

  }

  getOneDataFromAll(what) async{
    var url = databaseUrl + "database/profils/getOneDataFromAll.php";
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

  getAllFriendlists() async {
    var url = databaseUrl + "database/profils/getAllFriendlists.php";
    var uri = Uri.parse(url);
    var res = await http.get(uri, headers: {"Accept": "application/json"});

    var responseBody = json.decode(res.body);

    return responseBody;
  }

  updateProfilName(userId, oldName, newName) async{
    FirebaseAuth.instance.currentUser.updateDisplayName(newName);

    updateProfil(userId, "name", newName);

    var chats = await ChatDatabase().getAllChatgroupsFromUser(userId);
    for(var chat in chats){
      var newUserData = jsonDecode(chat["users"]);
      newUserData[userId]["name"] = newName;

      ChatDatabase().updateChatGroup(chat["id"], "users", newUserData);
    }


    var allProfilFriendlists = await getAllFriendlists();

    for(var profil in allProfilFriendlists){
      if(profil["friendlist"] == "" || profil["friendlist"] == []){
        if(profil["friendlist"].isEmpty) continue;

        var friendlist = jsonDecode(profil["friendlist"]);

        if(profil["friendlist"].contains(oldName)){
          friendlist.add(newName);
          friendlist.remove(oldName);
        }

        updateProfil(profil["id"], "friendlist", friendlist);
      }
    }
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

    var allChatGroups = await ChatDatabase().getAllChatgroupsFromUser(userId);
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

  getChat(chatId) async {
    var url = databaseUrl + "database/chats/getChat.php";
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
    http.post(url, body: json.encode({
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
    var activeChat = await ProfilDatabase().getOneData("activeChat", "id", chatPartnerId);

    if(chatData["id"] != activeChat){
      var allNewMessages = await ProfilDatabase().getOneData("newMessages", "id", chatPartnerId);

      ProfilDatabase().updateProfil(chatPartnerId, "newMessages", allNewMessages +1);

      var oldChatNewMessages = await ChatDatabase().getNewMessages(chatData["id"], chatPartnerId);

      oldChatNewMessages = oldChatNewMessages["users"];
      var oldChatNewMessagesMap= Map<String, dynamic>.from(jsonDecode(oldChatNewMessages));
      oldChatNewMessagesMap[chatPartnerId]["newMessages"] = oldChatNewMessagesMap[chatPartnerId]["newMessages"] +1;

      ChatDatabase().updateChatGroup(chatData["id"], "users", oldChatNewMessagesMap);

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

  getNewMessages(chatId, userId) async {
    var url = databaseUrl + "database/chats/getNewMessageCounter.php";
    var data = "?param1=$chatId";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});

    var responseBody = json.decode(res.body);

    return responseBody;
  }

  getAllChatgroupsFromUser(userId)async  {
    var url = databaseUrl + "database/chats/getAllChatsForUser.php";
    var data = "?param1=$userId";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    var responseBody = json.decode(res.body);

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
}

class EventDatabase{

  addNewEvent(eventData) async {
    var url = Uri.parse(databaseUrl + "database/events/newEvent.php");
    await http.post(url, body: json.encode(eventData));
  }

  updateOne(id, change, data){
    var url = Uri.parse(databaseUrl + "database/events/changeEvent.php");

    if(data is List){
      data = json.encode(data);
    }

    http.post(url, body: json.encode({
      "id": id,
      "change": change,
      "data": data
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

  getEvent(eventId) async {
    var url = databaseUrl + "database/events/getEvent.php";
    var data = "?param1=$eventId";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    var responseBody = json.decode(res.body);

    if(responseBody == false) return false;

    responseBody["interesse"] = jsonDecode(responseBody["interesse"]);
    responseBody["zusage"] = jsonDecode(responseBody["zusage"]);
    responseBody["absage"] = jsonDecode(responseBody["absage"]);
    responseBody["freischalten"] = jsonDecode(responseBody["freischalten"]);
    responseBody["freigegeben"] = jsonDecode(responseBody["freigegeben"]);
    responseBody["sprache"] = jsonDecode(responseBody["sprache"]);


    return responseBody;

  }

  getEvents(whereCondition) async {
    var url = databaseUrl + "database/events/getEvents.php";
    var data = "?param1=$whereCondition";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    var responseBody = json.decode(res.body);

    for(var i = 0; i < responseBody.length; i++){
      responseBody[i]["interesse"] = jsonDecode(responseBody[i]["interesse"]);
      responseBody[i]["zusage"] = jsonDecode(responseBody[i]["zusage"]);
      responseBody[i]["absage"] = jsonDecode(responseBody[i]["absage"]);
      responseBody[i]["freischalten"] = jsonDecode(responseBody[i]["freischalten"]);
      responseBody[i]["freigegeben"] = jsonDecode(responseBody[i]["freigegeben"]);
      responseBody[i]["sprache"] = jsonDecode(responseBody[i]["sprache"]);
    }


    return responseBody;

  }

  getOneData(what, eventId) async {
    var url = databaseUrl + "database/events/getOneData.php";
    var data = "?param1=$what&param2=$eventId";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    dynamic responseBody = res.body;

    try{
      responseBody = jsonDecode(responseBody);
      responseBody = jsonDecode(responseBody[responseBody.keys.toList()[0]]);
    }catch(error){

    }


    return responseBody;
  }

  getEventsCheckList(userId, where) async {
    var url = databaseUrl + "database/events/getEventCheckList.php";
    var data = "?param1=$userId&param2=$where";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});

    var responseBody = json.decode(res.body);

    for(var i = 0; i < responseBody.length; i++){
      responseBody[i]["interesse"] = jsonDecode(responseBody[i]["interesse"]);
      responseBody[i]["zusage"] = jsonDecode(responseBody[i]["zusage"]);
      responseBody[i]["absage"] = jsonDecode(responseBody[i]["absage"]);
      responseBody[i]["freischalten"] = jsonDecode(responseBody[i]["freischalten"]);
      responseBody[i]["freigegeben"] = jsonDecode(responseBody[i]["freigegeben"]);
      responseBody[i]["sprache"] = jsonDecode(responseBody[i]["sprache"]);
    }


    return responseBody;

  }

  getAllEvents() async {
    var url = Uri.parse(databaseUrl + "database/events/getAllEvents.php");
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var responseBody = json.decode(res.body);

    for(var i = 0; i < responseBody.length; i++){
      responseBody[i]["interesse"] = jsonDecode(responseBody[i]["interesse"]);
      responseBody[i]["zusage"] = jsonDecode(responseBody[i]["zusage"]);
      responseBody[i]["absage"] = jsonDecode(responseBody[i]["absage"]);
      responseBody[i]["freischalten"] = jsonDecode(responseBody[i]["freischalten"]);
      responseBody[i]["freigegeben"] = jsonDecode(responseBody[i]["freigegeben"]);
      responseBody[i]["sprache"] = jsonDecode(responseBody[i]["sprache"]);
    }

    return responseBody;
  }

  getAllEventsWhere(whereCondition) async{
    var url = databaseUrl + "database/events/getEvents.php";
    var data = "?param1=$whereCondition";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    dynamic responseBody = res.body;

    for(var i = 0; i < responseBody.length; i++){
      responseBody[i]["interesse"] = jsonDecode(responseBody[i]["interesse"]);
      responseBody[i]["zusage"] = jsonDecode(responseBody[i]["zusage"]);
      responseBody[i]["absage"] = jsonDecode(responseBody[i]["absage"]);
      responseBody[i]["freischalten"] = jsonDecode(responseBody[i]["freischalten"]);
      responseBody[i]["freigegeben"] = jsonDecode(responseBody[i]["freigegeben"]);
      responseBody[i]["sprache"] = jsonDecode(responseBody[i]["sprache"]);
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
  var toActiveChat = await ProfilDatabase().getOneData("activeChat", "id", messageData["zu"]);

  if(toActiveChat == chatId) return;


  var chatPartnerName = await ProfilDatabase().getOneData("name", "id", messageData["von"]);
  var toToken = await ProfilDatabase().getOneData("token", "id", messageData["zu"]);

  var notificationInformation = {
    "toId": messageData["zu"],
    "token": toToken,
    "title": chatPartnerName,
    "inhalt": messageData["message"],
    "changePageId": chatId,
    "apiKey": firebaseWebKey,
    "typ" : "chat"
  };

  sendNotification(notificationInformation);


}

sendNotification(notificationInformation) async {
    var notificationsAllowed = await ProfilDatabase().
      getOneData("notificationstatus", "id", notificationInformation["toId"]);

    if(notificationsAllowed == 0) return;

    if(notificationInformation["token"] == "" || notificationInformation["token"] == null){

      var emailAdresse = await ProfilDatabase().getOneData("email", "id", notificationInformation["toId"]);

      var url = Uri.parse(databaseUrl + "services/sendEmail.php");
      http.post(url, body: json.encode({
        "to": emailAdresse,
        "title": notificationInformation["title"],
        "inhalt": notificationInformation["inhalt"],
      }));

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

