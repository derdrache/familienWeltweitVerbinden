import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

class NewsPageSettingsPage extends StatefulWidget {
  const NewsPageSettingsPage({Key key}) : super(key: key);

  @override
  State<NewsPageSettingsPage> createState() => _NewsPageSettingsPageState();
}

class _NewsPageSettingsPageState extends State<NewsPageSettingsPage> {
  bool showFriendAdded;
  bool showFriendChangedLocation;
  bool showNewFamilyLocation;
  bool showInterestingEvents;
  bool showCityInformation;

  @override
  Widget build(BuildContext context) {

    newFriendOption() {
      return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showFriendAdded,
                  onChanged: (value) {
                    setState(() {
                      showFriendAdded = value;
                    });
                  }),
              SizedBox(width: 10),
              Text("Als Freund hinzugefügt anzeigen")
            ],
          ));
    }

    friendChangedLocationOption() {
      return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showFriendChangedLocation,
                  onChanged: (value) {
                    setState(() {
                      showFriendChangedLocation = value;
                    });
                  }),
              SizedBox(width: 10),
              Text("Freund Standort gewechselt anzeigen")
            ],
          ));
    }

    newFamilyAtLocationOption() {
      return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showNewFamilyLocation,
                  onChanged: (value) {
                    setState(() {
                      showNewFamilyLocation = value;
                    });
                  }),
              SizedBox(width: 10),
              Text("Neue Familie an deinem Ort anzeigen")
            ],
          ));
    }

    showEventsOption() {
      return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showInterestingEvents,
                  onChanged: (value) {
                    setState(() {
                      showInterestingEvents = value;
                    });
                  }),
              SizedBox(width: 10),
              Text("interessante Events anzeigen")
            ],
          ));
    }

    showCityInformationOption() {
      return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showCityInformation,
                  onChanged: (value) {
                    setState(() {
                      showCityInformation = value;
                    });
                  }
              ),
              SizedBox(width: 10),
              Text("neue Statdinfomationen anzeigen")
            ],
          ));
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "News Anzeige",
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            newFriendOption(),
            friendChangedLocationOption(),
            newFamilyAtLocationOption(),
            showEventsOption(),
            showCityInformationOption()
          ],
        ),
      ),
    );
  }
}