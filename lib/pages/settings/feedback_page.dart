import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../functions/sendAdmin.dart';
import '../../global/global_functions.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';

class FeedbackPage extends StatelessWidget {
  final TextEditingController feedbackTextKontroller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final String userName = Hive.box("secureBox").get("ownProfil")["name"];

  FeedbackPage({Key? key}) : super(key: key);

  feedbackSendenAndClose(context) async {
    String title = "Feedback zu families worldwide";
    String text = feedbackTextKontroller.text;

    if (text.isEmpty) return;

    text = text.replaceAll("'", "''");

    addAdminMessage(title, text, userName);

    feedbackTextKontroller.clear();

    customSnackBar(context, AppLocalizations.of(context)!.feedbackDanke,
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
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: CustomTextInput(
                  feedbackTextKontroller.text, feedbackTextKontroller,
                  moreLines: 10,
                  hintText: AppLocalizations.of(context)!.feedbackText,
                  labelText: "Feedback",
                  validator: checkValidatorEmpty(context)),
            ),
            Align(
              child: Container(
                width: 200,
                margin: const EdgeInsets.all(10),
                child: FloatingActionButton.extended(
                    onPressed: () => feedbackSendenAndClose(context),
                    label: Text(
                      AppLocalizations.of(context)!.senden,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }
}
