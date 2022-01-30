import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as globalFunctions;
import 'login_page.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  var emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  resetPassword() async {
    if(_formKey.currentState!.validate()){
      try{
        await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text);
        customSnackbar(context, "Email zum Passwort zurücksetzen wurde versendet",
            color: Colors.green);
        return true;
      }on FirebaseAuthException catch(error){
        if(error.code == "user-not-found"){
          customSnackbar(context, "kein User zu der Email Adresse gefunden");
        }
        return false;
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
      appBar: customAppBar(title: "Reset Passwort"),
      body: Container(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SizedBox(height: 20),
                Center(child: Text("Reset Link wird an deine Email Adresse gesendet")),
                customTextInput("Email", emailController,
                    validator: globalFunctions.checkValidationEmail()),
                customFloatbuttonExtended("Send Email", () async{
                  var wasReset = await resetPassword();
                  if (wasReset){
                    globalFunctions.changePage(context, LoginPage());
                  }

                })
              ],
            ),
          )
        )
    );
  }
}
