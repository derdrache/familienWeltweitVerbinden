import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/global_functions.dart';

aboutAppWindow(context) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  github() {
    return InkWell(
      onTap: () =>
          openURL("https://github.com/derdrache/familienWeltweitVerbinden"),
      child: const Row(
        children: [
          Text("Open Source: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            "Github Repo",
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.blue,
            ),
          )
        ],
      ),
    );
  }

  iconsInformation() {
    icconInfoRow(icon, creator, link) {
      return Container(
        margin: EdgeInsets.only(left: 15, bottom: 15),
        child: Row(
          children: [
            Image.asset(
              icon,
              width: 24,
              height: 24,
            ),
            SizedBox(
              width: 10,
            ),
            InkWell(
              onTap: () => openURL(link),
                child: Text("createt by $creator")
            )
          ],
        ),
      );
    }

    return ExpansionTile(
      title: Text("Icon creators"),
      children: [
        icconInfoRow("assets/icons/meetup.png", "Freepik", "https://www.flaticon.com/authors/freepik"),
        icconInfoRow("assets/icons/community.png", "Freepik", "https://www.flaticon.com/authors/freepik"),
        icconInfoRow("assets/icons/village.png", "Freepik", "https://www.flaticon.com/authors/freepik"),
        icconInfoRow("assets/icons/country_flags.png", "Freepik", "https://www.flaticon.com/authors/freepik"),
        icconInfoRow("assets/icons/schedule.png", "Freepik", "https://www.flaticon.com/authors/freepik"),
        icconInfoRow("assets/icons/information.png", "Freepik", "https://www.flaticon.com/authors/freepik"),
        icconInfoRow("assets/icons/cloack_forward.png", "Freepik", "https://www.flaticon.com/authors/freepik"),
        icconInfoRow("assets/icons/filter.png", "Freepik", "https://www.flaticon.com/authors/freepik"),
        icconInfoRow("assets/icons/telegram.png", "Icons8", "https://icons8.com/"),
      ],
    );

  }

  return showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return AboutDialog(
          applicationName: "families worldwide",
          applicationVersion: packageInfo.version,
          applicationIcon: Image.asset('assets/WeltFlugzeug.png'),
          children: [
            github(),
            const SizedBox(height: 10),
            const Row(
              children: [
                Text("Framework:  ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Flutter"),
              ],
            ),
            const SizedBox(height: 10),
            iconsInformation(),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.aboutAppText)
          ],
        );
      });
}
