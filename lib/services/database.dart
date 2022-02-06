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

class ChatDatabaseKontroller{

  addNewChatGroup(users) {
    users = users.keys.toList();
    var chatID = global_functions.getChatID(users);

    var chatgroupData = {
      "id": chatID,
      "users" : users,
      "lastMessage": "",
      "lastMessageDate": "",
    };

    chatGroupsDB.child(chatID).set(chatgroupData);

    return chatgroupData;
  }

  updateChatGroup(chatID, chatgroupData){
    chatGroupsDB.child(chatID).update(chatgroupData);
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

  getAllChatgroupsFromUserStream(userID, userName) {
    return chatGroupsDB.orderByChild("users/$userID").equalTo(userName).onValue;
  }

  getAllMessagesStream(chatID) {
    return chatMessagesDB.child(chatID).orderByChild("date").onValue;
  }

}

class ProfilDatabaseKontroller{

  addNewProfil(id, profilData){
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

  getProfilEmail(id) async{
    var query = await profilsDB.child(id).child("email").get();
    var data = query.value;

    return data;
  }

  getProfilFromName(name) async{
    var query = await profilsDB.orderByChild("name").limitToFirst(1).equalTo(name).once();

    if(query.snapshot.exists) return query.snapshot.value;
  }

  getProfilIDFromName(name) async {
    var query = await profilsDB.orderByChild("name").limitToFirst(1).equalTo(name).once();

    if(query.snapshot.exists) return query.snapshot.children.first.key;
  }

  getProfilIDFromEmail(email) async{
    var query = await profilsDB.orderByChild("email").limitToFirst(1).equalTo(email).once();

    if(query.snapshot.exists) return query.snapshot.children.first.key;
  }

  getProfilName(id) async {
    var query = await profilsDB.child(id).child("name").get();

    return query.value;
  }

  getAllProfils() async {
    var profils = [];

    var query = await profilsDB.get();
    var snapshot = query.children;

    for (var profil in snapshot) {
      profils.add(profil.value);
    }

    return profils;

  }

  getAllProfilsStream(){
    return profilsDB.onValue;
  }

}