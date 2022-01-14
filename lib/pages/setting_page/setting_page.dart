import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../database.dart';
import '../../global_functions.dart' as globalFunctions;


class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double globalPadding = 30;
  double fontSize = 18;
  var borderColor = Colors.grey[200]!;
  var profilName = "";
  var profilOrt = "";
  var profilKinder = [];
  var profilInteressen = [];
  var profilBio = "";

  @override
  void initState() {
    // TODO: implement initState

    getAndSetDataFromDB();
    super.initState();
  }

  menuBar(){
    return Container(
      child: Row(
        children: [
          Expanded(child: SizedBox()),
          TextButton(
            style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    )
                )
            ),
            child: Icon(Icons.more_vert),
            onPressed: () => print("open Settings"),
            // Name ändern, abmelden
          )
        ],
      ),
    );
  }

  nameContainer(){
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 10, color: borderColor))
      ),
      child: Text(
        profilName,
        style: TextStyle(fontSize: 30),
      )
    );
  }

  profilContainer(){
    double containerPadding = 5;

    themeContainer(haupttext, beschreibung){
      return Container(
        padding: EdgeInsets.only(top: containerPadding, bottom: containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(haupttext,
              style: TextStyle(fontSize: fontSize),
            ),
            SizedBox(height: 3),
            Text(beschreibung,
              style: TextStyle(color: Colors.grey, fontSize: fontSize-2.0),
            ),
          ],
        )
      );
    }

    return Container(
        width: double.maxFinite,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 10, color: borderColor))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Profil",
                style: TextStyle(color: Colors.blue, fontSize: fontSize)
            ),
            SizedBox(height: 5),
            themeContainer(profilOrt, "Aktueller Ort"),
            themeContainer(profilKinder.join(" , "), "Alter der Kinder"),
            themeContainer(profilInteressen.join(" , "), "Interessen"),
            themeContainer(profilBio, "Über mich")
          ],
        )
    );
  }

  settingContainer(){

    themeContainer(title){
      return Text(title);
    }

    return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Einstellungen",
                style: TextStyle(color: Colors.blue, fontSize: fontSize)),
            themeContainer("Privatsphäre und Sicherheit") //Email anzeigen, Passwort ändern
          ],
        )
    );
  }

  getProfilFromDatabase() async {
    var userEmail = FirebaseAuth.instance.currentUser!.email;
    var docID = await dbGetProfilDocumentID(userEmail);
    var profil = await dbGetProfil(docID);

    return profil;
  }

  void getAndSetDataFromDB() async {
    try{
      var userProfil = await getProfilFromDatabase();
      List childrenDataYears = [];

      userProfil["kinder"].forEach((kind){
        var timestampToYears = globalFunctions.timeStampToAllDict(kind)["years"];
        childrenDataYears.add(timestampToYears);
      });

      setState(() {
        profilName = userProfil["name"];
        profilOrt = userProfil["ort"];
        profilInteressen = userProfil["interessen"];
        profilKinder = childrenDataYears;
      });

    } catch (error){
      print("Problem mit dem User finden");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              menuBar(),
              nameContainer(),
              profilContainer(),
              settingContainer()
          ]
        )
    );
  }
}
