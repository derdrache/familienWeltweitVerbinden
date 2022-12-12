import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../widgets/dialogWindow.dart';
import 'create_profil_page.dart';
import '../start_page.dart';
import '../login_register_page/register_page.dart';
import '../login_register_page/forget_password_page.dart';
import '../../services/database.dart';
import 'impressum.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

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
  bool googleLoginLoading = false;
  bool angemeldetBleiben = true;

  @override
  void initState() {
    super.initState();
  }


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

    try {
      email = email.replaceAll(' ', '');
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: passwort);

      if (kIsWeb && angemeldetBleiben) {
        FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }

      await _refreshHiveData();

      var ownProfil = Hive.box("secureBox").get("ownProfil");

      if (ownProfil != false && ownProfil.isNotEmpty) {
          global_functions.changePageForever(context, StartPage());
        } else {
          global_functions.changePageForever(context, const CreateProfilPage());
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


    try {
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(authProvider);

      User user = userCredential.user;
      return user;
    } catch (_) {
      setState(() {
        googleLoginLoading = false;
      });
    }


  }

  signInWithGoogleAndroid() async {
    try{
      GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    }catch(_){

    }
  }

  bool isPhone() {
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    return data.size.shortestSide < 600 ? true : false;
  }

  _refreshHiveData() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    if(userId == "BUw5puWtumVtAa8mpnDmhBvwdJo1"){
      databaseUrl = "http://test.families-worldwide.com/";
    }
    await refreshHiveProfils();

    var ownProfil = Hive.box("secureBox").get("ownProfil");
    if(ownProfil == false || ownProfil.isEmpty) return;

    refreshHiveNewsSetting();
    await refreshHiveChats();
    await refreshHiveEvents();

    if(userId == "BUw5puWtumVtAa8mpnDmhBvwdJo1"){
      await refreshHiveCommunities();
      await refreshHiveNewsPage();
      await refreshHiveStadtInfo();
      await refreshHiveStadtInfoUser();
      await refreshHiveFamilyProfils();
    }
  }

  _sendeHilfe(reportController){
    if(reportController.text.isEmpty) return;

    ChatDatabase().addAdminMessage(
        reportController.text, "Login/Hilfe");

    customSnackbar(context, AppLocalizations.of(context).hilfeVersendetText,
        color: Colors.green);
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
          child: kIsWeb && !isPhone()
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: Image.asset('assets/WeltFlugzeug.png')),
                    const SizedBox(width: 15),
                    Column(
                      children: [
                        Center(
                          child: Text(AppLocalizations.of(context).willkommenBeiAppName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context).slogn1 +
                              "\n" +
                              AppLocalizations.of(context).slogn2,
                          textAlign: TextAlign.center,
                        )
                      ],
                    )
                  ],
                )
              : Column(
                  children: [
                    Center(child: Image.asset('assets/WeltFlugzeug.png')),
                    const SizedBox(height: 15),
                    Text(AppLocalizations.of(context).willkommenBeiAppName,
                        textAlign: TextAlign.center,
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

    Widget forgetPassButton() {
      return TextButton(
          style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.black),
          child: Text(AppLocalizations.of(context).passwortVergessen),
          onPressed: () {
            passwortController.text = "";
            global_functions.changePage(context, const ForgetPasswordPage());
          });
    }

    Widget hilfeButton() {
      return TextButton(
          style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.black),
          child: Text(AppLocalizations.of(context).hilfe, style: const TextStyle(color: Colors.blue),),
          onPressed: () {
            var reportController = TextEditingController();

            showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CustomAlertDialog(
                      height: 390,
                      title: AppLocalizations.of(context).hilfe,
                      children: [
                        TextField(
                          controller: reportController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            hintText: AppLocalizations.of(context).hilfeVorschlag,
                            hintMaxLines: 10,
                          ),
                          maxLines: 10,
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
                          child: FloatingActionButton.extended(
                              onPressed: () {
                                Navigator.pop(context);
                                _sendeHilfe(reportController);
                              },
                              label: Text(AppLocalizations.of(context).senden)),
                        )
                      ]);
                });
          });
    }

    Widget googleLoginButton() {
      return Align(
        child: InkWell(
          onTap: () async {
            setState(() {
              googleLoginLoading = true;
            });

            if (kIsWeb) {
              await signInWithGoogleWeb();
            } else {
              await signInWithGoogleAndroid();
            }
            var userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null){
              setState(() {
                googleLoginLoading = false;
              });
              return;
            }

            await _refreshHiveData();
            var ownProfil = Hive.box("secureBox").get("ownProfil");

            if (ownProfil != false && ownProfil.isNotEmpty) {
              global_functions.changePageForever(context, StartPage());
            } else {
              global_functions.changePageForever(
                  context, const CreateProfilPage());
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
                  child: !googleLoginLoading ? Row(
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
              ): const CircularProgressIndicator()
              )),

        ),
      );
    }

    Widget footer() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: () =>
                    global_functions.changePage(context, const ImpressumPage()),
                child: const Text("Impressum"))
          ],
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
                    keyboardType: TextInputType.emailAddress,
                    validator: global_functions.checkValidationEmail(context),
                    textInputAction: TextInputAction.next),
                customTextInput(
                    AppLocalizations.of(context).passwort, passwortController,
                    validator: global_functions.checkValidatorPassword(context),
                    passwort: true,
                    textInputAction: TextInputAction.done,
                    onSubmit: () => userLogin()),
                if (kIsWeb) angemeldetBleibenBox(),
                const SizedBox(height: 15),
                forgetPassButton(),
                const SizedBox(height: 15),
                isLoading
                    ? loadingBox()
                    : kIsWeb && !isPhone()
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              customFloatbuttonExtended(
                                  "Login", () => userLogin()),
                              customFloatbuttonExtended(
                                  AppLocalizations.of(context).registrieren,
                                  () {
                                global_functions.changePage(
                                    context, const RegisterPage());
                              })
                            ],
                          )
                        : customFloatbuttonExtended("Login", () => userLogin()),
                customFloatbuttonExtended(
                    AppLocalizations.of(context).registrieren, () {
                  global_functions.changePage(context, const RegisterPage());
                }),
                googleLoginButton(),
                const SizedBox(height: 15),
                hilfeButton(),
                const SizedBox(height: 15),
                if (kIsWeb) footer(),

              ],
            )));
  }
}
