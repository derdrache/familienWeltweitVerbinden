import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../start_page.dart';
import '../login_register_page/register_page.dart';
import '../login_register_page/forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwortController = TextEditingController();
  var email = "";
  var passwort = "";
  bool isLoading = false;

  loading(){
    return Container(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator())
    );
  }

  userLogin() async{
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: passwort);
      global_functions.changePageForever(context, StartPage());
    }on FirebaseAuthException catch(error){
      setState(() {
        isLoading = false;
      });
      if(error.code == "user-not-found"){
        customSnackbar(context, "Benutzer nicht gefunden");
      } else if(error.code == "wrong-password"){
        customSnackbar(context, "Password ist falsch");
      }
    }
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
        child: SizedBox(
          width: 150,
          child: TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(Colors.black)
              ),
              child: const Text("Passwort vergessen?"),
              onPressed: (){
                passwortController.text = "";
                global_functions.changePage(context, const ForgetPasswordPage());
              }
          ),
        ),
      );
    }

    doLogin(){
      if(_formKey.currentState!.validate()){
        setState(() {
          isLoading = true;
          email = emailController.text;
          passwort = passwortController.text;
        });
        userLogin();
      }
    }

    return Scaffold(
        body: Form(
          key: _formKey,
            child: ListView(
              children: [
                header(),
                customTextInput("Email", emailController,
                    validator: global_functions.checkValidationEmail()),
                customTextInput("Passwort", passwortController,
                    validator: global_functions.checkValidatorPassword(),
                    passwort: true),
                forgetPassButton(),
                isLoading ? loading() : customFloatbuttonExtended("Login", () => doLogin()),
                customFloatbuttonExtended("Register", (){
                  global_functions.changePage(context, const RegisterPage());
                }),
              ],
            )
        )
    );
  }
}
