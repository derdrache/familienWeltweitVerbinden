import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/global_functions.dart' as global_functions;
import '../../widgets/layout/custom_floating_action_button_extended.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';
import '../../widgets/nutzerrichtlinen.dart';
import 'create_profil_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final checkEmailController = TextEditingController();
  final passwordController = TextEditingController();
  final checkPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  registrationButton() async {
    setState(() {
      isLoading = true;
    });
    var registrationComplete = await registration();
    if (registrationComplete) {
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

      if (context.mounted) {
        global_functions.changePageForever(context, const CreateProfilPage());
      }
    }
  }

  registration() async {
    var success = false;

    if (formKey.currentState!.validate()) {
      var email = emailController.text;
      email = email.replaceAll(" ", "");
      var password = passwordController.text;

      try {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        success = true;
      } on FirebaseAuthException catch (error) {

        if(!context.mounted) return;

        if (error.code == "email-already-in-use") {
          customSnackBar(
              context, AppLocalizations.of(context)!.emailInBenutzung);
        } else if (error.code == "invalid-email") {
          customSnackBar(context, AppLocalizations.of(context)!.emailUngueltig);
        } else if (error.code == "weak-password") {
          customSnackBar(
              context, AppLocalizations.of(context)!.passwortSchwach);
        } else if (error.code == "network-request-failed") {
          customSnackBar(
              context, AppLocalizations.of(context)!.keineVerbindungInternet);
        }
      }
    }

    setState(() {
      isLoading = false;
    });

    return success;
  }

  loadingBox() {
    return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Align(
            child: Column(
              children: [
                const SizedBox(
                  height: 50,
                ),
                Image.asset('assets/WeltFlugzeug.png'),
                const Text("Account erstellen",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 20,
                ),
                CustomTextInput(
                  "Email",
                  emailController,
                  margin:
                      const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
                  validator: global_functions.checkValidationEmail(context),
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                ),
                CustomTextInput(AppLocalizations.of(context)!.emailBestaetigen,
                    checkEmailController,
                    margin: const EdgeInsets.only(
                        left: 20, right: 20, top: 5, bottom: 10),
                    validator: global_functions.checkValidationEmail(context,
                        emailCheck: emailController.text),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress),
                CustomTextInput(
                    AppLocalizations.of(context)!.passwort, passwordController,
                    margin: const EdgeInsets.only(
                        left: 20, right: 20, top: 10, bottom: 5),
                    hideInput: true,
                    validator: global_functions.checkValidatorPassword(context),
                    textInputAction: TextInputAction.next),
                CustomTextInput(
                    AppLocalizations.of(context)!.passwortBestaetigen,
                    checkPasswordController,
                    margin:
                        const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
                    hideInput: true,
                    validator: global_functions.checkValidatorPassword(context,
                        passwordCheck: passwordController.text),
                    textInputAction: TextInputAction.done,
                    onSubmit: () => registrationButton()),
                const SizedBox(height: 10),
                isLoading
                    ? loadingBox()
                    : customFloatbuttonExtended(
                        AppLocalizations.of(context)!.registrieren,
                        () => registrationButton()),
                NutzerrichtlinenAnzeigen(page: "register"),
                const Expanded(child: SizedBox.shrink()),
                InkWell(
                  onTap: () =>
                      global_functions.changePageForever(context, const LoginPage()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.bereitsMitglied),
                      Text(
                        AppLocalizations.of(context)!.anmelden,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ));
  }
}
