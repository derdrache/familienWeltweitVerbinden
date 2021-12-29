import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../custom_widgets.dart';
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

  userLogin() async{
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: passwort
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StartPage()));
    }on FirebaseAuthException catch(error){
      if(error.code == "user-not-found"){
        print("Benutzer nicht gefunden");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.blue,
          content: Text("Benutzer nicht gefunden"),
        ));
      } else if(error.code == "wrong-password"){
        print("Password ist falsch");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.blue,
          content: Text("Password ist falsch"),
        ));
      }
    };
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
        child: Center(
            child:Text(
                "Login",
              style: TextStyle(fontSize: 24),
            )
        ),
      );
    }

    Widget emailTextField(){
      return Container(
        margin: EdgeInsets.only(top:sideSpace,bottom: sideSpace),
        padding: EdgeInsets.only(left: sideSpace, right:sideSpace),
        child: TextFormField(
            controller: emailController,
            decoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black),
                ),
                border: OutlineInputBorder(),
                labelText: "Email",
            ),
            validator: (value){
                if(value == null || value.isEmpty){
                  return "Bitte Email Adresse eingeben";
                }
                else if(!value.contains("@")){
                  return "Bitte gültige Email Adresse eingeben";
                }
                return null;
            },
        ),
      );
    }

    Widget passwortTextField(){
      return Container(
        margin: EdgeInsets.only(top:sideSpace,bottom: sideSpace),
        padding: EdgeInsets.only(left: sideSpace, right:sideSpace),
        child: TextFormField(
          controller: passwortController,
          decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
            ),
            border: OutlineInputBorder(),
            labelText: "Passwort",
          ),
          validator: (value){
            if(value == null || value.isEmpty){
              return "Bitte Passwort eingeben";
            }
            return null;
          },
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

    return Scaffold(
        body: Form(
          key: _formKey,
            child: ListView(
              children: [
                header(),
                emailTextField(),
                passwortTextField(),
                TextButton( child: Text("Passwort vergessen?"), onPressed: (){
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context)=> ForgetPasswordPage())
                  );
                }),
                customFloatbuttonExtended("Login", () => doLogin()),
                customFloatbuttonExtended("Register", (){
                  Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                          pageBuilder: (context,a,b)=> RegisterPage(),
                          transitionDuration: Duration(seconds: 0)
                      ),
                          (route) => false);
                }),
              ],
            )
        )
    );
  }
}
