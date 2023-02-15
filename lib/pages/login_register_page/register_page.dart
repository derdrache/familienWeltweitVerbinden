import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../services/database/database.dart';
import '../../services/notification.dart';
import '../../widgets/custom_appbar.dart';
import '../../windows/nutzerrichtlinen.dart';
import 'create_profil_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final checkEmailController = TextEditingController();
  final passwordController = TextEditingController();
  final checkPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  registrationButton() async {
    setState(() {
      isLoading = true;
    });
    var registrationComplete = await registration();
    if (registrationComplete) {
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      global_functions.changePageForever(context, const CreateProfilPage());
    }
  }

  registration() async {
    var success = false;

    if (formKey.currentState.validate()) {
      var email = emailController.text;
      email = email.replaceAll(" ", "");
      var password = passwordController.text;

      try {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        success = true;
      } on FirebaseAuthException catch (error) {
        if (error.code == "email-already-in-use") {
          customSnackbar(
              context, AppLocalizations.of(context).emailInBenutzung);
        } else if (error.code == "invalid-email") {
          customSnackbar(context, AppLocalizations.of(context).emailUngueltig);
        } else if (error.code == "weak-password") {
          customSnackbar(context, AppLocalizations.of(context).passwortSchwach);
        } else if (error.code == "network-request-failed") {
          customSnackbar(
              context, AppLocalizations.of(context).keineVerbindungInternet);
        } else {
          sendEmail({
            "title": "Registrierungs Problem",
            "inhalt": """
             Email: ${FirebaseAuth.instance.currentUser?.email} hat Probleme mit dem Login
             Folgendes Problem ist aufgetaucht: $error"""
          });
        }
      }
    }

    setState(() {
      isLoading = false;
    });

    return success;
  }

  loadingBox() {
    return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: AppLocalizations.of(context).registrieren),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Center(
            child: Form(
          key: formKey,
          child: ListView(
            children: [
              customTextInput(
                "Email",
                emailController,
                validator: global_functions.checkValidationEmail(context),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
              ),
              customTextInput(AppLocalizations.of(context).emailBestaetigen,
                  checkEmailController,
                  validator: global_functions.checkValidationEmail(context,
                      emailCheck: emailController.text),
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress),
              customTextInput(
                  AppLocalizations.of(context).passwort, passwordController,
                  passwort: true,
                  validator: global_functions.checkValidatorPassword(context),
                  textInputAction: TextInputAction.next),
              customTextInput(AppLocalizations.of(context).passwortBestaetigen,
                  checkPasswordController,
                  passwort: true,
                  validator: global_functions.checkValidatorPassword(context,
                      passwordCheck: passwordController.text),
                  textInputAction: TextInputAction.done,
                  onSubmit: () => registrationButton()),
              NutzerrichtlinenAnzeigen(page: "register"),
              isLoading
                  ? loadingBox()
                  : customFloatbuttonExtended(
                      AppLocalizations.of(context).registrieren,
                      () => registrationButton())
            ],
          ),
        )),
      ),
    );
  }
}
