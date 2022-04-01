import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import 'create_profil_page.dart';
import '../start_page.dart';
import '../login_register_page/register_page.dart';
import '../login_register_page/forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);

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
  bool angemeldetBleiben = true;

  loading(){
    return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator())
    );
  }

  userLogin() async{
    if(kIsWeb && angemeldetBleiben) {
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

    try{
      email = email.replaceAll(' ', '');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: passwort);

      bool emailVerified = FirebaseAuth.instance.currentUser?.emailVerified?? false;

      if(emailVerified){
        var userId = FirebaseAuth.instance.currentUser.uid;
        var profilName = await ProfilDatabase().getOneData("name", "id", userId);

        if(profilName != false){
          global_functions.changePageForever(context, StartPage());
        } else{
          global_functions.changePageForever(context, CreateProfilPage());
        }


      } else{
        setState(() {
          isLoading = false;
        });
        customSnackbar(context, AppLocalizations.of(context).emailNichtBestaetigt);
      }

    }on FirebaseAuthException catch(error){
      setState(() {
        isLoading = false;
      });
      if(error.code == "user-not-found"){
        customSnackbar(context, AppLocalizations.of(context).benutzerNichtGefunden);
      } else if(error.code == "wrong-password"){
        customSnackbar(context, AppLocalizations.of(context).passwortFalsch);
      } else if(error.code == "network-request-failed"){
        customSnackbar(context, AppLocalizations.of(context).keineVerbindungInternet);
      }
    }
  }

  signInWithGoogleWeb() async {
    await Firebase.initializeApp();
    User user;

    FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    GoogleAuthProvider authProvider = GoogleAuthProvider();

    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithPopup(authProvider);

      user = userCredential.user;
    } catch (e) {
      print(e);
    }

    return user;
  }

  signInWithGoogleAndroid() async {
    // Trigger the authentication flow
    GoogleSignInAccount googleUser = await GoogleSignIn().signIn();


    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);


  }

  @override
  Widget build(BuildContext context) {
    double sideSpace = 20;
    var screensize = MediaQuery. of(context).size;

    Widget header(){
      return Container(
        margin: EdgeInsets.only(top: sideSpace, bottom: sideSpace, left: sideSpace*2, right:sideSpace*2),
        child: Column(
          children: [
            Center(
                child: Image.asset('assets/WeltFlugzeug.png')
            ),
            SizedBox(height: 15),
            Text(AppLocalizations.of(context).willkommenBeiAppName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text(AppLocalizations.of(context).slogn1 + "\n" + AppLocalizations.of(context).slogn2),
          ],
        )

      );
    }

    angemeldetBleibenBox(){
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Switch(value: angemeldetBleiben, onChanged: (value){
            setState(() {
              angemeldetBleiben = value;
            });
          }),
          SizedBox(width: 10),
          Text("Angemeldet bleiben?")
        ],
      );
    }

    Widget forgetPassButton(){
      return Align(
        child: SizedBox(
          width: 200,
          child: TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(Colors.black)
              ),
              child: Text(AppLocalizations.of(context).passwortVergessen),
              onPressed: (){
                passwortController.text = "";
                global_functions.changePage(context, const ForgetPasswordPage());
              }
          ),
        ),
      );
    }

    doLogin(){
      if(_formKey.currentState.validate()){
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
                customTextInput(AppLocalizations.of(context).passwort, passwortController,
                    validator: global_functions.checkValidatorPassword(context),
                    passwort: true,
                    textInputAction: TextInputAction.done,
                    onSubmit: () => doLogin()),
                if(kIsWeb) angemeldetBleibenBox(),
                forgetPassButton(),
                isLoading ? loading() : customFloatbuttonExtended("Login", () => doLogin()),
                customFloatbuttonExtended(AppLocalizations.of(context).registrieren, (){
                  global_functions.changePage(context, const RegisterPage());
                }),
                /*
                TextButton(
                  child: Text("Google Log In"),
                  onPressed: ()async {
                    if (kIsWeb){
                      await signInWithGoogleWeb();
                    } else{
                      await signInWithGoogleAndroid();
                    }
                    var userId = FirebaseAuth.instance.currentUser.uid;

                    if(userId == null) return;
                    var userExist = await ProfilDatabase().getOneData("name", "id", userId);
                    print(userExist == false);
                    if(userExist == false){
                      global_functions.changePageForever(context, CreateProfilPage());
                    } else{
                      global_functions.changePageForever(context, StartPage());
                    }
                  },
                )
                 */
              ],
            )
        )
    );
  }
}
