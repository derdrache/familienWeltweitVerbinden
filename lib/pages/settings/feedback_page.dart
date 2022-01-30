import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:familien_suche/global/custom_widgets.dart';
import '../../global/global_functions.dart';

class FeedbackPage extends StatelessWidget {
  var profil;
  var feedbackTextKontroller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  FeedbackPage({Key? key, profil}) : super(key: key);

  feedbackSenden(){
    if(formKey.currentState!.validate()){
      final Uri emailLaunchUri = Uri(
          scheme: 'mailto',
          path: 'dominik.mast.11@gmail.com',
          queryParameters: {
            'subject': 'Feedback für Familien Weltweit App',
            'body': feedbackTextKontroller.text
          }
      );

    launch(emailLaunchUri.toString());

    }
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
            onPressed: () => feedbackSenden(),
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
