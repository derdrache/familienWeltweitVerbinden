import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    return const SizedBox(
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

      bool emailVerified = FirebaseAuth.instance.currentUser?.emailVerified?? false;

      if(emailVerified){
        global_functions.changePageForever(context, StartPage());
      } else{
        setState(() {
          isLoading = false;
        });
        customSnackbar(context, AppLocalizations.of(context)!.emailNichtBestaetigt);
      }

    }on FirebaseAuthException catch(error){
      setState(() {
        isLoading = false;
      });
      if(error.code == "user-not-found"){
        customSnackbar(context, AppLocalizations.of(context)!.benutzerNichtGefunden);
      } else if(error.code == "wrong-password"){
        customSnackbar(context, AppLocalizations.of(context)!.passwortFalsch);
      } else if(error.code == "network-request-failed"){
        customSnackbar(context, AppLocalizations.of(context)!.keineVerbindungInternet);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double sideSpace = 20;

    Widget header(){
      return Container(
        margin: EdgeInsets.only(top: sideSpace, bottom: sideSpace),
        child: Column(
          children: [
            Center(
                child: Image.asset('assets/WeltFlugzeug.png')
            ),
            SizedBox(height: 15),
            Text(AppLocalizations.of(context)!.willkommenBeiAppName, style: TextStyle(fontSize: 20),)
          ],
        )



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
              child: Text(AppLocalizations.of(context)!.passwortVergessen),
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
                    validator: global_functions.checkValidationEmail(context),
                    textInputAction: TextInputAction.next
                ),
                customTextInput(AppLocalizations.of(context)!.passwort, passwortController,
                    validator: global_functions.checkValidatorPassword(context),
                    passwort: true,
                    textInputAction: TextInputAction.done,
                    onSubmit: () => doLogin()),
                forgetPassButton(),
                isLoading ? loading() : customFloatbuttonExtended("Login", () => doLogin()),
                customFloatbuttonExtended(AppLocalizations.of(context)!.registrieren, (){
                  global_functions.changePage(context, const RegisterPage());
                })
              ],
            )
        )
    );
  }
}
