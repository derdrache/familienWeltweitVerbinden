import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

class NewsPageSettingsPage extends StatefulWidget {
  Map settingsProfil;

  NewsPageSettingsPage({Key key, this.settingsProfil}) : super(key: key);

  @override
  State<NewsPageSettingsPage> createState() => _NewsPageSettingsPageState();
}

class _NewsPageSettingsPageState extends State<NewsPageSettingsPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  bool showFriendAdded;
  bool showFriendChangedLocation;
  bool showNewFamilyLocation;
  bool showInterestingEvents;
  bool showCityInformation;
  bool showFriendTravelPlan;

  @override
  void initState() {
    showFriendAdded = widget.settingsProfil["showFriendAdded"];
    showFriendChangedLocation =
        widget.settingsProfil["showFriendChangedLocation"];
    showNewFamilyLocation = widget.settingsProfil["showNewFamilyLocation"];
    showInterestingEvents = widget.settingsProfil["showInterestingEvents"];
    showCityInformation = widget.settingsProfil["showCityInformation"];
    showFriendTravelPlan = widget.settingsProfil["showFriendTravelPlan"];

    super.initState();
  }

  changeHiveProfil(dbColumn, input) {
    var newsSettings = Hive.box('secureBox').get("newsSettings") ?? [];

    for (var newsSetting in newsSettings) {
      if (newsSetting["id"] == userId) newsSetting[dbColumn] = input;
    }
  }

  @override
  Widget build(BuildContext context) {
    newFriendOption() {
      return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showFriendAdded,
                  onChanged: (value) {
                    setState(() {
                      showFriendAdded = value;
                    });

                    NewsSettingsDatabase().update(
                        "showFriendAdded = '${value == true ? 1 : 0}'",
                        "WHERE id = '$userId'");
                    changeHiveProfil("showFriendAdded", value);
                  }),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).newsSettingFriendAdd)
            ],
          ));
    }

    friendChangedLocationOption() {
      return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showFriendChangedLocation,
                  onChanged: (value) {
                    setState(() {
                      showFriendChangedLocation = value;
                    });

                    NewsSettingsDatabase().update(
                        "showFriendChangedLocation = '${value == true ? 1 : 0}'",
                        "WHERE id = '$userId'");
                    changeHiveProfil("showFriendChangedLocation", value);
                  }),
              const SizedBox(width: 10),
              Text(
                  AppLocalizations.of(context).newsSettingFriendLocationChanged)
            ],
          ));
    }

    newFamilyAtLocationOption() {
      return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showNewFamilyLocation,
                  onChanged: (value) {
                    setState(() {
                      showNewFamilyLocation = value;
                    });

                    NewsSettingsDatabase().update(
                        "showNewFamilyLocation = '${value == true ? 1 : 0}'",
                        "WHERE id = '$userId'");
                    changeHiveProfil("showNewFamilyLocation", value);
                  }),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).newsSettingNewFamilieLocation)
            ],
          ));
    }

    newTravelPlanFriend(){
      return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showFriendTravelPlan,
                  onChanged: (value) {
                    setState(() {
                      showFriendTravelPlan = value;
                    });

                    NewsSettingsDatabase().update(
                        "showFriendTravelPlan = '${value == true ? 1 : 0}'",
                        "WHERE id = '$userId'");
                    changeHiveProfil("showFriendTravelPlan", value);
                  }),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).newsSettingShowTravelPlan)
            ],
          ));
    }

    showEventsOption() {
      return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showInterestingEvents,
                  onChanged: (value) {
                    setState(() {
                      showInterestingEvents = value;
                    });

                    NewsSettingsDatabase().update(
                        "showInterestingEvents = '${value == true ? 1 : 0}'",
                        "WHERE id = '$userId'");
                    changeHiveProfil("showInterestingEvents", value);
                  }),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).newsSettingShowEvent)
            ],
          ));
    }

    showCityInformationOption() {
      return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: showCityInformation,
                  onChanged: (value) {
                    setState(() {
                      showCityInformation = value;
                    });

                    NewsSettingsDatabase().update(
                        "showCityInformation = '${value == true ? 1 : 0}'",
                        "WHERE id = '$userId'");
                    changeHiveProfil("showCityInformation", value);
                  }),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).newsSettingShowCityInformation)
            ],
          ));
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).newsSettingTitle,
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            newFriendOption(),
            friendChangedLocationOption(),
            newTravelPlanFriend(),
            newFamilyAtLocationOption(),
            showEventsOption(),
            showCityInformationOption()
          ],
        ),
      ),
    );
  }
}
