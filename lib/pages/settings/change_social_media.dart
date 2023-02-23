import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../global/global_functions.dart';
import '../../widgets/custom_appbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ChangeSocialMediaLinks extends StatefulWidget {
  const ChangeSocialMediaLinks({Key key}) : super(key: key);

  @override
  State<ChangeSocialMediaLinks> createState() => _ChangeSocialMediaLinksState();
}

class _ChangeSocialMediaLinksState extends State<ChangeSocialMediaLinks> {
  Map ownProfil = Hive.box("secureBox").get("ownProfil");
  var newLinkController = TextEditingController();
  bool incorrectInput = false;

  showAddSheet() async {
    await showModalBottomSheet(
      context: context,
      elevation: 5,
      enableDrag: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, bottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: 150,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextField(
                      controller: newLinkController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(0.0),
                        border: UnderlineInputBorder(),
                        labelText: 'Enter link',
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if(incorrectInput) Text(
                          AppLocalizations.of(context).eingabeKeinLink,
                         style: const TextStyle(color: Colors.red),
                      ),
                      const Expanded(child: SizedBox.shrink()),
                      ElevatedButton(
                        child: const Text("OK"),
                        onPressed: () {
                          String newLink = newLinkController.text;

                          if(!isLink(newLink) || newLink.isEmpty){
                            bottomSheetState((){
                              incorrectInput = true;
                            });
                          }else{
                            Navigator.pop(context);
                            saveNewLink(newLink);
                            setState(() {
                              newLinkController.clear();
                              incorrectInput = false;
                            });
                          }
                        },
                      )
                    ],)
                  ],),
                ),
              ),
            );
          }
        );
      }
    );

    setState(() {
      newLinkController.clear();
      incorrectInput = false;
    });
  }

  saveNewLink(newLink){
    ownProfil["socialMediaLinks"].add(newLink);
    ProfilDatabase().updateProfil(
      "socialMediaLinks = JSON_ARRAY_APPEND(socialMediaLinks, '\$', '$newLink')",
      "WHERE id = '${ownProfil["id"]}'"
    );
  }

  deleteLink(link){
    ownProfil["socialMediaLinks"].remove(link);
    ProfilDatabase().updateProfil(
        "socialMediaLinks = JSON_REMOVE(socialMediaLinks, JSON_UNQUOTE(JSON_SEARCH(socialMediaLinks, 'one', '$link')))",
        "WHERE id = '${ownProfil["id"]}'"
    );
  }

  @override
  Widget build(BuildContext context) {

    showSocialMediaLinks(){
      List<Widget> allSocialMediaLinks = [];

      for(var socialMediaLink in ownProfil["socialMediaLinks"]){
        allSocialMediaLinks.add(
          Container(
            margin: const EdgeInsets.all(10),
            child: Row(children: [
              Text(socialMediaLink),
              Expanded(child: SizedBox.shrink()),
              CloseButton(
                onPressed: (){
                  deleteLink(socialMediaLink);
                  setState(() {});
                },
              )
            ],),
          )
        );
      }

      return allSocialMediaLinks;
    }

    return Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).socialMediaLinkAendern
      ),
      body: Column(children: showSocialMediaLinks(),),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => showAddSheet(),
      ),
    );
  }
}
