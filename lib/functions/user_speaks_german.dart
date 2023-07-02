import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

bool getUserSpeaksGerman(){
  var ownProfil = Hive.box("secureBox").get("ownProfil");
  String systemLanguage =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode;
  bool userSpeakGerman = ownProfil["sprachen"].contains("Deutsch") ||
      ownProfil["sprachen"].contains("german") ||
      systemLanguage == "de";

  return userSpeakGerman;

}