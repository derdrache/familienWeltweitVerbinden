import 'dart:io';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/dialogWindow.dart';

class NutzerrichtlinenAnzeigen extends StatelessWidget {
  String page;
  var isGerman = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  NutzerrichtlinenAnzeigen({Key key, this.page}) : super(key: key);

  getPageClickOn(){
    if(page == "register"){
      return isGerman
          ? "Registrieren "
          : "Sign up ";
    }else if(page == "login"){
      return "Login ";
    }else if(page == "create"){
      return isGerman
          ? "Erstellen oder Speichern "
          : "Create or Save ";
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = 12;
    var startText = isGerman
        ? "Indem Sie auf " +getPageClickOn() + "klicken, erklären Sie sich mit den "
        : "By clicking " +getPageClickOn() + "you agree to the ";

    var getNotifications = isGerman
        ? " und stimmen zu, unsere Benachrichtigungen / E-Mails zu erhalten, die Sie jederzeit selbst abschalten können"
        : " and agree to receive our notifications / emails, which you can turn off yourself at any time";

    var satzverbindung = isGerman ? " und der " : " and ";



    termsOfUseWindow(){
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                title: AppLocalizations.of(context).nutzungsbedingungen,
                children: [

                ]);
          });
    }

    termsOfUse() {
      return TextSpan(
          text: AppLocalizations.of(context).nutzungsbedingungen,
          recognizer: TapGestureRecognizer()..onTap = () => termsOfUseWindow(),
          style: TextStyle(fontSize: fontSize, color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline));
    }

    privacyPolicyWindow(){
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                title: AppLocalizations.of(context).datenschutzrichtlinie,
                children: [

                ]);
          });
    }

    privacyPolicy() {
      return TextSpan(
          text: AppLocalizations.of(context).datenschutzrichtlinie,
          recognizer: TapGestureRecognizer()..onTap = () => privacyPolicyWindow(),
          style: TextStyle(fontSize: fontSize, color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline));
    }

    return Container(
        margin: const EdgeInsets.all(15),
        child: RichText(
            text: TextSpan(children: [
          TextSpan(
              text: startText,
              style: TextStyle(fontSize: fontSize, color: Colors.black)),
          termsOfUse(),
          if(page == "register") TextSpan(
              text: getNotifications,
              style: TextStyle(fontSize: fontSize, color: Colors.black))
        ])));
  }
}
