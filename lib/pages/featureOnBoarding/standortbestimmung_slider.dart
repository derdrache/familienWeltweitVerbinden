import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/settings/privacy_security_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class StandortbestimmungSlider extends StatelessWidget {
  const StandortbestimmungSlider({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Image.asset("assets/icons/map_icon.png",
              width: 150, height: 150),),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.automatischeStandortbestimmung,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.standortBestimmungBeschreibung,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 100),
          FloatingActionButton.extended(
            onPressed: () => changePage(context, const PrivacySecurityPage()),
            label: Text(AppLocalizations.of(context)!.standortBestimmungsButtonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }
}

