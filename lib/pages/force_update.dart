import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';


class ForceUpdatePage extends StatelessWidget {
  final bool spracheIstDeutsch = kIsWeb
      ? PlatformDispatcher.instance.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  ForceUpdatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(20),
          padding: EdgeInsets.all(10),
          child: Center(
              child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(height: 150, width: 150, child: Image.asset('assets/launch_image.png')),
                const SizedBox(height: 100),
                Text(
                  spracheIstDeutsch
                      ? "Bitte aktualisiere\nfamilies worldwide"
                      : "Please Update\n families worldwide",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 35),
                ),
                const SizedBox(height: 40),
                Text(
                  spracheIstDeutsch
                      ? "Diese Version der App wird nicht mehr unterstützt. Installieren Sie die neueste Version, um wieder auf alle Ihre Unterhaltungen zugreifen zu können."
                      : "This version of the app is no longer supported. To get back to all your conversations, install latest version.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 25),
                ),
              ])),
        ),
      ),
    );
  }
}