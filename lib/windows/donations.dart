import 'package:familien_suche/windows/dialog_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../functions/user_speaks_german.dart';

donationWindow(BuildContext context, {infoTextGer = "", infoTextEng = ""}) {
  String infoText = infoTextEng;
  bool systemIsGerman =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode == "de";
  bool userSpeakGerman = getUserSpeaksGerman();

  if(systemIsGerman || userSpeakGerman) infoText = infoTextGer;

  openKoFi() async {
    Uri url = Uri.parse("https://ko-fi.com/devdrache");

    await launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  openPaypal() async {
    Uri url = Uri.parse("https://www.paypal.com/paypalme/DominikMast");

    await launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  copyText(string) async{
    await Clipboard.setData(ClipboardData(text: string));
  }

  openBitcoin(){
    String walletKey = "bc1qds8msk2mll5qzdfqgx5apw0857h3pr5qh9yptx";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog( children: [
          Image.asset("assets/bilder/walletMatrixcode.png"),
          const SizedBox(height: 10,),
          Column(
            children: [
              const Text("Wallet:"),
              Text(walletKey)
            ],
          ),
          const SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: FloatingActionButton.extended(onPressed: () => copyText(walletKey), label: const Text("Copy"),),
          )
        ]);
      }
    );
  }

  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          childrenMargin: const EdgeInsets.only(left: 40, right: 40, top: 20, bottom: 20),
            children: [
              Center(child: Text(AppLocalizations.of(context)!.supportFamiliesWorldwide, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),)),
              const SizedBox(height: 30,),
              if(infoText.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 30), child: Text(infoText)),
              Padding(
                padding: const EdgeInsets.only(left: 50, right: 50),
                child: FloatingActionButton.extended(
                  icon: SizedBox(
                      width: 30,
                      height: 30,
                      child: Image.asset("assets/icons/kofi logo.png")),
                  onPressed: () => openKoFi(),
                  label: const Text("Buy me a coffee"),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 50, right: 50),
                child: FloatingActionButton.extended(
                  icon: Image.asset("assets/icons/paypal logo.png"),
                  onPressed: () => openPaypal(),
                  label: const Text(""),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 50, right: 50),
                child: FloatingActionButton.extended(
                  icon: SizedBox(
                      width: 30,
                      height: 30,
                      child: Image.asset("assets/icons/bitcoin.png")),
                  onPressed: () => openBitcoin(),
                  label: const Text("Bitcoin"),
                ),
              ),
              const SizedBox(height: 10)
            ]
        );
      });
}
