import 'package:familien_suche/windows/dialog_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/style.dart' as style;

donationWindow(BuildContext context, {infoText = ""}) {

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
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: SimpleDialog(
                contentPadding: const EdgeInsets.all(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(style.roundedCorners),
                ),
                insetPadding: const EdgeInsets.all(10),
                children: [
                  Text(AppLocalizations.of(context)!.supportFamiliesWorldwide, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                  if(infoText.isNotEmpty) Container(margin: const EdgeInsets.only(top: 20,bottom: 20), child: Text(infoText)),
                  FloatingActionButton.extended(
                    icon: SizedBox(
                        width: 30,
                        height: 30,
                        child: Image.asset("assets/icons/kofi logo.png")),
                    onPressed: () => openKoFi(),
                    label: const Text("Buy me a coffee"),
                  ),
                  const SizedBox(height: 30),
                  FloatingActionButton.extended(
                    icon: Image.asset("assets/icons/paypal logo.png"),
                    onPressed: ()=> openPaypal(),
                    label: const Text(""),
                  ),
                  const SizedBox(height: 30),
                  FloatingActionButton.extended(
                    icon: SizedBox(
                        width: 30,
                        height: 30,
                        child: Image.asset("assets/icons/bitcoin.png")),
                    onPressed: () => openBitcoin(),
                    label: const Text("Bitcoin"),
                  ),
                  const SizedBox(height: 10)
                ],
              ),
            ),
          ],
        );
      });
}
