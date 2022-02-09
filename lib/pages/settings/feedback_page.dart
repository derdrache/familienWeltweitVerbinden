import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:familien_suche/global/custom_widgets.dart';
import '../../global/global_functions.dart';

class FeedbackPage extends StatelessWidget {
  var feedbackTextKontroller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var userName = FirebaseAuth.instance.currentUser!.displayName;


  feedbackSendenAndClose(context) async {
    var chatDatabaseKontroller = ChatDatabase();

    chatDatabaseKontroller.addAdminMessage(
        feedbackTextKontroller.text, userName);

    feedbackTextKontroller.clear();
    Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {

    beschreibungsText(){
      return Container(
        margin: EdgeInsets.all(30),
        child: Text("Hier kannst du mir alles mitteilen von Fehler in der App "
            "über Verbesserungswünschen bis hin zu schönen Worten.")
      );
    }

    feedbackEingabe(){
      return customTextInput(
          "Feedback eingeben",
          feedbackTextKontroller,
          moreLines: 10,
          validator: checkValidatorEmpty()
      );
    }

    feedbackSendenButton(){
      return Container(
        margin: EdgeInsets.all(10),
        child: FloatingActionButton.extended(
            onPressed: () => feedbackSendenAndClose(context),
            label: Text("Senden")
        ),
      );
    }


    return Scaffold(
      appBar: customAppBar(title: "Feedback"),
      body: Form(
        key: formKey,
        child: ListView(
          children: [
            beschreibungsText(),
            feedbackEingabe(),
            feedbackSendenButton()
          ],
        ),
      ),
    );
  }
}
