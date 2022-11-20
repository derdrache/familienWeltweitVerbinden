import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';


class ForceUpdatePage extends StatelessWidget {
  bool spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  ForceUpdatePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(20),
          child: Center(
              child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  spracheIstDeutsch
                      ? "Families worldwide hat ein großes Update bekommen"
                      : "Families worldwide has received a major update",
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),
                Text(
                  spracheIstDeutsch
                      ? "Bitte im Playstore die neuste Version runterladen. "
                      : "Please download the latest version from the Playstore. ",
                  style: const TextStyle(fontSize: 16),
                ),
              ])),
        ),
      ),
    );
  }
}