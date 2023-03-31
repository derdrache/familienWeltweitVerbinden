import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:familien_suche/global/custom_widgets.dart';
import 'package:hive/hive.dart';
import '../../global/global_functions.dart';
import '../../widgets/custom_appbar.dart';

class FeedbackPage extends StatelessWidget {
  TextEditingController feedbackTextKontroller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final String userName = Hive.box("secureBox").get("ownProfil")["name"];

  feedbackSendenAndClose(context) async {
    if(feedbackTextKontroller.text.isEmpty) return;

    ChatDatabase().addAdminMessage(
        feedbackTextKontroller.text, userName);

    feedbackTextKontroller.clear();

    customSnackbar(context, AppLocalizations.of(context).feedbackDanke,
        color: Colors.green);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Feedback"),
      body: Form(
        key: formKey,
        child: ListView(
          children: [
            Center(
              child: Container(
                  margin: const EdgeInsets.all(30),
                  child: Text(AppLocalizations.of(context).feedbackText)),
            ),
            customTextInput(
                AppLocalizations.of(context).feedback, feedbackTextKontroller,
                moreLines: 10, validator: checkValidatorEmpty(context)),
            Align(
              child: Container(
                width: 200,
                margin: const EdgeInsets.all(10),
                child: FloatingActionButton.extended(
                    onPressed: () => feedbackSendenAndClose(context),
                    label: Text(AppLocalizations.of(context).senden)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
