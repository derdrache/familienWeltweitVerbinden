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

  submit(){
    if(_formKeyT.currentState!.validate()){
        print(nameController.text);
        print(emailController.text);
        print(passwordController.text);
        print(checkPasswordController.text);
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
              customFloatbuttonExtended("Registrieren", () => submit())
            ],
          ),
        )
      ),
    );
  }
}
