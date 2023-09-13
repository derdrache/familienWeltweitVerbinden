import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/encryption.dart';
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';

class ChangeEmailPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String userEmail = FirebaseAuth.instance.currentUser!.email!;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  ChangeEmailPage({Key? key}) : super(key: key);

  userLogin(password) async {
    var userEmail = FirebaseAuth.instance.currentUser!.email;
    UserCredential? loginUser;
    try {
      loginUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail ?? "", password: password);
    } on FirebaseAuthException catch (_) {
      loginUser = null;
    }

    return loginUser;
  }

  @override
  Widget build(BuildContext context) {

    checkValidationAndError() async {
      if (emailController.text.isEmpty) {
        customSnackBar(context, AppLocalizations.of(context)!.emailEingeben);
        return false;
      }
      if (passwordController.text.isEmpty) {
        customSnackBar(context, AppLocalizations.of(context)!.passwortEingeben);
        return false;
      }

      bool emailIsValid = RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(emailController.text);
      if (!emailIsValid) {
        customSnackBar(context, AppLocalizations.of(context)!.emailUngueltig);
        return false;
      }

      var loginUser = await userLogin(passwordController.text);
      if (loginUser == null && context.mounted) {
        customSnackBar(
            context, AppLocalizations.of(context)!.emailOderPasswortFalsch);
        return false;
      }

      return true;
    }

    save() async {
      bool isValid = await checkValidationAndError();
      var encryptedEmail = encrypt(emailController.text);

      if(!isValid) return;

      try{
        await FirebaseAuth.instance.currentUser!.updateEmail(emailController.text);
      }catch(error){
        if(context.mounted) customSnackBar(context, AppLocalizations.of(context)!.emailInBenutzung);
        return;
      }

      updateHiveOwnProfil("email", emailController.text);
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
                  AppLocalizations.of(context)!.neueEmail, emailController, keyboardType: TextInputType.emailAddress),

              const SizedBox(height: 15),
              CustomTextInput(AppLocalizations.of(context)!.passwortBestaetigen,
                  passwordController,
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
