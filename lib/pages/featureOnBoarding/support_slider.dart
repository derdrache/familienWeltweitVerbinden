import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../windows/donations.dart';

class SupportSlider extends StatelessWidget {
  const SupportSlider({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Image.asset("assets/icons/heart_icon.png",
              width: 150, height: 150),),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.support,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.supportBeschreibung,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 50),
          FloatingActionButton.extended(
            onPressed: () => donationWindow(context),
            label: Text(AppLocalizations.of(context)!.spenden, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }
}

