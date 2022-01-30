import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as globalFunctions;
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final checkPasswordController = TextEditingController();
  final _formKeyT = GlobalKey<FormState>();


  registration() async{
    if(_formKeyT.currentState!.validate()){
      var email = emailController.text;
      var password = passwordController.text;

      try{
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        customSnackbar(context, "Registrierung erfolgreich, bitte Anmelden", color: Colors.green);
        return true;
      }on FirebaseAuthException catch(error){
        if(error.code == "email-already-in-use"){
          customSnackbar(context, "Email ist schon in Benutzung");
        } else if(error.code == "invalid-email"){
          customSnackbar(context, "Email ist nicht gültig");
        } else if(error.code == "weak-password"){
          customSnackbar(context, "Passwort ist zu schwach");
        }

        return false;
      }
    }
    return false;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    checkPasswordController.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: "Register"),
      body: Center(
        child: Form(
          key: _formKeyT,
          child: ListView(
            children: [
              customTextInput(
                  "Email", emailController,
                  validator: globalFunctions.checkValidationEmail()
              ),
              customTextInput(
                  "Passwort", passwordController, passwort: true,
                  validator: globalFunctions.checkValidatorPassword()
              ),
              customTextInput(
                  "Passwort bestätigen", checkPasswordController, passwort: true,
                  validator: globalFunctions.checkValidatorPassword(
                      passwordCheck: passwordController.text)
              ),
              customFloatbuttonExtended("Registrieren", () async{
                var registrationComplete = await registration();
                if(registrationComplete){
                  globalFunctions.changePage(context, LoginPage());
                }
              })
            ],
          ),
        )
      ),
    );
  }
}
