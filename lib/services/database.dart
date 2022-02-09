import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../global/global_functions.dart'as global_functions;

DatabaseReference realtimeDatabase = FirebaseDatabase.instanceFor(
    databaseURL: "https://praxis-cab-236720-default-rtdb.europe-west1.firebasedatabase.app",
    app: Firebase.app()).ref();
var chatGroupsDB = realtimeDatabase.child("chats");
var chatMessagesDB = realtimeDatabase.child("chatMessages");
var profilsDB = realtimeDatabase.child("profils");
var feedbackDB = realtimeDatabase.child("feedback");

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
  }

  addAdminMessage(message, user){
    feedbackDB.push().set({
      "feedback": message,
      "user": user,
      "date": DateTime.now().toString()
    });
  }

  getChat(chatID) async {
    var query = await chatGroupsDB.child(chatID).get();
    var data = query.value;

    return data;
  }

  getNewMessagesCounter(chatId, userId) async{
    var query = await chatGroupsDB.child(chatId).child("users").child(userId).child("newMessages").get();

    return query.value;
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
    FirebaseAuth.instance.currentUser?.updateDisplayName(profilData["name"]);
    profilsDB.child(id).set(profilData);
  }

  updateProfil(userID, data){
    profilsDB.child(userID).update(data);
  }

  updateProfilName(profilID,oldName, newName) {
    FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

    updateProfil(profilID, {"name": newName});

    chatGroupsDB.orderByChild("users/$profilID").equalTo(oldName).once().then((query){
      for (var chatGroup in query.snapshot.children) {
        var key = chatGroup.key;

        chatGroupsDB.child(key!).child("users").update({profilID: newName});
      }
    });
  }

  getProfil(id) async{
    var query = await profilsDB.child(id).get();
    var data = query.value;

    return data;
  }

  getOneData(id, information) async {
    var query = await profilsDB.child(id).child("email").get();

    return query.value;
  }

  getProfilFromName(name) async{
    var query = await profilsDB.orderByChild("name").limitToFirst(1).equalTo(name).once();

    if(query.snapshot.exists) return query.snapshot.value;
  }

  getProfilId(String search, String match) async{
    var query = await profilsDB.orderByChild(search).limitToFirst(1).equalTo(match).once();

    if(query.snapshot.exists) return query.snapshot.children.first.key;
  }

  getActiveChat(id) async {
    var query = await profilsDB.child(id).child("activeChat").get();

    return query.value;
  }

  getAllProfilsStream(){
    return profilsDB.onValue;
  }

  getNewMessagesStream(userId){
    return profilsDB.child(userId).child("newMessages").onValue;
  }

}