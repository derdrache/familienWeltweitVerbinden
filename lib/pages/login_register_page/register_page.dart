import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../custom_widgets.dart';
import '../../global_functions.dart' as globalFunctions;
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
        customSnackbar(context, "Registrierung erfolgreich, bitte Anmelden");
      }on FirebaseAuthException catch(error){
        if(error.code == "email-already-in-use"){
          customSnackbar(context, "Email ist schon in Benutzung");
        } else if(error.code == "invalid-email"){
          customSnackbar(context, "Email ist nicht gültig");
        } else if(error.code == "weak-password"){
          customSnackbar(context, "Passwort ist zu schwach");
        }
      }
    }
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
      appBar: CustomAppbar("Register", LoginPage()),
      body: Center(
        child: Form(
          key: _formKeyT,
          child: ListView(
            children: [
              customTextForm(
                  "Email", emailController,
                  validator: globalFunctions.checkValidatorEmpty()
              ),
              customTextForm(
                  "Passwort", passwordController, obsure: true,
                  validator: globalFunctions.checkValidatorEmpty()
              ),
              customTextForm(
                  "Passwort bestätigen", checkPasswordController, obsure: true,
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return "Bitte Passwort eingeben";
                    } else if(value != passwordController.text){
                      return "Passwort stimmt nicht überein";
                    }
                    return null;
                  }
              ),
              customFloatbuttonExtended("Registrieren", (){
                registration();
                dispose();
                globalFunctions.changePage(context, LoginPage());
              })
            ],
          ),
        )
      ),
    );
  }
}
