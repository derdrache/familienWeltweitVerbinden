import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/locationsService.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../global/global_functions.dart' as global_functions;
import 'bulletin_board_erstellen.dart';
import 'bulletin_board_note.dart';

class BulletinBoardPage extends StatefulWidget {
  const BulletinBoardPage({Key? key}) : super(key: key);

  @override
  State<BulletinBoardPage> createState() => _BulletinBoardPageState();
}

class _BulletinBoardPageState extends State<BulletinBoardPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController noteSearchKontroller = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  int displayDataEntries = 20;
  var allBulletinBoardNotes =
      Hive.box('secureBox').get("bulletinBoardNotes") ?? [];

  @override
  void initState() {
    _scrollBar();
    super.initState();
  }

  _scrollBar() {
    _scrollController.addListener(() {
      bool isBottom = _scrollController.position.atEdge;

      if (isBottom) {
        setState(() {
          displayDataEntries += 20;
        });
      }
    });
  }

  getAllSearchBulletinNotes() {
    var resultNotes = [];
    String searchText = noteSearchKontroller.text.toLowerCase();

    if (searchText.isEmpty) return allBulletinBoardNotes;

    for (var note in allBulletinBoardNotes) {
      bool nameKondition =
          note["titleGer"].toLowerCase().contains(searchText) ||
              note["titleEng"].toLowerCase().contains(searchText);
      bool countryKondition =
          note["location"]["countryname"].toLowerCase().contains(searchText) ||
              LocationService()
                  .transformCountryLanguage(note["location"]["countryname"])
                  .toLowerCase()
                  .contains(searchText);
      bool cityKondition =
          note["location"]["city"].toLowerCase().contains(searchText);

      if (nameKondition || countryKondition || cityKondition) {
        resultNotes.add(note);
      }
    }

    return resultNotes;
  }

  @override
  Widget build(BuildContext context) {
    allBulletinBoardNotes =
        Hive.box('secureBox').get("bulletinBoardNotes") ?? [];
    double width = MediaQuery.of(context).size.width;
    List allNotes = getAllSearchBulletinNotes();

    return Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.schwarzesBrett,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SizedBox(
                height: double.infinity,
                child: SingleChildScrollView(
                    controller: _scrollController,
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(alignment: WrapAlignment.center, children: [
                        for (var note in allNotes)
                          BulletinBoardCard(
                            note: note,
                            afterPageVisit: () {
                              setState(() {});
                            },
                          ),
                        if (allNotes.isEmpty)
                          SizedBox(
                              height: 300,
                              child: Center(
                                child: Text(
                                  noteSearchKontroller.text.isEmpty
                                      ? AppLocalizations.of(context)!
                                          .keineSchwarzeBrettZettelVorhanden
                                      : AppLocalizations.of(context)!
                                          .keineSchwarzeBrettZettelGefunden,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ))
                      ]),
                    )),
              ),
              if (allNotes.length > 30 || noteSearchKontroller.text.isNotEmpty)
                Positioned(
                    bottom: 15,
                    right: 15,
                    child: Container(
                      width: width * 0.9,
                      height: 50,
                      decoration: BoxDecoration(
                          border: Border.all(),
                          color: Colors.white,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20))),
                      child: TextField(
                        controller: noteSearchKontroller,
                        focusNode: searchFocusNode,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.suche,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(10)),
                        onChanged: (_) => setState(() {}),
                      ),
                    ))
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
                heroTag: "create note",
                tooltip: AppLocalizations.of(context)!.tooltipNotizErstellen,
                child: const Icon(Icons.create),
                onPressed: () => global_functions.changePage(
                    context, const BulletonBoardCreate())),
            if (getAllSearchBulletinNotes().length > 30)
              const SizedBox(height: 70),
          ],
        ));
  }
}
