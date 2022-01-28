import 'package:familien_suche/pages/settings/privacy_security_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../global/global_functions.dart';
import '../../services/database.dart';
import '../../global/global_functions.dart' as globalFunctions;
import '../../windows/change_profil_window.dart';
import '../../global/custom_widgets.dart';
import '../../global/variablen.dart' as globalVariablen;
import '../../services/locationsService.dart';
import '../login_register_page/login_page.dart';


class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double globalPadding = 30;
  double fontSize = 16;
  var borderColor = Colors.grey[200]!;
  var userProfil;
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


  getProfilFromDatabase() async {
    emailTextKontroller.text = FirebaseAuth.instance.currentUser!.email!;
    nameTextKontroller.text = FirebaseAuth.instance.currentUser!.displayName!;
    userProfil = await dbGetProfil(nameTextKontroller.text);
  }

  void getAndSetDataFromDB() async {
    List childrenAgeTimestamp = [];
    try{
      await getProfilFromDatabase();
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
    var locationData;
    while(locationData == null){
      locationData = await LocationService().getLocationMapDataGeocode(ortKontroller.text);
    }

    var locationDict = {
      "ort": locationData["city"],
      "longt": double.parse(locationData["longt"]),
      "latt": double.parse(locationData["latt"]),
      "land": locationData["countryname"]
    };
    dbChangeProfil(userProfil["docid"], locationDict);
  }

  validAndSave(beschreibung) async{
    String errorMessage = "";

    if(beschreibung == beschreibungStadt){
      pushLocationDataToDB();
    }else if(beschreibung == beschreibungReise){
      dbChangeProfil(userProfil["docid"], {"reiseart": reiseArtInput.getSelected()});
    }else if(beschreibung == beschreibungKinder){
      dbChangeProfil(userProfil["docid"], {"kinder": kinderAgeBox.getDates()});
    }else if(beschreibung == beschreibungInteressen){
      dbChangeProfil(userProfil["docid"], {"interessen": interessenInputBox.getSelected()});
    }else if(beschreibung == beschreibungSprachen){
      dbChangeProfil(userProfil["docid"], {"sprachen": sprachenInputBox.getSelected()});
    }else if(beschreibung == beschreibungBio){
      dbChangeProfil(userProfil["docid"], {"aboutme": bioTextKontroller.text});
    }else if(beschreibung == beschreibungName){
      dbChangeUserName(userProfil["docid"],userProfil["name"],nameTextKontroller.text);
    } else if (beschreibung == beschreibungEmail){
      errorMessage = await checkPasswortAndNewEmail();
      if(errorMessage == ""){
        FirebaseAuth.instance.currentUser?.updateEmail(emailTextKontroller.text);
        dbChangeProfil(userProfil["docid"], {"email":emailTextKontroller.text });
      }


    } else if (beschreibung == beschreibungPasswort){
      FirebaseAuth.instance.currentUser?.updatePassword(passwortTextKontroller.text);
    }

    if(errorMessage.isEmpty){
      setState(() {});
      Navigator.of(context, rootNavigator: true).pop();
    } else{
      customSnackbar(context, errorMessage);
    }


  }

  checkPasswortAndNewEmail() async {
    var errorString = "";

    if(passwortTextKontroller.text != "" && emailTextKontroller.text != ""){
      bool emailIsValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(emailTextKontroller.text);
      var emailInUse = await dbGetProfilFromEmail(emailTextKontroller.text);

      if (emailInUse != null){
        errorString += "- Email wird schon verwendet";
      } else if (emailIsValid){
        var loginUser;
        try {
          loginUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: userProfil["email"],
              password: passwortTextKontroller.text
          );
        } on FirebaseAuthException catch  (e) {
          loginUser = null;
        }

        if(loginUser != null){
          return "";
        } else{
          errorString += "falsches Passwort";
        }
      } else {
        errorString += "- ungültige Email";
      }
    } else{
      if(passwortTextKontroller.text == ""){
        errorString += "- Passwort eingeben \n";
      }
      if(emailTextKontroller.text == ""){
        errorString += "- Email eingeben \n";
      }
    }
    return errorString;
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double containerPadding = 5;


    themeContainer(haupttext, beschreibung, changeWidget){
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => profilChangeWindow(context, beschreibung, changeWidget,
          () => validAndSave(beschreibung),
        ),//profilChangeWindow(context, beschreibung, changeWidget, () => validAndSave(beschreibung)),
        child: Container(
            padding: EdgeInsets.only(top: containerPadding, bottom: containerPadding),
            width: width /2 -20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                haupttext == ""? CircularProgressIndicator() : Text(haupttext,
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

    emailChangeWindow(){
      return Column(
        children: [
          customTextfield(beschreibungEmail,emailTextKontroller),
          SizedBox(height: 15),
          customTextfield("Passwort bestätigen",passwortTextKontroller)
        ],
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
                              () => validAndSave(beschreibungName)),
                      child: Text(beschreibungName, style: TextStyle(color: textColor)))
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: () => profilChangeWindow(context, beschreibungEmail,
                          emailChangeWindow(),
                          () => validAndSave(beschreibungEmail)
                      ),
                      child: Text(beschreibungEmail, style: TextStyle(color: textColor))
                  )
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: () => profilChangeWindow(context, beschreibungPasswort,
                          customTextfield(beschreibungPasswort, passwortTextKontroller),
                              () => validAndSave(beschreibungPasswort)),
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

      return  customAppBar(
          title: "",
          elevation: 0.0,
          button: TextButton(
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
      );
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
              themeContainer(bioTextKontroller.text== ""? " ": bioTextKontroller.text,
                  beschreibungBio,
                  customTextfield("über mich", bioTextKontroller)
              )
            ],
          )
      );
    }

    settingContainer(){

      themeContainer(title, icon, function){
        return GestureDetector(
          excludeFromSemantics: true,
          onTap: function,
          child: Container(
              child: Row(
                children: [
                  Icon(icon),
                  SizedBox(width: 20),
                  Text(title)
                ],
              )
          ),
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
              themeContainer("Privatsphäre und Sicherheit", Icons.lock,
                      () => changePage(context, PrivacySecurityPage(profil: userProfil))
              ),
              SizedBox(height: 20),

            ],
          )
      );
    }


    return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: ListView(
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
