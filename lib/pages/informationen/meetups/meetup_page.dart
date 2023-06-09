import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../../global/variablen.dart' as global_var;
import '../../../global/global_functions.dart' as global_functions;
import '../../../widgets/badge_icon.dart';
import '../../start_page.dart';
import 'meetup_suchen.dart';
import 'meetupCard.dart';
import 'meetup_erstellen.dart';

class MeetupPage extends StatefulWidget {
  const MeetupPage({Key? key}) : super(key: key);

  @override
  _MeetupPageState createState() => _MeetupPageState();
}

class _MeetupPageState extends State<MeetupPage> {
  var userId = FirebaseAuth.instance.currentUser!.uid;
  double textSizeHeadline = 20.0;
  var myOwnMeetups = Hive.box('secureBox').get("myEvents") ?? [];
  var myInterestedMeetups = Hive.box('secureBox').get("interestEvents") ?? [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    createMeetupCards(meetups, withInteresse) {
      List<Widget> meetupCards = [];

      for (var meetup in meetups) {
        bool isOwner = meetup["erstelltVon"] == userId;
        var freischaltenCount = meetup["freischalten"].length;
        bool isNotPublic = meetup["art"] != "public" && meetup["art"] != "öffentlich";

        meetupCards.add(Stack(
          children: [
            MeetupCard(
                meetupData: meetup,
                margin: const EdgeInsets.only(top: 10, bottom: 0, right: 20, left: 10),
                withInteresse: withInteresse,
                fromMeetupPage: true,
                afterFavorite: () => setState((){}),
                afterPageVisit: () => setState((){})),
            if (isOwner && isNotPublic)
              Positioned(
                right: 10,
                top: 10,
                child: BadgeIcon(
                  text: freischaltenCount > 0 ? freischaltenCount.toString(): "",
                )
              )
          ],
        ));
      }

      return meetupCards;
    }

    meineInteressiertenMeetupsBox() {
      return Container(
          padding: const EdgeInsets.only(top: 10),
          width: double.infinity,
          decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(width: 1, color: global_var.borderColorGrey))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Text(
                    AppLocalizations.of(context)!.favoritenMeetups,
                    style: TextStyle(fontSize: textSizeHeadline),
                  )),
              FutureBuilder(
                  future: null,
                  builder: (context, snapshot) {
                    if (myInterestedMeetups != null && myInterestedMeetups.isNotEmpty) {
                      return Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                              direction: Axis.vertical,
                              children: createMeetupCards(myInterestedMeetups, true)),
                        ),
                      );
                    }

                    return Center(
                        heightFactor: 5,
                        child: Text(
                          AppLocalizations.of(context)!
                              .nochKeineMeetupsAusgewaehlt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: textSizeHeadline, color: Colors.grey),
                        ));
                  }),
            ],
          ));
    }

    meineErstellenMeetupsBox() {
      return Container(
          padding: const EdgeInsets.only(top: 10),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Text(
                    AppLocalizations.of(context)!.meineMeetups,
                    style: TextStyle(fontSize: textSizeHeadline),
                  )),
              FutureBuilder(
                  future: null,
                  builder: (context, snapshot) {
                    if (myOwnMeetups != null && myOwnMeetups.isNotEmpty) {
                      return Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                              direction: Axis.vertical,
                              children: createMeetupCards(myOwnMeetups, false)),
                        ),
                      );
                    }

                    return Center(
                        heightFactor: 5,
                        child: Text(
                          AppLocalizations.of(context)!.nochKeineMeetupsErstellt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: textSizeHeadline, color: Colors.grey),
                        ));
                  }),
            ],
          ));
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "Meetups",
        leading: IconButton(
          onPressed: () => global_functions.changePageForever(context, StartPage(selectedIndex: 2,)),
          icon: const Icon(Icons.arrow_back),
        ),
        buttons: [
          IconButton(
              onPressed: ()=> Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MeetupSuchenPage()))
                  .whenComplete(() => setState(() {})),
              icon: const Icon(
                Icons.search,
                size: 30,
              ))
        ],
      ),
      body: SafeArea(
        child: Container(
            padding: const EdgeInsets.only(top: kIsWeb ? 0 : 24),
            child: Column(children: [
              Expanded(child: meineInteressiertenMeetupsBox()),
              Expanded(child: meineErstellenMeetupsBox()),
            ])),
      ),
      floatingActionButton: FloatingActionButton(
          heroTag: "meetup hinzufügen",
          child: const Icon(Icons.add),
          onPressed: () =>
              global_functions.changePage(context, const MeetupErstellen())),
    );
  }
}
