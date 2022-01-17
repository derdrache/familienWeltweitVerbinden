import 'package:cloud_firestore/cloud_firestore.dart';

CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");


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
  CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");

  return profil.doc(docID).update(data).then((value) => print("User Updated"))
      .catchError((error) => print("Failed to update user: $error"));
}

dbDeleteProfil(docID) {
  return profil
      .doc(docID)
      .delete();
}