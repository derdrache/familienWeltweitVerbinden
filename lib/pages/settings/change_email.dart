import 'package:familien_suche/global/encryption.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';

class ChangeEmailPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String userEmail = FirebaseAuth.instance.currentUser!.email!;
  TextEditingController emailKontroller = TextEditingController();
  TextEditingController passwortKontroller = TextEditingController();

  ChangeEmailPage({Key? key}) : super(key: key);

  userLogin(passwort) async {
    var userEmail = FirebaseAuth.instance.currentUser!.email;
    UserCredential? loginUser;
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

    checkValidationAndError() async {
      if (emailKontroller.text.isEmpty) {
        customSnackbar(context, AppLocalizations.of(context)!.emailEingeben);
        return false;
      }
      if (passwortKontroller.text.isEmpty) {
        customSnackbar(context, AppLocalizations.of(context)!.passwortEingeben);
        return false;
      }

      bool emailIsValid = RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(emailKontroller.text);
      if (!emailIsValid) {
        customSnackbar(context, AppLocalizations.of(context)!.emailUngueltig);
        return false;
      }

      var loginUser = await userLogin(passwortKontroller.text);
      if (loginUser == null && context.mounted) {
        customSnackbar(
            context, AppLocalizations.of(context)!.emailOderPasswortFalsch);
        return false;
      }

      return true;
    }

    save() async {
      bool isValid = await checkValidationAndError();
      var encryptedEmail = encrypt(emailKontroller.text);

      if(!isValid) return;

      try{
        await FirebaseAuth.instance.currentUser!.updateEmail(emailKontroller.text);
      }catch(error){
        if(context.mounted) customSnackbar(context, AppLocalizations.of(context)!.emailInBenutzung);
        return;
      }

      updateHiveOwnProfil("email", emailKontroller.text);
      ProfilDatabase().updateProfil(
          "email = '$encryptedEmail'", "WHERE id = '$userId'");

      if(context.mounted) Navigator.pop(context);
    }

    return Scaffold(
        appBar: CustomAppBar(
            title: AppLocalizations.of(context)!.emailAendern,),
        body: Container(
          margin: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              CustomTextInput(
                  AppLocalizations.of(context)!.neueEmail, emailKontroller, keyboardType: TextInputType.emailAddress),

              const SizedBox(height: 15),
              CustomTextInput(AppLocalizations.of(context)!.passwortBestaetigen,
                  passwortKontroller,
                  hideInput: true, onSubmit: () => save()),
              const SizedBox(height: 20),
              FloatingActionButton.extended(
                  label: Text(
                    AppLocalizations.of(context)!.speichern,
                    style: const TextStyle(fontSize: 20),
                  ),
                  icon: const Icon(Icons.save),
                  onPressed: () => save())
            ],
          ),
        ));
  }
}
