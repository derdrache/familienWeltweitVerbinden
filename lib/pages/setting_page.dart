import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/database.dart';
import '../global/global_functions.dart' as globalFunctions;
import '../windows/change_profil_window.dart';
import '../global/custom_widgets.dart';
import '../global/variablen.dart' as globalVariablen;
import '../services/locationsService.dart';
import '../pages/login_register_page/login_page.dart';


class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double globalPadding = 30;
  double fontSize = 16;
  var borderColor = Colors.grey[200]!;
  var nameTextKontroller = TextEditingController();
  var kinderAgeBox = ChildrenBirthdatePickerBox();
  var interessenInputBox = CustomMultiTextForm(
      auswahlList: globalVariablen.interessenListe);
  var bioTextKontroller = TextEditingController();
  var emailTextKontroller = TextEditingController();
  var passwortTextKontroller = TextEditingController();
  var reiseArtInput = CustomDropDownButton(items: globalVariablen.reisearten);
  var sprachenInputBox = CustomMultiTextForm(
      auswahlList: globalVariablen.sprachenListe);
  var ortKontroller = TextEditingController();
  String beschreibungStadt = "Aktuelle Stadt";
  String beschreibungReise  = "Art der Reise";
  String beschreibungKinder = "Alter der Kinder";
  String beschreibungInteressen = "Interessen";
  String beschreibungSprachen = "Sprachen";
  String beschreibungBio = "Über mich";
  String beschreibungName = "Name ändern";
  String beschreibungEmail = "Email ändern";
  String beschreibungPasswort = "Passwort ändern";

  @override
  void initState() {

    getAndSetDataFromDB();


    super.initState();
  }


  nameContainer(){
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 10, color: borderColor))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nameTextKontroller.text,
            style: TextStyle(fontSize: 30),
          ),
          Text(emailTextKontroller.text)
        ]
      )
    );
  }

  settingContainer(){

    themeContainer(title, icon){
      return Container(
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 20),
            Text(title)
          ],
        )
      );
    }

    return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Einstellungen",
                style: TextStyle(color: Colors.blue, fontSize: fontSize)),
            SizedBox(height: 20),
            themeContainer("Privatsphäre und Sicherheit", Icons.lock),//Email anzeigen, Passwort ändern
            SizedBox(height: 20),

          ],
        )
    );
  }

  getProfilFromDatabase() async {
    emailTextKontroller.text = FirebaseAuth.instance.currentUser!.email!;
    var profil = await dbGetProfil(emailTextKontroller.text);

    return profil;
  }

  void getAndSetDataFromDB() async {
    var userProfil;
    List childrenAgeTimestamp = [];
    try{
      userProfil = await getProfilFromDatabase();
      List childrenDataYears = [];

      userProfil["kinder"].forEach((kind){
        var changeTimeStamp = globalFunctions.timeStampToAllDict(kind);
        childrenDataYears.add(changeTimeStamp["years"]);
        childrenAgeTimestamp.add(changeTimeStamp["date"]);
      });

      setState(() {
        nameTextKontroller.text = userProfil["name"];
        emailTextKontroller.text = userProfil["email"];
        ortKontroller.text = userProfil["ort"];
        interessenInputBox.selected = userProfil["interessen"];
        kinderAgeBox.setSelected(childrenAgeTimestamp);
        bioTextKontroller.text = userProfil["aboutme"];
        reiseArtInput.selected = userProfil["reiseart"];
        sprachenInputBox.selected = userProfil["sprachen"];
      });
    } catch (error){
      print("Problem mit dem User finden");
    }

  }

  pushLocationDataToDB() async {
    var locationData = await LocationService().getLocationMapDataGeocode(ortKontroller.text);

    var locationDict = {
      "ort": locationData["city"],
      "longt": double.parse(locationData["longt"]),
      "latt": double.parse(locationData["latt"]),
      "land": locationData["countryname"]
    };
    dbChangeProfil(emailTextKontroller.text, locationDict);
  }

  saveFunction(beschreibung) async{
    if(beschreibung == beschreibungStadt){
      pushLocationDataToDB();
    }else if(beschreibung == beschreibungReise){
      dbChangeProfil(emailTextKontroller.text, {"reiseart": reiseArtInput.getSelected()});
    }else if(beschreibung == beschreibungKinder){
      dbChangeProfil(emailTextKontroller.text, {"kinder": kinderAgeBox.getDates()});
    }else if(beschreibung == beschreibungInteressen){
      dbChangeProfil(emailTextKontroller.text, {"interessen": interessenInputBox.getSelected()});
    }else if(beschreibung == beschreibungSprachen){
      dbChangeProfil(emailTextKontroller.text, {"sprachen": sprachenInputBox.getSelected()});
    }else if(beschreibung == beschreibungBio){
      dbChangeProfil(emailTextKontroller.text, {"aboutme": bioTextKontroller.text});
    }else if(beschreibung == beschreibungName){
      FirebaseAuth.instance.currentUser?.updateDisplayName(nameTextKontroller.text);
      dbChangeProfil(emailTextKontroller.text, {"name": nameTextKontroller.text});
    } else if (beschreibung == beschreibungPasswort){
      FirebaseAuth.instance.currentUser?.updatePassword(passwortTextKontroller.text);
    }

    setState(() {});

    Navigator.of(context, rootNavigator: true).pop();

  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double containerPadding = 5;


    themeContainer(haupttext, beschreibung, changeWidget){
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => profilChangeWindow(context, beschreibung, changeWidget, () => saveFunction(beschreibung)),
        child: Container(
            padding: EdgeInsets.only(top: containerPadding, bottom: containerPadding),
            width: width /2 -20,
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
        ),
      );
    }

    profilContainer(){
      return Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(width: 10, color: borderColor))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text("Profil",
                    style: TextStyle(color: Colors.blue, fontSize: fontSize)
                ),
                Expanded(child: SizedBox()),
                Text("Antippen, um Einträge zu ändern",style: TextStyle(color: Colors.grey, fontSize: 14)),
                Expanded(child: SizedBox()),
              ]),
              SizedBox(height: 5),
              Wrap(
                children: [
                  themeContainer(ortKontroller.text, beschreibungStadt , customTextfield("", ortKontroller)),
                  themeContainer(reiseArtInput.getSelected(), beschreibungReise, reiseArtInput),
                  themeContainer(kinderAgeBox.getDates(years: true)  == null? "":
                  kinderAgeBox.getDates(years: true).join(" , "),
                      beschreibungKinder, kinderAgeBox),
                  themeContainer(
                      interessenInputBox.getSelected() == null? "" :
                      interessenInputBox.getSelected().join(" , "),
                      beschreibungInteressen,interessenInputBox),
                  themeContainer(
                      sprachenInputBox.getSelected() == null? "":
                      sprachenInputBox.getSelected().join(" , "),
                      beschreibungSprachen, sprachenInputBox)
                ],
              ),
              themeContainer(bioTextKontroller.text, beschreibungBio,
                  customTextfield("über mich", bioTextKontroller))
            ],
          )
      );
    }

    menuBar(){

      openSettingWindow()async {
        var textColor = Colors.black;

        return showMenu(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            context: context,
            position: RelativeRect.fromLTRB(100, 0, 0, 100),
            items: [
              PopupMenuItem(
                  child: TextButton(
                    onPressed: () => profilChangeWindow(context, beschreibungName,
                        customTextfield(beschreibungName,nameTextKontroller),
                        () => saveFunction(beschreibungName)),
                    child: Text(beschreibungName, style: TextStyle(color: textColor)))
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: () => profilChangeWindow(context, beschreibungPasswort,
                          customTextfield(beschreibungPasswort, passwortTextKontroller),
                              () => saveFunction(beschreibungPasswort)),
                      child: Text(beschreibungPasswort, style: TextStyle(color: textColor)))
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        globalFunctions.changePage(context, LoginPage());
                      },
                      child: Text("Abmelden", style: TextStyle(color: textColor)))
              ),
            ]
        );
      }

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
              child: Icon(Icons.more_vert, color: Colors.black),
              onPressed: () => openSettingWindow(),
            )
          ],
        ),
      );
    }




    return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: ListView(
            //crossAxisAlignment: CrossAxisAlignment.start,
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
