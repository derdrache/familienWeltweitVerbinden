import 'package:flutter/material.dart';

import '../../custom_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwortController = TextEditingController();

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

    return Scaffold(
        body: Container(
            child: ListView(
              children: [
                header(),
                emailTextField(),
                passwortTextField(),
                TextButton(onPressed: null, child: Text("Passwort vergessen?")),
                customFloatbuttonExtended("Login", null),
                customFloatbuttonExtended("Register", null),
              ],
            )
        )
    );
  }
}
