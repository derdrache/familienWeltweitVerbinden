import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final checkPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  registrationButton()async{
    setState(() {
      isLoading = true;
    });
    var registrationComplete = await registration();
    if(registrationComplete){
      customSnackbar(context, AppLocalizations.of(context).registerAndEmailBestaetigen, color: Colors.green);
      global_functions.changePageForever(context, const LoginPage());
    }
  }

  registration() async{
    if(formKey.currentState.validate()){
      var email = emailController.text;
      email = email.replaceAll(' ', '');
      var password = passwordController.text;

      try{
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        FirebaseAuth.instance.currentUser?.sendEmailVerification();

        return true;
      }on FirebaseAuthException catch(error){
        setState(() {
          isLoading = false;
        });
        if(error.code == "email-already-in-use"){
          customSnackbar(context, AppLocalizations.of(context).emailInBenutzung);
        } else if(error.code == "invalid-email"){
          customSnackbar(context, AppLocalizations.of(context).emailUngueltig);
        } else if(error.code == "weak-password"){
          customSnackbar(context, AppLocalizations.of(context).passwortSchwach);
        } else if(error.code == "network-request-failed"){
          customSnackbar(context, AppLocalizations.of(context).keineVerbindungInternet);
        }

        return false;
      }
    }

    setState(() {
      isLoading = false;
    });

    return false;
  }

  loading(){
    return const SizedBox(
      width: 40,
      height: 40,
      child: Center(child: CircularProgressIndicator())
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context).registrieren),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Center(
          child: Form(
            key: formKey,
            child: ListView(
              children: [
                customTextInput(
                  "Email", emailController,
                  validator: global_functions.checkValidationEmail(context),
                  textInputAction: TextInputAction.next
                ),
                customTextInput(
                  AppLocalizations.of(context).passwort, passwordController, passwort: true,
                  validator: global_functions.checkValidatorPassword(context),
                  textInputAction: TextInputAction.next
                ),
                customTextInput(
                  AppLocalizations.of(context).passwortBestaetigen, checkPasswordController, passwort: true,
                  validator: global_functions.checkValidatorPassword(
                    context,
                    passwordCheck: passwordController.text),
                    textInputAction: TextInputAction.done,
                    onSubmit: () => registrationButton()
                  ),
                isLoading ? loading():
                customFloatbuttonExtended(AppLocalizations.of(context).registrieren, () => registrationButton())
              ],
            ),
          )
        ),
      ),
    );
  }
}
