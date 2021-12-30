import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../custom_widgets.dart';
import '../../global_functions.dart' as globalFunction;
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final checkPasswordController = TextEditingController();
  final _formKeyT = GlobalKey<FormState>();

  registration() async{
    if(_formKeyT.currentState!.validate()){
      var name = nameController.text;
      var email = emailController.text;
      var password = passwordController.text;

      try{
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        print(userCredential);
        
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Registrierung erfolgreich, bitte Anmelden")
            )
        );

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginPage() )
        );
      }on FirebaseAuthException catch(error){
        print("error");
      }
    }
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
                  "Nickname",
                  nameController,
                  globalFunction.checkValidatorEmpty()
              ),
              customTextForm(
                  "Email",
                  emailController,
                  globalFunction.checkValidatorEmail()
              ),
              customTextForm(
                  "Passwort",
                  passwordController,
                  globalFunction.checkValidatorEmpty()
              ),
              customTextForm(
                  "Passwort bestätigen",
                  checkPasswordController,
                  (value){
                    if(value == null || value.isEmpty){
                      return "Bitte Passwort eingeben";
                    } else if(value != passwordController.text){
                      return "Passwort stimmt nicht überein";
                    }
                    return null;
                  }
              ),
              customFloatbuttonExtended("Registrieren", () => registration())
            ],
          ),
        )
      ),
    );
  }
}
