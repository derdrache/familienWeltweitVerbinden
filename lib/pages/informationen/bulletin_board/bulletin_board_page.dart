import 'package:familien_suche/pages/informationen/bulletin_board/bulletin_board_erstellen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../widgets/custom_appbar.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../start_page.dart';
import 'bulletin_board_note.dart';

class BulletinBoardPage extends StatefulWidget {
  bool forCity;
  bool forLand;

  BulletinBoardPage({Key? key, this.forCity = false, this.forLand = false})
      : super(key: key);

  @override
  State<BulletinBoardPage> createState() => _BulletinBoardPageState();
}

class _BulletinBoardPageState extends State<BulletinBoardPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  var onSearch = false;
  TextEditingController noteSearchKontroller = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  int displayDataEntries = 20;
  var allBulletinBoardNotes = Hive.box('secureBox').get("bulletinBoardNotes") ?? [];

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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    String onSearchText = onSearch ? AppLocalizations.of(context)!.suche : "";

    return Scaffold(
        appBar: CustomAppBar(
          title: "$onSearchText ${AppLocalizations.of(context)!.schwarzesBrett}",
          leading: IconButton(
            onPressed: () => global_functions.changePageForever(
                context,
                StartPage(
                  selectedIndex: 2,
                )),
            icon: const Icon(Icons.arrow_back),
          ),
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
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          for ( var note in allBulletinBoardNotes ) BulletinBoardCard(note: note)
                        ]
                      ),
                    )),
              ),
              if (onSearch)
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
                child: const Icon(Icons.create),
                onPressed: () => global_functions.changePage(
                    context, const BulletonBoardCreate())),
            const SizedBox(height: 10),
            FloatingActionButton(
              mini: onSearch ? true : false,
              backgroundColor: onSearch ? Colors.red : null,
              onPressed: () {
                if (onSearch) {
                  searchFocusNode.unfocus();
                  noteSearchKontroller.clear();
                }

                setState(() {
                  onSearch = !onSearch;
                });
              },
              child: Icon(onSearch ? Icons.close : Icons.search),
            ),
          ],
        ));
  }
}
