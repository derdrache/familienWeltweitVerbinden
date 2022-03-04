import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../global/global_functions.dart'as global_functions;

DatabaseReference realtimeDatabase = FirebaseDatabase.instanceFor(
    databaseURL: "https://praxis-cab-236720-default-rtdb.europe-west1.firebasedatabase.app",
    app: Firebase.app()).ref();
var chatGroupsDB = realtimeDatabase.child("chats");
var chatMessagesDB = realtimeDatabase.child("chatMessages");
var profilsDB = realtimeDatabase.child("profils");
var feedbackDB = realtimeDatabase.child("feedback");
var testDB = realtimeDatabase.child("test");

var databaseUrl = "https://families-worldwide.com/";
/*
class ChatDatabase{

  addNewChatGroup(users, messageData) {
    var userKeysList = users.keys.toList();
    var usersList = users.values.toList();
    var chatID = global_functions.getChatID(userKeysList);


    var chatgroupData = {
      "id": chatID,
      "users" : {
        userKeysList[0] : {"name" : usersList[0], "newMessages": 0},
        userKeysList[1] : {"name" : usersList[1], "newMessages": 0},
      },
      "lastMessage": messageData["message"],
      "lastMessageDate": messageData["date"],
    };

    chatGroupsDB.child(chatID).set(chatgroupData);

    return chatgroupData;
  }

  updateChatGroup(chatID, chatgroupData){
    chatGroupsDB.child(chatID).update(chatgroupData);
  }

  updateNewMessageCounter(chatId, userId, counter){
    chatGroupsDB.child(chatId).child("users").child(userId).update({
        "newMessages": counter});
  }

  addNewMessage(chatgroupData, messageData){
    var users = chatgroupData["users"].keys.toList();
    var chatID = global_functions.getChatID(users);
    var chatGroup = chatMessagesDB.child(chatID);

    chatGroup.push().set(messageData);
    _changeNewMessageCounter(messageData["to"], chatgroupData);
  }

  _changeNewMessageCounter(chatPartnerId, chatData) async{
    var allNewMessages = await ProfilDatabase().getOneData(chatPartnerId,"newMessages") ?? 0;

    ProfilDatabase().updateProfil(
        chatPartnerId,
        {"newMessages": allNewMessages +1}
    );


    var oldUserNewMessages = await ChatDatabase().getNewMessages(chatData["id"], chatPartnerId);
    var activeChat = await ProfilDatabase().getOneData(chatPartnerId, "activeChat");

    if(chatData["id"] != activeChat){
      ChatDatabase().updateNewMessageCounter(
          chatData["id"],
          chatPartnerId,
          oldUserNewMessages + 1
      );
    }

  }

  addAdminMessage(message, user){
    feedbackDB.push().set({
      "feedback": message,
      "user": user,
      "date": DateTime.now().toString()
    });
  }

  getNewMessages(chatId, userId) async {
    var query = await chatGroupsDB.child(chatId).child("users").child(userId).child("newMessages").get();

    return query.value;

  }

  getChat(chatID) async {
    var query = await chatGroupsDB.child(chatID).get();
    var data = query.value;

    return data;
  }

  getAllChatgroupsFromUserStream(userID, userName) {
    return chatGroupsDB.orderByChild("users/$userID/name").equalTo(userName).onValue;
  }

  getAllMessagesStream(chatID) {
    return chatMessagesDB.child(chatID).orderByChild("date").onValue;
  }

}

class ProfilDatabase{

  addNewProfil(id, profilData){
    profilsDB.child(id).set(profilData);
    FirebaseAuth.instance.currentUser?.updateDisplayName(profilData["name"]);
  }

  updateProfil(userID, data){
    profilsDB.child(userID).update(data);
  }

  updateProfilName(profilID,oldName, newName) async {
    FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
    updateProfil(profilID, {"name": newName});

    chatGroupsDB.orderByChild("users/$profilID/name").equalTo(oldName).get().then((query){
      for (var chatGroup in query.children) {
        var key = chatGroup.key;

        chatGroupsDB.child(key).child("users").child(profilID).update({"name": newName});
      }
    });

    var query = await profilsDB.orderByChild("friendlist/$oldName").equalTo(true).get();
    query.children.forEach((element) {
      profilsDB.child(element.key).child("friendlist").child(oldName).remove();
      profilsDB.child(element.key).child("friendlist").update({newName: true});
    });


  }

  getProfil(id) async{
    var query = await profilsDB.child(id).get();
    var data = query.value;

    return data;
  }

  getOneData(id, information) async {
    var query = await profilsDB.child(id).child(information).get();

    return query.value;
  }

  getProfilFromName(name) async{
    var query = await profilsDB.orderByChild("name").limitToFirst(1).equalTo(name).get();

    if(query.exists) return query.value;
  }

  getProfilId(String search, String match) async{
    var query = await profilsDB.orderByChild(search).limitToFirst(1).equalTo(match).get();

    if(query.exists) return query.children.first.key;
  }

  getProfilStream(id){
    return profilsDB.child(id).onValue;
  }

  getAllProfilsStream(){
    return profilsDB.onValue;
  }

  getNewMessagesStream(userId){
    return profilsDB.child(userId).child("newMessages").onValue;
  }

  workAroundGetAllErrors() async {
    var query = await profilsDB.orderByChild("error").equalTo(true).get();

    return query.value;
  }

  removeData(userId, data){
    profilsDB.child(userId).child(data).remove();
  }

}

 */

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

  //kein Stream mehr
  getAllProfils() async{
    var url = Uri.parse(databaseUrl + "database/profils/getAllProfils.php");
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var responseBody = json.decode(res.body);

    return responseBody;
  }

  getProfil(look, inhalt) async{
    var url = databaseUrl + "database/profils/getProfil.php";
    var data = "?param1=$look&param2=$inhalt";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});

    var responseBody = json.decode(res.body);
    return responseBody;

  }

  getOneData(what, look, inhalt) async {
    var url = databaseUrl + "database/profils/getOneData.php";
    var data = "?param1=$what&param2=$look&param3=$inhalt";
    var uri = Uri.parse(url+data);
    var res = await http.get(uri, headers: {"Accept": "application/json"});
    var responseBody = res.body;

    if(responseBody is List){
      responseBody = json.encode(responseBody);
    }

    return responseBody;

  }

  getAllFriendlists() async {
    var url = "databaseUrl + database/profils/getAllFriendlists.php";
    var uri = Uri.parse(url);
    var res = await http.get(uri, headers: {"Accept": "application/json"});

    var responseBody = json.decode(res.body);

    return responseBody;
  }
  
  updateProfilName(userId, oldName, newName) async {
    FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
    updateProfil(userId, "name", newName);

    var chats = await ChatDatabase().getAllChatgroupsFromUser(userId);
    for(var chat in chats){
      var newUserData = jsonDecode(chat["users"]);
      newUserData[userId]["name"] = newName;

      ChatDatabase().updateChatGroup(chat["id"], "users", newUserData);
    }


    var allProfilFriendlists = await getAllFriendlists();
    for(var profil in allProfilFriendlists){
      var friendlist = jsonDecode(profil["friendlist"]);

      if(profil["friendlist"].contains(oldName)){
        friendlist.add(newName);
        friendlist.remove(oldName);
      }

      updateProfil(profil["id"], "friendlist", friendlist);
    }
  }

}


