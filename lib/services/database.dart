import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

DatabaseReference realtimeDatabase = FirebaseDatabase.instanceFor(
    databaseURL: "https://praxis-cab-236720-default-rtdb.europe-west1.firebasedatabase.app",
    app: Firebase.app()).ref();


class ChatDatabaseKontroller{
  var chatGroups = realtimeDatabase.child("chats");
  var chatMessages = realtimeDatabase.child("chatMessages");

  addNewChatGroup(users) {
    var userIDList = users.keys.toList();
    userIDList.sort();
    var id = userIDList.join("_");

    var chatgroupData = {
      "id": id,
      "users" : users,
      "lastMessage": "",
      "lastMessageDate": "",
    };

    chatGroups.child(id).set(chatgroupData);

    return chatgroupData;
  }

  updateChatGroup(chatID, chatgroupData){
    chatGroups.child(chatID).update(chatgroupData);
  }

  addNewMessage(chatgroupData, messageData,{ newChat = false}){
    var users = chatgroupData["users"].keys.toList();
    users.sort();
    var id = users.join("_");
    var chatGroup = realtimeDatabase.child("chatMessages").child(id);

    chatGroup.push().set(messageData);
  }

  getChat(chatID) async {
    var query = await chatGroups.child(chatID).get();
    var data = query.value;

    return data;
  }

  getAllChatgroupsFromUserStream(userID, userName) {
    return chatGroups.orderByChild("users/$userID").equalTo(userName).onValue;
  }

  getAllMessagesStream(chatID) {
    return chatMessages.child(chatID).orderByChild("date").onValue;
  }

}

class ProfilDatabaseKontroller{
  var profils = realtimeDatabase.child("profils");

  addNewProfil(id, profilData){
    profils.child(id).set(profilData);
  }

  updateProfil(userID, data){
    profils.child(userID).update(data);
  }

  updateProfilName(profilID,oldName, newName) {
    FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

    updateProfil(profilID, {"name": newName});

    realtimeDatabase.child("chats").orderByChild("users/$profilID").equalTo(oldName).once().then((value){
      value.snapshot.children.forEach((element) {
        var key = element.key;

        realtimeDatabase.child("chats").child(key!).child("users").update({profilID: newName});

      });

    });

  }

  deleteProfil(){

  }

  getProfil(id) async{
    var query = await profils.child(id).get();
    var data = query.value;

    return data;
  }

  getProfilEmail(id) async{
    var query = await profils.child(id).child("email").get();
    var data = query.value;

    return data;
  }

  getProfilFromName(name) async{
    var event = await profils.orderByChild("name").limitToFirst(1).equalTo(name).once();
    if(event.snapshot.exists){
      return event.snapshot.value;
    }

  }

  getProfilIDFromName(name) async {
    var event = await profils.orderByChild("name").limitToFirst(1).equalTo(name).once();

    if(event.snapshot.exists){
      return event.snapshot.children.first.key;
    }
  }

  getProfilIDFromEmail(email) async{
    var event = await profils.orderByChild("email").limitToFirst(1).equalTo(email).once();

    if(event.snapshot.exists){
      return event.snapshot.children.first.key;
    }

  }

  getProfilName(id) async {
    var query = await profils.child(id).child("name").get();

    return query.value;

  }

  getAllProfils() async {
    var resultProfils = [];

    var test = await profils.get();
    var data = test.children;

    data.forEach((element) {
      resultProfils.add(element.value);
    });

    return resultProfils;

  }

  getAllProfilsStream(){
    return profils.onValue;
  }


}