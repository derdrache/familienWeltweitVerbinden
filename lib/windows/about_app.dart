import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/global_functions.dart';

aboutAppWindow(context) async{
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return AboutDialog(
            applicationName: "families worldwide",
            applicationVersion: packageInfo.version,
            applicationIcon: Image.asset('assets/WeltFlugzeug.png'),
            children: [
              InkWell(
                onTap: () => openURL(
                    "https://github.com/derdrache/familienWeltweitVerbinden"),
                child: const Row(
                  children: [
                    Text("Open Source: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "Github Repo",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Text("Framework:  ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Flutter"),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Text("Icons: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("created by Freepik - Flaticon"),
                ],
              ),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.aboutAppText)
            ],
          );
        });
}