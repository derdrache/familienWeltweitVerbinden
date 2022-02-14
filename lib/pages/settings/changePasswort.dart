import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';

class ChangePasswortPage extends StatelessWidget {
  var passwortOldKontroller = TextEditingController();
  var passwortNewKontroller = TextEditingController();
  var passwortNewCheckKontroller = TextEditingController();

  ChangePasswortPage({Key? key}) : super(key: key);

  userLogin(passwort) async {
    var userEmail = FirebaseAuth.instance.currentUser!.email;
    var loginUser;
    try {
      loginUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail??"",
          password: passwort
      );
    } on FirebaseAuthException catch  (e) {
      print(e);
      loginUser = null;
    }

    return loginUser;
  }

  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: () async {
          var newPasswort = passwortNewKontroller.text;
          var newPasswortCheck = passwortNewCheckKontroller.text;
          var oldPasswort = passwortOldKontroller.text;

          if (newPasswort == "" || newPasswort == oldPasswort){
            customSnackbar(context, "neues Passwort eingeben");
            return;
          }
          if(newPasswortCheck == ""){
            customSnackbar(context, "neues Passwort bestätigen");
            return;
          }
          if(oldPasswort == ""){
            customSnackbar(context, "altes Passwort eingeben");
            return;
          }
          if (newPasswort != newPasswortCheck){
            customSnackbar(context, "Passwort bestätigung stimmt nicht mit dem neuen Passwort überein");
            return;
          }

          try{
            var loginTest = await userLogin(oldPasswort);

            if(loginTest == null){
              customSnackbar(context, "Altes Passwort ist falsch");
              return;
            }

            await FirebaseAuth.instance.currentUser?.updatePassword(newPasswort);
            Navigator.pop(context);

          } catch (error){
            customSnackbar(context, "Neues Passwort ist zu schwach");
          }
        }
      );
    }

    return Scaffold(
      appBar: customAppBar(title: "Passwort ändern", button: saveButton()),
      body: Column(
        children: [
          customTextInput("Neues Passwort eingeben", passwortNewKontroller,
              passwort: true),
          const SizedBox(height: 15),
          customTextInput("Neues Passwort wiederholen", passwortNewCheckKontroller,
              passwort: true),
          const SizedBox(height: 15),
          customTextInput("Altes Passwort eingeben", passwortOldKontroller,
              passwort: true)
        ],
      )
    );
  }
}
