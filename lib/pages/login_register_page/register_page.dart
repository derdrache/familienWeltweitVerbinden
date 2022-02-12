import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../start_page.dart';
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
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  var actionCodeSettings = {
    // URL you want to redirect back to. The domain (www.example.com) for this
    // URL must be in the authorized domains list in the Firebase Console.
    "url": 'https://www.example.com/finishSignUp?cartId=1234',
    // This must be true.
    "handleCodeInApp": true,
    "iOS": {
      "bundleId": 'com.example.ios'
    },
    "android": {
      "packageName": 'com.example.android',
      "installApp": true,
      "minimumVersion": '12'
    },
    "dynamicLinkDomain": 'example.page.link'
  };


  registration() async{
    if(formKey.currentState!.validate()){
      var email = emailController.text;
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
      appBar: customAppBar(title: "Register"),
      body: Center(
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              customTextInput(
                "Email", emailController,
                validator: global_functions.checkValidationEmail(),
                textInputAction: TextInputAction.next
              ),
              customTextInput(
                "Passwort", passwordController, passwort: true,
                validator: global_functions.checkValidatorPassword(),
                textInputAction: TextInputAction.next
              ),
              customTextInput(
                "Passwort bestätigen", checkPasswordController, passwort: true,
                validator: global_functions.checkValidatorPassword(
                passwordCheck: passwordController.text),
                textInputAction: TextInputAction.done
              ),
              isLoading ? loading(): customFloatbuttonExtended("Registrieren", () async{
                setState(() {
                  isLoading = true;
                });
                var registrationComplete = await registration();
                if(registrationComplete){
                  customSnackbar(context, "Registrierung erfolgreich, bitte Email bestätigen", color: Colors.green);
                  global_functions.changePageForever(context, LoginPage());
                }
              })
            ],
          ),
        )
      ),
    );
  }
}
