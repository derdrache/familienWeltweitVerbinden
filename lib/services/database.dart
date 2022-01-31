import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");
CollectionReference chats = FirebaseFirestore.instance.collection("chats");
DatabaseReference realtimeDatabase = FirebaseDatabase.instanceFor(
    databaseURL: "https://praxis-cab-236720-default-rtdb.europe-west1.firebasedatabase.app",
    app: Firebase.app()).ref();


dbAddNewProfil(data) {
  return profil.add(data).then((value) {
    profil.doc(value.id).update({"docid": value.id});
  });
}

dbGetAllProfils() async {
  QuerySnapshot querySnapshot = await profil.get();

  final allData = querySnapshot.docs.map((doc) => doc.data()).toList();

  return allData;

}

dbGetProfil(name) async{
  var profilData;

  await profil.where("name", isEqualTo: name)
      .limit(1)
      .get()
      .then((value) {
    if (value.docs.isNotEmpty) {
      profilData = value.docs[0].data();
    } else {
      profilData = null;
    }
  });

  return profilData;
}

dbGetProfilFromEmail(email) async{
  var profilData;

  await profil.where("email", isEqualTo: email).limit(1)
      .get()
      .then((value) {
        if(value.docs.isNotEmpty){
          profilData = value.docs[0].data();
        }

      });

  return profilData;
}

dbChangeProfil(docID, data){
  print(data);
  return profil.doc(docID).update(data).then((value) => print("User Updated"))
      .catchError((error) => print("Failed to update user: $error"));
}

dbDeleteProfil(docID) {
  return profil
      .doc(docID)
      .delete();
}





dbGetOneUserChat(user1, user2) async{
  var groupChatData;

  await chats.where("users", arrayContains: user1).get().then((values){
    if(values.docs.isNotEmpty){
      for(var value in values.docs){

        var hasUser2 = value.get("users").contains(user2);
        if(hasUser2){
          groupChatData =  value.data();
        }
      }
    }
  });

  return groupChatData;
}

dbGetMessagesFromChatgroup(chatgroup) async {
  QuerySnapshot querySnapshots = await chats.doc(chatgroup["docid"]).
                                collection("messages").orderBy("date", descending: true).get();
  List allData = querySnapshots.docs.map((doc) => doc.data()).toList();

  return allData;
}

dbAddMessage(chatgroupData, messageData,{ newChat = false}) async {

  if(newChat){
    chatgroupData = {
      "users" : chatgroupData["users"],
      "lastMessage": messageData["message"],
      "lastMessageDate": messageData["date"],
    };

    await chats.add(chatgroupData).then((value) {
      chatgroupData["docid"] = value.id;
      chats.doc(value.id).update({"docid": value.id});
    });
  } else{
    await chats.doc(chatgroupData["docid"]).update({
      "lastMessage" : messageData["message"],
      "lastMessageDate": messageData["date"]
    });
  }

  await chats.doc(chatgroupData["docid"]).collection("messages").add({
    "message" : messageData["message"],
    "date" : messageData["date"],
    "from": chatgroupData["users"].indexOf(messageData["from"])
  });

  return chatgroupData;
}

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


class DBChat{

  addNewChatGroup(chatgroupData,messageData){
    var chatGroups = realtimeDatabase.child("chats");
    var chatKey = chatGroups.push().key;

    chatgroupData = {
      "users" : chatgroupData["users"],
      "lastMessage": messageData["message"],
      "lastMessageDate": messageData["date"],
    };

    chatGroups.push().set(chatgroupData);

    return chatKey;
  }

  updateChatGroup(){

  }

  addNewMessage(chatID, messageData){
    var chatGroup = realtimeDatabase.child("chatMessages").child(chatID);

    chatGroup.push().set(messageData);
  }

  addChatIDToProfils(){

  }


}

class DBProfil{

}