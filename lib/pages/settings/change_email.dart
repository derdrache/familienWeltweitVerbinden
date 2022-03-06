import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/global_functions.dart' as global_functions;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../login_register_page/login_page.dart';


class ChangeEmailPage extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var userEmail = FirebaseAuth.instance.currentUser?.email;
  var emailKontroller = TextEditingController();
  var passwortKontroller = TextEditingController();

  ChangeEmailPage({Key key}) : super(key: key);

  userLogin(passwort) async {
    var userEmail = FirebaseAuth.instance.currentUser.email;
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

    saveFunction()async {
      if(emailKontroller.text == ""){
        customSnackbar(context, AppLocalizations.of(context).emailEingeben);
        return;
      }
      if(passwortKontroller.text == ""){
        customSnackbar(context, AppLocalizations.of(context).passwortEingeben);
        return;
      }

      bool emailIsValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(emailKontroller.text);
      if(!emailIsValid){
        customSnackbar(context, AppLocalizations.of(context).emailUngueltig);
        return;
      }

      var emailInUse = await ProfilDatabase().getOneData("id", "email", emailKontroller.text);
      if (emailInUse != false){
        customSnackbar(context, AppLocalizations.of(context).emailInBenutzung);
        return;
      }

      var loginUser = await userLogin(passwortKontroller.text);
      if(loginUser == null){
        customSnackbar(context, AppLocalizations.of(context).emailOderPasswortFalsch);
        return;
      }


      FirebaseAuth.instance.currentUser.verifyBeforeUpdateEmail(emailKontroller.text);
      await ProfilDatabase().updateProfil(userId,"email",emailKontroller.text);
      customSnackbar(context, AppLocalizations.of(context).neueEmailVerifizieren, color: Colors.green);
      Navigator.pop(context);
    }

    saveButton() {
      return TextButton(
          child: Icon(Icons.done),
          onPressed: () => saveFunction()
      );
    }

    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context).emailAendern,buttons: [saveButton()]),
      body: Column(
        children: [
          customTextInput(AppLocalizations.of(context).neueEmail,emailKontroller),
          const SizedBox(height: 15),
          customTextInput(AppLocalizations.of(context).passwortBestaetigen,
              passwortKontroller, passwort: true, onSubmit: () => saveFunction())
        ],
      )
    );
  }
}
