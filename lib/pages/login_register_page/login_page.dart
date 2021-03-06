import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../services/notification.dart';
import 'create_profil_page.dart';
import '../start_page.dart';
import '../login_register_page/register_page.dart';
import '../login_register_page/forget_password_page.dart';
import '../../services/database.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwortController = TextEditingController();
  String email = "";
  String passwort = "";
  bool isLoading = false;
  bool angemeldetBleiben = true;

  loadingBox() {
    return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator()));
  }

  userLogin() async {
    if (!_formKey.currentState.validate()) return;

    setState(() {
      isLoading = true;
      email = emailController.text;
      passwort = passwortController.text;
    });

    if (kIsWeb && angemeldetBleiben) {
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

    try {
      email = email.replaceAll(' ', '');
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: passwort);

      bool emailVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;

      if (emailVerified) {
        var userId = FirebaseAuth.instance.currentUser.uid;
        var ownProfil =
            await ProfilDatabase().getData("*", "WHERE id = '$userId'");
        Hive.box('secureBox').put("ownProfil", ownProfil);

        if (ownProfil != false) {
          global_functions.changePageForever(context, StartPage());
        } else {
          global_functions.changePageForever(context, const CreateProfilPage());
        }
      } else {
        setState(() {
          isLoading = false;
        });
        customSnackbar(
            context, AppLocalizations.of(context).emailNichtBestaetigt);
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        isLoading = false;
      });
      if (error.code == "user-not-found") {
        customSnackbar(
            context, AppLocalizations.of(context).benutzerNichtGefunden);
      } else if (error.code == "wrong-password") {
        customSnackbar(context, AppLocalizations.of(context).passwortFalsch);
      } else if (error.code == "network-request-failed") {
        customSnackbar(
            context, AppLocalizations.of(context).keineVerbindungInternet);
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
    } catch (_) {}

    return user;
  }

  signInWithGoogleAndroid() async {
    GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    double sideSpace = 20;

    Widget header() {
      return Container(
          margin: EdgeInsets.only(
              top: sideSpace,
              bottom: sideSpace,
              left: sideSpace * 2,
              right: sideSpace * 2),
          child: Column(
            children: [
              Center(child: Image.asset('assets/WeltFlugzeug.png')),
              const SizedBox(height: 15),
              Text(AppLocalizations.of(context).willkommenBeiAppName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).slogn1 +
                    "\n" +
                    AppLocalizations.of(context).slogn2,
                textAlign: TextAlign.center,
              ),
            ],
          ));
    }

    angemeldetBleibenBox() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Switch(
              value: angemeldetBleiben,
              onChanged: (value) {
                setState(() {
                  angemeldetBleiben = value;
                });
              }),
          const SizedBox(width: 10),
          Text(AppLocalizations.of(context).angemeldetBleiben)
        ],
      );
    }

    Widget resendVerificationEmailButton() {
      return TextButton(
          style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all(Colors.black)),
          child: Text(
              AppLocalizations.of(context).verifizierungsEmailNochmalSenden),
          onPressed: () async {
            if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
              return;
            }
            try {
              await FirebaseAuth.instance.currentUser?.sendEmailVerification();
              customSnackbar(
                  context, AppLocalizations.of(context).emailErneutVersendet);
            } catch (error) {
              sendEmail({
                "title": "Firebase auth Problem",
                "inhalt": """
                  Email: ${FirebaseAuth.instance.currentUser?.email} hat Probleme mit dem Login
                  Folgendes Problem ist aufgetaucht: $error"""
              });
            }
          });
    }

    Widget forgetPassButton() {
      return TextButton(
          style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all(Colors.black)),
          child: Text(AppLocalizations.of(context).passwortVergessen),
          onPressed: () {
            passwortController.text = "";
            global_functions.changePage(context, const ForgetPasswordPage());
          });
    }

    Widget googleLoginButton() {
      return Align(
        child: InkWell(
          onTap: () async {
            if (kIsWeb) {
              await signInWithGoogleWeb();
            } else {
              await signInWithGoogleAndroid();
            }
            var userId = FirebaseAuth.instance.currentUser.uid;

            if (userId == null) return;
            var userExist =
                await ProfilDatabase().getData("name", "WHERE id = '$userId'");

            if (userExist == false) {
              global_functions.changePageForever(
                  context, const CreateProfilPage());
            } else {
              global_functions.changePageForever(context, StartPage());
            }
          },
          child: Container(
              height: 50,
              width: 280,
              margin: const EdgeInsets.only(
                  top: 10, bottom: 10, right: 55, left: 55),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.all(Radius.circular(30))),
              child: Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 30.0,
                    width: 30.0,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/googleGIcon.jpg'),
                          fit: BoxFit.cover),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).loginMitGoogle,
                    style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  )
                ],
              ))),
        ),
      );
    }

    return Scaffold(
        body: Form(
            key: _formKey,
            child: ListView(
              children: [
                header(),
                customTextInput("Email", emailController,
                    validator: global_functions.checkValidationEmail(context),
                    textInputAction: TextInputAction.next),
                customTextInput(
                    AppLocalizations.of(context).passwort, passwortController,
                    validator: global_functions.checkValidatorPassword(context),
                    passwort: true,
                    textInputAction: TextInputAction.done,
                    onSubmit: () => userLogin()),
                if (kIsWeb) angemeldetBleibenBox(),
                forgetPassButton(),
                resendVerificationEmailButton(),
                isLoading
                    ? loadingBox()
                    : customFloatbuttonExtended("Login", () => userLogin()),
                customFloatbuttonExtended(
                    AppLocalizations.of(context).registrieren, () {
                  global_functions.changePage(context, const RegisterPage());
                }),
                googleLoginButton(),
              ],
            )));
  }
}
