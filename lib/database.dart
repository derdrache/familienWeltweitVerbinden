import 'package:cloud_firestore/cloud_firestore.dart';

CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");


dbAddNewProfil(data) {

  return profil.add({
    "email": data["email"],
    "name": data["name"],
    "ort": data["ort"],
    "interessen": data["interessen"],
    "kinder": data["kinder"],
    "land": data["land"],
    "longt": data["longt"],
    "latt":  data["latt"]
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

dbGetProfilDocumentID(email) async{
  var docID;

  try{
    await profil
        .where('email', isEqualTo:email)
        .get()
        .then((snapshot) => docID=snapshot.docs[0].reference.id);
  }catch(error){
    docID = null;
  }

  return docID;
}

dbChangeProfil(docID, data){
  CollectionReference profil = FirebaseFirestore.instance.collection("Nutzer");

  return profil.doc(docID).update({
    "name": data["name"],
    "ort": data["ort"],
    "interessen": data["interessen"],
    "kinder": data["kinder"],
    "land": data["land"],
    "longt": data["longt"],
    "latt":  data["latt"]
      }).then((value) => print("User Updated"))
      .catchError((error) => print("Failed to update user: $error"));
}

dbDeleteProfil(docID) {
  return profil
      .doc(docID)
      .delete();
}