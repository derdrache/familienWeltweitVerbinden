import 'dart:io' show Platform;

import 'package:familien_suche/pages/login_register_page/on_boarding_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:stacked_firebase_auth/stacked_firebase_auth.dart';

import '../../auth/secrets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../widgets/dialogWindow.dart';
import '../../widgets/layout/custom_floating_action_button_extended.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';
import '../start_page.dart';
import '../login_register_page/forget_password_page.dart';
import '../../services/database.dart';
import 'impressum.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwortController = TextEditingController();
  String email = "";
  String passwort = "";
  bool isLoading = false;
  bool googleLoginLoading = false;
  bool appleLoginLoading = false;
  bool angemeldetBleiben = true;
  var versionNumber = Hive.box('secureBox').get("version");

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
    if (!_formKey.currentState!.validate()) return;

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
        if (context.mounted) {
          global_functions.changePageForever(context, StartPage());
        }
      } else {
        if (context.mounted) {
          global_functions.changePageForever(context, const OnBoardingSlider());
        }
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        isLoading = false;
      });
      if (error.code == "user-not-found") {
        customSnackbar(
            context, AppLocalizations.of(context)!.benutzerNichtGefunden);
      } else if (error.code == "wrong-password") {
        customSnackbar(context, AppLocalizations.of(context)!.passwortFalsch);
      } else if (error.code == "network-request-failed") {
        customSnackbar(
            context, AppLocalizations.of(context)!.keineVerbindungInternet);
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

      User? user = userCredential.user;
      return user;
    } catch (_) {
      setState(() {
        googleLoginLoading = false;
      });
    }
  }

  signInWithGoogleAndroid() async {
    try {
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (_) {}
  }

  signInWithApple() async {
    var firebaseAuthService = FirebaseAuthenticationService();
    final result = await firebaseAuthService.signInWithApple(
        appleRedirectUri:
            "https://praxis-cab-236720.firebaseapp.com/__/auth/handler",
        appleClientId: 'com.example.familienSuche');
  }

  bool isPhone() {
    final data = MediaQueryData.fromView(View.of(context));
    return data.size.shortestSide < 600 ? true : false;
  }

  _refreshHiveData() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == appStoreViewAccount) databaseUrl = testWebseite;

    await refreshHiveProfils();

    var ownProfil = Hive.box("secureBox").get("ownProfil");
    if (ownProfil == false || ownProfil.isEmpty) return;

    refreshHiveNewsSetting();
    await refreshHiveChats();
    await refreshHiveMeetups();

    if (userId == "BUw5puWtumVtAa8mpnDmhBvwdJo1") {
      await refreshHiveCommunities();
      await refreshHiveNewsPage();
      await refreshHiveStadtInfo();
      await refreshHiveStadtInfoUser();
      await refreshHiveFamilyProfils();
    }
  }

  _sendeHilfe(reportController) {
    var checkText = reportController.text.replaceAll(" ", "");
    if (checkText.isEmpty) return;

    ChatDatabase().addAdminMessage(reportController.text, "Login/Hilfe");

    customSnackbar(context, AppLocalizations.of(context)!.hilfeVersendetText,
        color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
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
          Text(AppLocalizations.of(context)!.angemeldetBleiben)
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
          child: Text(
            AppLocalizations.of(context)!.passwortVergessen,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
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
          child: Text(
            AppLocalizations.of(context)!.hilfe,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          onPressed: () {
            var reportController = TextEditingController();

            showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CustomAlertDialog(
                      height: 390,
                      title: AppLocalizations.of(context)!.hilfe,
                      children: [
                        TextField(
                          controller: reportController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            hintText:
                                AppLocalizations.of(context)!.hilfeVorschlag,
                            hintMaxLines: 10,
                          ),
                          maxLines: 10,
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 30, top: 10, right: 30),
                          child: FloatingActionButton.extended(
                              onPressed: () {
                                Navigator.pop(context);
                                _sendeHilfe(reportController);
                              },
                              label:
                                  Text(AppLocalizations.of(context)!.senden)),
                        )
                      ]);
                });
          });
    }

    Widget loginButton() {
      return isLoading
          ? loadingBox()
          : kIsWeb && !isPhone()
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    customFloatbuttonExtended("Login", () => userLogin()),
                    customFloatbuttonExtended(
                        AppLocalizations.of(context)!.registrieren, () {
                      global_functions.changePage(
                          context, const OnBoardingSlider());
                    })
                  ],
                )
              : customFloatbuttonExtended("Login", () => userLogin());
    }

    Widget supportRow() {
      return Container(
        width: 600,
        margin: const EdgeInsets.only(left: 20, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            hilfeButton(),
            const Expanded(child: SizedBox(width: 50)),
            forgetPassButton(),
          ],
        ),
      );
    }

    Widget googleLoginButton() {
      return InkWell(
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
          if (userId == null) {
            setState(() {
              googleLoginLoading = false;
            });
            return;
          }

          await _refreshHiveData();
          var ownProfil = Hive.box("secureBox").get("ownProfil");

          if (ownProfil != false && ownProfil.isNotEmpty) {
            if (context.mounted) {
              global_functions.changePageForever(context, StartPage());
            }
          } else {
            if (context.mounted) {
              global_functions.changePageForever(
                  context, const OnBoardingSlider());
            }
          }
        },
        child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: const BorderRadius.all(Radius.circular(12))),
            child: !googleLoginLoading
                ? Container(
                    height: 50.0,
                    width: 50.0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      image: DecorationImage(
                          image: AssetImage('assets/googleGIcon.png'),
                          fit: BoxFit.cover),
                      shape: BoxShape.circle,
                    ),
                  )
                : const Center(child: CircularProgressIndicator())),
      );
    }

    Widget appleLoginButton() {
      return InkWell(
        onTap: () async {
          setState(() {
            appleLoginLoading = true;
          });

          await signInWithApple();

          var userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId == null) {
            setState(() {
              appleLoginLoading = false;
            });
            return;
          }

          await _refreshHiveData();
          var ownProfil = Hive.box("secureBox").get("ownProfil");

          if (ownProfil != false && ownProfil.isNotEmpty) {
            if (context.mounted) {
              global_functions.changePageForever(context, StartPage());
            }
          } else {
            if (context.mounted) {
              global_functions.changePageForever(
                  context, const OnBoardingSlider());
            }
          }
        },
        child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: const BorderRadius.all(Radius.circular(12))),
            child: !appleLoginLoading
                ? Container(
                    height: 50.0,
                    width: 50.0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      image: DecorationImage(
                          image: AssetImage('assets/appleIcon.png'),
                          fit: BoxFit.cover),
                      shape: BoxShape.circle,
                    ),
                  )
                : const Center(child: CircularProgressIndicator())),
      );
    }

    Widget socialLoginButtons() {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (!Platform.isIOS) googleLoginButton(),
        const SizedBox(width: 10),
        if (Platform.isIOS) appleLoginButton(),
      ]);
    }

    Widget noAccountBox() {
      return InkWell(
        onTap: () => global_functions.changePage(context, const OnBoardingSlider()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.keinAccount),
            Text(
              AppLocalizations.of(context)!.registrieren,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            )
          ],
        ),
      );
    }

    Widget impressumBox() {
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
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(
                  height: 50,
                ),
                Image.asset('assets/WeltFlugzeug.png'),
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.willkommenBeiAppName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 20,
                ),
                CustomTextInput("Email", emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: global_functions.checkValidationEmail(context),
                    margin:
                        const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
                    textInputAction: TextInputAction.next),
                CustomTextInput(
                    AppLocalizations.of(context)!.passwort, passwortController,
                    validator: global_functions.checkValidatorPassword(context),
                    margin:
                        const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
                    hideInput: true,
                    textInputAction: TextInputAction.done,
                    onSubmit: () => userLogin()),
                if (kIsWeb) angemeldetBleibenBox(),
                supportRow(),
                const SizedBox(
                  height: 10,
                ),
                loginButton(),
                const SizedBox(
                  height: 30,
                ),
                Text(AppLocalizations.of(context)!.oderWeiterMit),
                const SizedBox(
                  height: 20,
                ),
                socialLoginButtons(),
                const Expanded(
                  child: SizedBox.shrink(),
                ),
                noAccountBox(),
                const SizedBox(height: 20),
                if (kIsWeb) impressumBox()
              ],
            ),
          ),
        ));
  }
}
