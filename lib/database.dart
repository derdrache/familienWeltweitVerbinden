import 'package:cloud_firestore/cloud_firestore.dart';

CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");


dbAddNewProfil({name, ort, interessen, kinder}) {

  return profil.add({
    "name" : name,
    "ort" : ort,
    "interessen": interessen,
    "kinder": kinder
  })
      .then((value) => print("User Added"))
      .catchError((error) => print("Failed to add user: $error"));
}

dbGetAllProfils() async {
  QuerySnapshot querySnapshot = await profil.get();

  final allData = querySnapshot.docs.map((doc) => doc.data()).toList();

  return allData;

}

dbGetProfil(docID) async{
  var profilData;

  await profil.doc(docID)
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

dbGetProfilDocumentID(phoneID) async{
  var docID = "";

  await profil
      .where('phoneID', isEqualTo:phoneID)
      .get()
      .then((snapshot) => docID=snapshot.docs[0].reference.id);

  return docID;
}

dbChangeProfil(docID, data){
  CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");

  return profil.doc(docID).update({
    "name": data["name"],
    "ort": data["ort"],
    "interessen": data["interessen"],
    "kinder": data["kinder"]
      }).then((value) => print("User Updated"))
      .catchError((error) => print("Failed to update user: $error"));
}

dbDeleteProfil() async{

}