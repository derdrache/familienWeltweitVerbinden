import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:familien_suche/global/custom_widgets.dart';
import '../../global/global_functions.dart';
import '../../widgets/custom_appbar.dart';

class FeedbackPage extends StatelessWidget {
  var feedbackTextKontroller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var userEmail = FirebaseAuth.instance.currentUser.email;


  feedbackSendenAndClose(context) async {
    var chatDatabaseKontroller = ChatDatabase();

    chatDatabaseKontroller.addAdminMessage(
        feedbackTextKontroller.text, userEmail);

    feedbackTextKontroller.clear();

    customSnackbar(context,
        AppLocalizations.of(context).feedbackDanke,
        color: Colors.green
    );

    Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {

    beschreibungsText(){
      return Center(
        child: Container(
          margin: EdgeInsets.all(30),
          child: Text(AppLocalizations.of(context).feedbackText)
        ),
      );
    }

    feedbackEingabe(){
      return customTextInput(
          AppLocalizations.of(context).feedback,
          feedbackTextKontroller,
          moreLines: 10,
          validator: checkValidatorEmpty(context)
      );
    }

    feedbackSendenButton(){
      return Align(
        child: Container(
          width: 200,
          margin: EdgeInsets.all(10),
          child: FloatingActionButton.extended(
              onPressed: () => feedbackSendenAndClose(context),
              label: Text(AppLocalizations.of(context).senden)
          ),
        ),
      );
    }


    return Scaffold(
      appBar: CustomAppBar(title: "Feedback"),
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