class ChatDatabase{

  addNewChatGroup(users, messageData)async {
    var userKeysList = users.keys.toList();
    var usersList = users.values.toList();
    var chatID = global_functions.getChatID(userKeysList);
    var date = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    var url = Uri.parse(databaseUrl + "database/chats/newChatGroup.php");
    await http.post(url, body: json.encode({
      "id": chatID,
      "date": date,
      "users": json.encode({
        userKeysList[0] : {"name": usersList[0], "newMessages": 0},
        userKeysList[1] : {"name": usersList[1], "newMessages": 0},
      }),
      "lastMessage": messageData["message"],
    }));

    var url2 = Uri.parse(databaseUrl + "database/chats/newMessageTable.php");
    await http.post(url2, body: json.encode({
      "id": chatID,
      "date": date,
      "message": messageData["message"],
      "von": messageData["to"],
      "zu": messageData["from"]
    }));
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

    var test = await http.post(url, body: json.encode({
      "id": chatId,
      "change": change,
      "data": data
    }));

  }

  addNewMessage(chatgroupData, messageData)async {
    var users = jsonDecode(chatgroupData["users"]).keys.toList();
    var chatID = global_functions.getChatID(users);
    var date = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    var url = Uri.parse(databaseUrl + "database/chats/newMessage.php");
    var test = await http.post(url, body: json.encode({
      "id": chatID,
      "date": date,
      "message": messageData["message"],
      "von": messageData["to"],
      "zu": messageData["from"]
    }));

    _changeNewMessageCounter(messageData["to"], chatgroupData);
  }

  _changeNewMessageCounter(chatPartnerId, chatData) async{
    var activeChat = await ProfilDatabase().getOneData("activeChat", "id", chatPartnerId);

    if(chatData["id"] != activeChat){
      var allNewMessages = await ProfilDatabase().getOneData("newMessages", "id", chatPartnerId);

      ProfilDatabase().updateProfil(chatPartnerId, "newMessages", int.parse(allNewMessages)+1);


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
