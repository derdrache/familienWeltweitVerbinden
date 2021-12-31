import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../custom_widgets.dart';
import '../../global_functions.dart' as globalFunction;
import 'login_page.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  var emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void resetPassword() async {
    if(_formKey.currentState!.validate()){
      try{
        await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text);
        customSnackbar(context, "Email zum Passwort zurücksetzen wurde versendet");

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginPage() )
        );
      }on FirebaseAuthException catch(error){
        if(error.code == "user-not-found"){
          customSnackbar(context, "kein User zu der Email Adresse gefunden");
        }
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar("Reset Passwort", LoginPage()),
      body: Container(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SizedBox(height: 100),
                Center(child: Text("Reset Link wird an deine Email Adresse gesendet")),
                customTextForm("Email", emailController,
                    validator: globalFunction.checkValidatorEmpty()),
                customFloatbuttonExtended("Send Email", () => resetPassword())
              ],
            ),
          )
        )
    );
  }
}
