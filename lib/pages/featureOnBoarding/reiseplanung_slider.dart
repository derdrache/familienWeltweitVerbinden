import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/settings/privacy_security_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';


import '../settings/change_reiseplanung.dart';

class ReiseplanungSlider extends StatelessWidget {
  const ReiseplanungSlider({super.key});

  @override
  Widget build(BuildContext context) {
    Map userProfil = Hive.box("secureBox").get("ownProfil");
    final bool spracheIstDeutsch = kIsWeb
        ? PlatformDispatcher.instance.locale.languageCode == "de"
        : Platform.localeName == "de_DE";

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Image.asset("assets/icons/travel_plan_icon.png",
              width: 150, height: 150),),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.reisePlanung,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.reiseplanungBeschreibung,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          FloatingActionButton.extended(
            onPressed: () => changePage(context, ChangeReiseplanungPage(reiseplanung: userProfil["reisePlanung"], isGerman: spracheIstDeutsch,)),
            label: Text(AppLocalizations.of(context)!.planungAnlegen, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }
}

