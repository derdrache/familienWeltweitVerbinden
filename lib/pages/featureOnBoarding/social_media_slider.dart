import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/settings/privacy_security_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../settings/change_social_media.dart';

class SocialMediaSlider extends StatelessWidget {
  const SocialMediaSlider({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Image.asset("assets/icons/page_link_icon.png",
              width: 150, height: 150),),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.socialMedia,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.socialMediaBeschreibung,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 100),
          FloatingActionButton.extended(
            onPressed: () => changePage(context, const ChangeSocialMediaLinks()),
            label: Text(AppLocalizations.of(context)!.addLink, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }
}

