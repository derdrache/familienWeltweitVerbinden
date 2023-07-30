import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';


class ForceUpdatePage extends StatelessWidget {
  final bool spracheIstDeutsch = kIsWeb
      ? PlatformDispatcher.instance.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  const ForceUpdatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(20),
          child: Center(
              child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset('assets/WeltFlugzeug.png'),
                const SizedBox(height: 50),
                Text(
                  spracheIstDeutsch
                      ? "Families worldwide hat wichtige Updates bekommen"
                      : "Families worldwide received important updates",
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),
                Text(
                  spracheIstDeutsch
                      ? "Damit die alten Fehler für alle sichtbar behoben sind, ist es nötig, die App auf den neusten Stand zu bringen\n\nBitte lade dir dafür die neuste Version im App Store runter."
                      : "In order to fix the old bugs for everyone to see, it is necessary to update the app to the latest version\n\nPlease download the latest version from the App Store for this.",
                  style: const TextStyle(fontSize: 16),
                ),
              ])),
        ),
      ),
    );
  }
}