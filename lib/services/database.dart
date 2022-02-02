import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");
CollectionReference chats = FirebaseFirestore.instance.collection("chats");
DatabaseReference realtimeDatabase = FirebaseDatabase.instanceFor(
    databaseURL: "https://praxis-cab-236720-default-rtdb.europe-west1.firebasedatabase.app",
    app: Firebase.app()).ref();



dbChangeUserName(profilDocid, oldName, newName) async {
  FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

  profil.doc(profilDocid).update({"name": newName});

  profil.where("friendlist", arrayContains: oldName)
        .get().then((values) {
          if(values.docs.isNotEmpty){
            for(var value in values.docs){
              List friendList = value.get("friendlist");
              friendList[friendList.indexOf(oldName)] = newName;

              profil.doc(value.id).update({"friendlist": friendList});
            }
          }
  });

  chats.where("users", arrayContains: oldName).get().then((values) {
    if(values.docs.isNotEmpty){
      for(var value in values.docs){
        List users = value.get("users");
        users[users.indexOf(oldName)] = newName;
        chats.doc(value.id).update({"users": users});
      }
    }
  });



}


class ChatDatabaseKontroller{
  var chatGroups = realtimeDatabase.child("chats");
  var chatMessages = realtimeDatabase.child("chatMessages");

  addNewChatGroup(users) {
    var newChatGroup = chatGroups.push();
    var chatKey = newChatGroup.key;

    var chatgroupData = {
      "id" : chatKey,
      "users" : users,
      "lastMessage": "",
      "lastMessageDate": "",
    };

    newChatGroup.set(chatgroupData);

    return chatgroupData;
  }

  updateChatGroup(chatID, chatgroupData){
    chatGroups.child(chatID).update(chatgroupData);
  }

  addNewMessage(chatgroupData, messageData,{ newChat = false}){
    var chatGroup = realtimeDatabase.child("chatMessages").child(chatgroupData["id"]);

    chatGroup.push().set(messageData);
  }

  getChat(user1, user2) async {
    var query = await chatGroups.orderByChild("users").limitToFirst(1)
        .equalTo({
      user1: true,
      user2: true
    }).once();
    var data = query.snapshot.children.first.value;

    return data;
  }

  getAllChatgroupsFromUserStream(name) {

    return chatGroups.orderByChild("users/$name").equalTo(true).onValue;
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

  updateProfilName(profilID, oldName, newName){
    FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

    updateProfil(profilID, {"name": newName});

    profils.orderByChild("friendlist/$oldName").equalTo(true).once().then((value){
      value.snapshot.children.forEach((element) {
        var friendlist = element.child("friendlist").value as Map;
        friendlist[newName] = true;
        friendlist.remove(oldName);

        updateProfil(element.key, friendlist);

      });
    });

    realtimeDatabase.child("chats").orderByChild("users/$oldName").equalTo(true)
        .once().then((value) {
          value.snapshot.children.forEach((element) {
            var users = element.child("users").value as Map;
            users[newName] = true;
            users.remove(oldName);

            ChatDatabaseKontroller().updateChatGroup(
                element.key,
                {"users": users}
            );
          });
    });

    //in jeder Nachricht updaten

  }

  deleteProfil(){

  }

  getProfil(id) async{
    var query = await profils.child(id).get();
    var data = query.value;

    return data;
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


}