import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../widgets/text_with_hyperlink_detection.dart';

class PinMessagesPage extends StatelessWidget {
  List pinMessages;
  MaterialAccentColor ownMessageBoxColor = Colors.greenAccent;
  Color chatpartnerMessageBoxColor = Colors.white;
  String userId = FirebaseAuth.instance.currentUser!.uid;


  PinMessagesPage({required this.pinMessages, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    showMessages(){
      List<Widget> messagesBoxList = [];

      for(Map message in pinMessages){
        Alignment textAlign = Alignment.centerLeft;
        Color boxColor = chatpartnerMessageBoxColor;
        DateTime messageDateTime =
        DateTime.fromMillisecondsSinceEpoch(int.parse(message["date"]));
        String messageTime = DateFormat('HH:mm').format(messageDateTime);
        String messageEdit = message["editDate"] == null
            ? ""
            : AppLocalizations.of(context)!.bearbeitet;

        if (message["von"] == userId) {
          textAlign = Alignment.centerRight;
          boxColor = ownMessageBoxColor;
        }

        messagesBoxList.add(Align(
          alignment: textAlign,
          child: Stack(
            children: [
              Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: boxColor,
                      border: Border.all(),
                      borderRadius:
                      const BorderRadius.all(Radius.circular(10))),
                  child: Wrap(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                            top: 5, left: 10, bottom: 7, right: 10),
                        child: TextWithHyperlinkDetection(
                            text: message["message"] ?? "",
                            fontsize: 16,
                            ),
                      ),
                      SizedBox(
                          width: message["editDate"] == null ? 40 : 110),
                    ],
                  )),
              Positioned(
                right: 20,
                bottom: 15,
                child: Text("$messageEdit $messageTime",
                    style: TextStyle(color: Colors.grey[600])),
              )
            ],
          ),
        ));
      }

      return messagesBoxList;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.angehefteteNachrichten,
      ),
      body: ListView(
        reverse: true,
        children: showMessages().reversed.toList(),
      ),
    );
  }
}
