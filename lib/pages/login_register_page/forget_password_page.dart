import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as globa_functions;
import '../../widgets/custom_appbar.dart';
import 'login_page.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({Key key}) : super(key: key);

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  var emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  resetPassword() async {
    if (_formKey.currentState.validate()) {
      try {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: emailController.text);
        customSnackbar(
            context, AppLocalizations.of(context).emailZuruecksetzenPasswort,
            color: Colors.green);
        return true;
      } on FirebaseAuthException catch (error) {
        if (error.code == "user-not-found") {
          customSnackbar(
              context, AppLocalizations.of(context).userEmailNichtGefunden);
        }
        return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            title: AppLocalizations.of(context).passwortZuruecksetzen),
        body: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Center(
                  child: Text(AppLocalizations.of(context).passwortResetLink)),
              customTextInput("Email", emailController,
                  validator: globa_functions.checkValidationEmail(context)),
              customFloatbuttonExtended(
                  AppLocalizations.of(context).emailSenden, () async {
                var wasReset = await resetPassword();
                if (wasReset) {
                  globa_functions.changePageForever(context, const LoginPage());
                }
              })
            ],
          ),
        ));
  }
}
