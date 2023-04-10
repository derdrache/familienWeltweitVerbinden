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
  final String userId = FirebaseAuth.instance.currentUser.uid;
  Map ownProfil = Hive.box('secureBox').get("ownProfil") ?? {};
  bool showFriendAdded;
  bool showFriendChangedLocation;
  bool showNewFamilyLocation;
  bool showInterestingEvents;
  bool showCityInformation;
  bool showFriendTravelPlan;
  double distance;

  @override
  void initState() {
    showFriendAdded = widget.settingsProfil["showFriendAdded"] == 1 ? true : false;
    showFriendChangedLocation =
        widget.settingsProfil["showFriendChangedLocation"] == 1 ? true : false;
    showNewFamilyLocation = widget.settingsProfil["showNewFamilyLocation"] == 1 ? true : false;
    showInterestingEvents = widget.settingsProfil["showInterestingEvents"] == 1 ? true : false;
    showCityInformation = widget.settingsProfil["showCityInformation"] == 1 ? true : false;
    showFriendTravelPlan = widget.settingsProfil["showFriendTravelPlan"] == 1 ? true : false;
    distance = ownProfil["familiesDistance"].toDouble() ?? 50.0;

    super.initState();
  }

  _changeHiveOwnNewsPageSetting(dbColumn, input) {
    Map ownSetting = Hive.box('secureBox').get("ownNewsSetting") ?? {};

    ownSetting[dbColumn] = input;
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
                    int intValue = value == true ? 1:0;

                    setState(() {
                      showFriendAdded = value;
                    });

                    NewsSettingsDatabase().update(
                        "showFriendAdded = '$intValue'",
                        "WHERE id = '$userId'");
                    _changeHiveOwnNewsPageSetting("showFriendAdded", intValue);
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
                    int intValue = value == true ? 1:0;

                    setState(() {
                      showFriendChangedLocation = value;
                    });
                    NewsSettingsDatabase().update(
                        "showFriendChangedLocation = '$intValue'",
                        "WHERE id = '$userId'");
                    _changeHiveOwnNewsPageSetting("showFriendChangedLocation", intValue);
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
          child: Column(
            children: [
              Row(
                children: [
                  Switch(
                      value: showNewFamilyLocation,
                      onChanged: (value) {
                        int intValue = value == true ? 1:0;
                        double newDistance = value ? 50 : 5;

                        setState(() {
                          showNewFamilyLocation = value;
                        });

                        NewsSettingsDatabase().update(
                            "showNewFamilyLocation = '$intValue'",
                            "WHERE id = '$userId'");

                        ProfilDatabase().updateProfil(
                            "familiesDistance = $newDistance",
                            "WHERE id = '$userId'"
                        );
                        _changeHiveOwnNewsPageSetting("showNewFamilyLocation", intValue);
                      }),
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).newsSettingNewFamilieLocation)
                ],
              ),
              if(showNewFamilyLocation) Text("${distance.round()} km ${AppLocalizations.of(context).umkreis}"),
              if(showNewFamilyLocation) Slider(
                value: distance,
                min: 5,
                max: 200,
                divisions: 100,
                label: '${distance.round()} km',
                onChanged: (newDistance){
                  setState(() {
                    distance = newDistance;
                    ownProfil["familiesDistance"] = newDistance;
                  });
                },
                onChangeEnd: (newDistance){
                  ProfilDatabase().updateProfil(
                      "familiesDistance = $newDistance",
                      "WHERE id = '$userId'"
                  );
                },
              )
            ],
          ));
    }

    friendNewTravelPlanOption(){
      return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Switch(
                  value: ownProfil["travelPlanNotification"] == 1 ? true : false,
                  onChanged: (value) {
                    int intValue = value == true ? 1:0;

                    setState(() {
                      ownProfil["travelPlanNotification"] = intValue;
                    });

                    ProfilDatabase().updateProfil(
                        "travelPlanNotification = '$intValue'",
                        "WHERE id = '${ownProfil["id"]}'");
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
                    int intValue = value == true ? 1:0;

                    setState(() {
                      showInterestingEvents = value;
                    });

                    NewsSettingsDatabase().update(
                        "showInterestingEvents = '$intValue'",
                        "WHERE id = '$userId'");
                    _changeHiveOwnNewsPageSetting("showInterestingEvents", intValue);
                  }),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).newsSettingShowMeetup)
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
                    int intValue = value == true ? 1:0;

                    setState(() {
                      showCityInformation = value;
                    });

                    NewsSettingsDatabase().update(
                        "showCityInformation = '$intValue'",
                        "WHERE id = '$userId'");
                    _changeHiveOwnNewsPageSetting("showCityInformation", intValue);
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
            friendNewTravelPlanOption(),
            newFamilyAtLocationOption(),
            showEventsOption(),
            showCityInformationOption(),
          ],
        ),
      ),
    );
  }
}
