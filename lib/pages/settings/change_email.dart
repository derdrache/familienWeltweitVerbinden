import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

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
          email: userEmail ?? "", password: passwort);
    } on FirebaseAuthException catch (_) {
      loginUser = null;
    }

    return loginUser;
  }

  @override
  Widget build(BuildContext context) {
    saveFunction() async {
      if (emailKontroller.text == "") {
        customSnackbar(context, AppLocalizations.of(context).emailEingeben);
        return;
      }
      if (passwortKontroller.text == "") {
        customSnackbar(context, AppLocalizations.of(context).passwortEingeben);
        return;
      }

      bool emailIsValid = RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(emailKontroller.text);
      if (!emailIsValid) {
        customSnackbar(context, AppLocalizations.of(context).emailUngueltig);
        return;
      }

      var emailInUse = await ProfilDatabase()
          .getData("id", "WHERE email = '${emailKontroller.text}'");
      if (emailInUse != false) {
        customSnackbar(context, AppLocalizations.of(context).emailInBenutzung);
        return;
      }

      var loginUser = await userLogin(passwortKontroller.text);
      if (loginUser == null) {
        customSnackbar(
            context, AppLocalizations.of(context).emailOderPasswortFalsch);
        return;
      }

      FirebaseAuth.instance.currentUser
          .verifyBeforeUpdateEmail(emailKontroller.text);
      await ProfilDatabase().updateProfil(
          "email = '${emailKontroller.text}'", "WHERE id = '$userId'");

      customSnackbar(
          context, AppLocalizations.of(context).neueEmailVerifizieren,
          color: Colors.green);

      customSnackbar(
          context, "Email " + AppLocalizations.of(context).erfolgreichGeaender,
          color: Colors.green);

      Navigator.pop(context);
    }

    saveButton() {
      return IconButton(
          icon: const Icon(Icons.done), onPressed: () => saveFunction());
    }

    return Scaffold(
        appBar: CustomAppBar(
            title: AppLocalizations.of(context).emailAendern,
            buttons: [saveButton()]),
        body: Container(
          margin: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              customTextInput(
                  AppLocalizations.of(context).neueEmail, emailKontroller),
              const SizedBox(height: 15),
              customTextInput(AppLocalizations.of(context).passwortBestaetigen,
                  passwortKontroller,
                  passwort: true, onSubmit: () => saveFunction())
            ],
          ),
        ));
  }
}
