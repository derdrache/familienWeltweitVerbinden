import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangePasswortPage extends StatelessWidget {
  var passwortOldKontroller = TextEditingController();
  var passwortNewKontroller = TextEditingController();
  var passwortNewCheckKontroller = TextEditingController();

  ChangePasswortPage({Key key}) : super(key: key);

  userLogin(passwort) async {
    var userEmail = FirebaseAuth.instance.currentUser.email;
    var loginUser;
    try {
      loginUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail ?? "", password: passwort);
    } on FirebaseAuthException catch (e) {
      print(e);
      loginUser = null;
    }

    return loginUser;
  }

  @override
  Widget build(BuildContext context) {
    saveButton() {
      return IconButton(
          icon: const Icon(Icons.done),
          onPressed: () async {
            var newPasswort = passwortNewKontroller.text;
            var newPasswortCheck = passwortNewCheckKontroller.text;
            var oldPasswort = passwortOldKontroller.text;

            if (newPasswort == "" || newPasswort == oldPasswort) {
              customSnackbar(
                  context, AppLocalizations.of(context).neuesPasswortEingeben);
              return;
            }
            if (newPasswortCheck == "") {
              customSnackbar(context,
                  AppLocalizations.of(context).neuesPasswortWiederholen);
              return;
            }
            if (oldPasswort == "") {
              customSnackbar(
                  context, AppLocalizations.of(context).altesPasswortEingeben);
              return;
            }
            if (newPasswort != newPasswortCheck) {
              print(newPasswort);
              print(newPasswortCheck);
              customSnackbar(context,
                  AppLocalizations.of(context).passwortStimmtNichtMitNeuem);
              return;
            }

            try {
              var loginTest = await userLogin(oldPasswort);

              if (loginTest == null) {
                customSnackbar(
                    context, AppLocalizations.of(context).altesPasswortFalsch);
                return;
              }

              await FirebaseAuth.instance.currentUser
                  ?.updatePassword(newPasswort);

              customSnackbar(
                  context,
                  AppLocalizations.of(context).passwort +
                      " " +
                      AppLocalizations.of(context).erfolgreichGeaender,
                  color: Colors.green);

              Navigator.pop(context);
            } catch (error) {
              customSnackbar(
                  context, AppLocalizations.of(context).neuesPasswortSchwach);
            }
          });
    }

    return Scaffold(
        appBar: CustomAppBar(
            title: AppLocalizations.of(context).passwortVeraendern,
            buttons: [saveButton()]),
        body: Container(
          margin: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              customTextInput(
                  AppLocalizations.of(context).neuesPasswortEingeben,
                  passwortNewKontroller,
                  passwort: true),
              const SizedBox(height: 15),
              customTextInput(
                  AppLocalizations.of(context).neuesPasswortWiederholen,
                  passwortNewCheckKontroller,
                  passwort: true),
              const SizedBox(height: 15),
              customTextInput(
                  AppLocalizations.of(context).altesPasswortEingeben,
                  passwortOldKontroller,
                  passwort: true)
            ],
          ),
        ));
  }
}
