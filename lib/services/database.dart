import 'package:cloud_firestore/cloud_firestore.dart';

CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");
CollectionReference chats = FirebaseFirestore.instance.collection("chats");


dbAddNewProfil(id, data) {

  return profil.doc(id).set(data)
      .then((value) => print("User Added"))
      .catchError((error) => print("Failed to add user: $error"));
}

dbGetAllProfils() async {
  QuerySnapshot querySnapshot = await profil.get();

  final allData = querySnapshot.docs.map((doc) => doc.data()).toList();

  return allData;

}

dbGetProfil(email) async{
  var profilData;

  await profil.doc(email)
      .get()
      .then((DocumentSnapshot documentSnapshot) {
    if (documentSnapshot.exists) {
      profilData = documentSnapshot.data();
    } else {
      print('Document does not exist on the database');
    }
  });

  return profilData;
}

dbChangeProfil(docID, data){
  return profil.doc(docID).update(data).then((value) => print("User Updated"))
      .catchError((error) => print("Failed to update user: $error"));
}

dbDeleteProfil(docID) {
  return profil
      .doc(docID)
      .delete();
}


dbGetAllUsersChats(user) async{
  var userChatGroups = [];

  await chats
      .get()
      .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          for(var chatgroup in querySnapshot.docs){
            userChatGroups.add(chatgroup.data());
          }
        }
      });

  return userChatGroups;
}

dbGetMessagesFromChatgroup(chatgroup) async{
  QuerySnapshot querySnapshots =  await chats.doc(chatgroup["docid"]).collection("messages").get();
  List allData = querySnapshots.docs.map((doc) => doc.data()).toList();

  return allData;
}

dbAddMessage(messageData) async {
  await chats.doc(messageData["docid"]).collection("messages").add({
    "message" : messageData["message"],
    "date" : messageData["date"],
    "from": messageData["from"]
  });


}