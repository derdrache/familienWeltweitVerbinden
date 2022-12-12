import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangePasswortPage extends StatelessWidget {
  TextEditingController passwortOldKontroller = TextEditingController();
  TextEditingController passwortNewKontroller = TextEditingController();
  TextEditingController passwortNewCheckKontroller = TextEditingController();

  ChangePasswortPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    validationAndError(newPasswort, newPasswortCheck, oldPasswort){
      if (newPasswort == "" || newPasswort == oldPasswort) {
        customSnackbar(
            context, AppLocalizations.of(context).neuesPasswortEingeben);
        return false;
      }
      if (newPasswortCheck == "") {
        customSnackbar(context,
            AppLocalizations.of(context).neuesPasswortWiederholen);
        return false;
      }
      if (oldPasswort == "") {
        customSnackbar(
            context, AppLocalizations.of(context).altesPasswortEingeben);
        return false;
      }
      if (newPasswort != newPasswortCheck) {
        customSnackbar(context,
            AppLocalizations.of(context).passwortStimmtNichtMitNeuem);
        return false;
      }

      return true;
    }

    userLogin(passwort) async {
      var userEmail = FirebaseAuth.instance.currentUser.email;
      var loginUser;
      try {
        loginUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: userEmail ?? "", password: passwort);
      } on FirebaseAuthException catch (_) {
        customSnackbar(
            context, AppLocalizations.of(context).altesPasswortFalsch);
        loginUser = null;
      }

      return loginUser;
    }

    save() async{
      String newPasswort = passwortNewKontroller.text;
      String newPasswortCheck = passwortNewCheckKontroller.text;
      String oldPasswort = passwortOldKontroller.text;

      bool isValid = validationAndError(
          newPasswort, newPasswortCheck, oldPasswort);
      var loginUser = await userLogin(oldPasswort);

      if(!isValid || loginUser == null) return;

      try {
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
    }

    return Scaffold(
        appBar: CustomAppBar(
            title: AppLocalizations.of(context).passwortVeraendern,),
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
                  passwort: true),
              const SizedBox(height: 20),
              FloatingActionButton.extended(
                  label: Text(
                    AppLocalizations.of(context).speichern,
                    style: const TextStyle(fontSize: 20),
                  ),
                  icon: const Icon(Icons.save),
                  onPressed: () => save())
            ],
          ),
        ));
  }
}
