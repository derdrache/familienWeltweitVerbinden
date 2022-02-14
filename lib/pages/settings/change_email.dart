import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';


class ChangeEmailPage extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var userEmail = FirebaseAuth.instance.currentUser?.email;
  var emailKontroller = TextEditingController();
  var passwortKontroller = TextEditingController();

  ChangeEmailPage({Key? key}) : super(key: key);

  userLogin(passwort) async {
    var userEmail = FirebaseAuth.instance.currentUser!.email;
    var loginUser;
    try {
      loginUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail??"",
          password: passwort
      );
    } on FirebaseAuthException catch  (e) {
      print(e);
      loginUser = null;
    }

    return loginUser;
  }

  @override
  Widget build(BuildContext context) {

    saveButton() {
      return TextButton(
          child: Icon(Icons.done),
          onPressed: () async {
            if(emailKontroller.text == ""){
              customSnackbar(context, "email eingeben");
              return;
            }
            if(passwortKontroller.text == ""){
              customSnackbar(context, "passwort eingeben");
              return;
            }

            bool emailIsValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(emailKontroller.text);
            if(!emailIsValid){
              customSnackbar(context, "ungültige Email");
              return;
            }

            var emailInUse = await ProfilDatabase()
                .getProfilId("email", emailKontroller.text);
            if (emailInUse != null){
              customSnackbar(context, "Email wird schon verwendet");
              return;
            }

            var loginUser = await userLogin(passwortKontroller.text);
            if(loginUser == null){
              customSnackbar(context, "Email oder Passwort falsch");
              return;
            }

            FirebaseAuth.instance.currentUser?.updateEmail(emailKontroller.text);

            ProfilDatabase().updateProfil(
                userId, {"email":emailKontroller.text }
            );
            Navigator.pop(context);
      });
    }

    return Scaffold(
      appBar: customAppBar(title: "Email ändern",button: saveButton()),
      body: Column(
        children: [
          customTextInput("neue Email",emailKontroller),
          const SizedBox(height: 15),
          customTextInput("Passwort bestätigen",passwortKontroller, passwort: true)
        ],
      )
    );
  }
}
