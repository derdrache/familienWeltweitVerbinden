import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as globalFunctions;
import '../start_page.dart';
import '../login_register_page/register_page.dart';
import '../login_register_page/forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var userLogedIn = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwortController = TextEditingController();
  var email = "";
  var passwort = "";


  userLogin() async{
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: passwort);
      globalFunctions.changePage(context, StartPage());
    }on FirebaseAuthException catch(error){
      if(error.code == "user-not-found"){
        customSnackbar(context, "Benutzer nicht gefunden");
      } else if(error.code == "wrong-password"){
        customSnackbar(context, "Password ist falsch");
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double sideSpace = 20;

    Widget header(){
      return Container(
        margin: EdgeInsets.only(top: sideSpace, bottom: sideSpace),
        child: const Center(
            child:Text(
                "Login",
              style: TextStyle(fontSize: 24),
            )
        ),
      );
    }

    Widget forgetPassButton(){
      return Align(
        child: Container(
          width: 150,
          child: FlatButton(
            hoverColor: Colors.transparent,
              child: Text("Passwort vergessen?"),
              onPressed: (){
                globalFunctions.changePage(context, ForgetPasswordPage());
              }
          ),
        ),
      );
    }

    doLogin(){
      if(_formKey.currentState!.validate()){
        setState(() {
          email = emailController.text;
          passwort = passwortController.text;
        });
        userLogin();
      }
    }

    return userLogedIn != null ? StartPage() : Scaffold(
        body: Form(
          key: _formKey,
            child: ListView(
              children: [
                header(),
                customTextInput("Email", emailController,
                    validator: globalFunctions.checkValidationEmail()),
                customTextInput("Passwort", passwortController,
                    validator: globalFunctions.checkValidatorPassword(),
                    passwort: true),
                forgetPassButton(),
                customFloatbuttonExtended("Login", () => doLogin()),
                customFloatbuttonExtended("Register", (){
                  globalFunctions.changePage(context, RegisterPage());
                }),
              ],
            )
        )
    );
  }
}
