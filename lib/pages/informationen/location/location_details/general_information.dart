import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../global/global_functions.dart' as global_func;
import '../../../../functions/is_user_inactive.dart';
import '../../../../services/database.dart';
import '../../../../widgets/windowConfirmCancelBar.dart';
import '../../../../windows/dialog_window.dart';
import '../../../chat/chat_details.dart';
import '../../../show_profil.dart';

class GeneralInformationPage extends StatefulWidget {
  final Map location;
  final List usersCityInformation;
  final bool fromCityPage;

  const GeneralInformationPage(
      {Key? key,
      required this.location,
      required this.usersCityInformation,
      this.fromCityPage = false})
      : super(key: key);

  @override
  State<GeneralInformationPage> createState() => _GeneralInformationPageState();
}

class _GeneralInformationPageState extends State<GeneralInformationPage> {
  var userId = FirebaseAuth.instance.currentUser!.uid;
  late bool isCity;
  final translator = GoogleTranslator();
  late bool hasVisited;

  @override
  void initState() {
    isCity = widget.location["isCity"] == 1;

    super.initState();
  }

  showFamilyVisitWindow(list) {
    List<Widget> familiesListActive = [];
    List<Widget> familiesListInacitve = [];

    for (var profil in list) {
      var isInactive = isUserInactive(profil);
      var familyProfil = getFamilyProfil(familyMemberId: profil["id"]);
      bool isFamilyMember = false;

      if (familyProfil != null){
        isFamilyMember = familyProfil["members"].contains(userId);
      }

      if (profil == null || profil.isEmpty) continue;

      Widget profilRow = InkWell(
        onTap: () =>
            global_func.changePage(context, ShowProfilPage(profil: profil)),
        child: Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Text(
                  profil["name"],
                  style: const TextStyle(fontSize: 20),
                ),
                if (profil["id"] == userId || isFamilyMember) Text(
                  " - ${AppLocalizations.of(context)!.eigenesProfil}",
                  style: TextStyle(color: Colors.green),
                ),
                if (isInactive)
                  Text(
                    " - ${AppLocalizations.of(context)!.inaktiv}",
                    style: const TextStyle(color: Colors.red),
                  )
              ],
            )),
      );

      if (isInactive) {
        familiesListInacitve.add(profilRow);
      } else {
        familiesListActive.add(profilRow);
      }
    }

    List<Widget> familiesList = familiesListActive + familiesListInacitve;

    if (familiesList.isEmpty) {
      familiesList.add(Container(
          margin: const EdgeInsets.all(10),
          child: Text(AppLocalizations.of(context)!.keineFamilieStadt)));
    } else {
      familiesList.add(const SizedBox(height: 10));
    }

    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  title: AppLocalizations.of(context)!.besuchtVon,
                  children: familiesList);
            }));
  }

  getFamiliesThere() {
    var profilList = [];
    var allProfils = getAllActiveProfilsHive();

    for (var profil in allProfils) {
      if (profil["ort"].isEmpty) continue;

      bool inLocation;

      if (isCity) {
        inLocation = widget.location["ort"].contains(profil["ort"]) ?? false;
      } else {
        inLocation = widget.location["ort"].contains(profil["land"]) ?? false;
      }

      if (inLocation) profilList.add(profil["id"]);
    }

    return profilList;
  }

  createNewChatGroup(lcationId) async {
    String locationId = lcationId.toString();
    var chatGroup = getChatGroupFromHive(connectedWith: locationId.toString());
    if (chatGroup != null) return;

    var checkChatGroup = await ChatGroupsDatabase()
        .getChatData("id", "WHERE connected = '</stadt=$locationId'");
    if (checkChatGroup != false) return;

    var newChatId =
        await ChatGroupsDatabase().addNewChatGroup(null, "</stadt=$locationId");
    var hiveChatGroups = Hive.box('secureBox').get("chatGroups");
    hiveChatGroups.add({
      "id": newChatId,
      "users": {},
      "lastMessage": "</neuer Chat",
      "lastMessageDate": DateTime.now().millisecondsSinceEpoch,
      "connected": "</stadt=$locationId"
    });
  }

  setInternetIconColor(indikator) {
    if (indikator <= 20) return Colors.red;
    if (indikator <= 40) return Colors.orange;
    if (indikator <= 60) return Colors.yellow;
    if (indikator <= 80) return Colors.green;

    return Colors.green[800];
  }

  getCityImage(){
    if (widget.location["bild"].isEmpty) {
      return Image.asset(
        "assets/bilder/city.jpg",
        fit: BoxFit.fill,
      );
    }else{
      return CachedNetworkImage(
        imageUrl: widget.location["bild"],
        fit: BoxFit.fill,
      );
    }
  }

  getLocationImageWidgetNew() {
    if (widget.location["bild"].isEmpty) {
      if (!isCity) {
        return Image.asset(
          "assets/bilder/land.jpg",
          fit: BoxFit.fill,
        );
      }
      return Image.asset(
        "assets/bilder/city.jpg",
        fit: BoxFit.fill,
      );
    } else {
      String imgUrl = isCity ? widget.location["bild"] : widget.location["mainCityImage"] ?? "";
      return CachedNetworkImage(
        imageUrl: imgUrl,
        fit: BoxFit.fill,
      );
    }
  }

  changeVisitedStauts() {
    hasVisited = !hasVisited;

    if (hasVisited) {
      widget.location["familien"].add(userId);
      StadtinfoDatabase().update(
          "familien = JSON_ARRAY_APPEND(familien, '\$', '$userId')",
          "where id = '${widget.location["id"]}'");
    } else {
      widget.location["familien"].remove(userId);
      StadtinfoDatabase().update(
          "familien = JSON_REMOVE(familien, JSON_UNQUOTE(JSON_SEARCH(familien, 'one', '$userId')))",
          "where id = '${widget.location["id"]}'");
    }
  }

  changeVisitedStatusWindow() {
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
              title: hasVisited
                  ? AppLocalizations.of(context)!.ortNichtBesuchtTitle
                  : AppLocalizations.of(context)!.ortBesuchtTitle,
              children: [
                Container(
                    margin: const EdgeInsets.all(10),
                    child: Center(
                        child: Text(hasVisited
                            ? "${AppLocalizations.of(context)!.ortNichtBesuchtBody1} ${widget.location["ort"]} ${AppLocalizations.of(context)!.ortNichtBesuchtBody2}"
                            : "${AppLocalizations.of(context)!.ortBesuchtBody1} ${widget.location["ort"]} ${AppLocalizations.of(context)!.ortBesuchtBody2}"))),
                WindowConfirmCancelBar(
                  onConfirm: () {
                    setState(() {
                      changeVisitedStauts();
                    });
                  },
                ),
              ]);
        });
  }

  changeFamilyProfils({profilIdList}){
    List newProfilList = [];
    List removeProfils = [];

      for (var profileId in profilIdList) {
        var profile = Map.of(getProfilFromHive(profilId: profileId) ?? {});
        var familyProfil = getFamilyProfil(familyMemberId: profile["id"]);

        if (familyProfil == null){
          newProfilList.add(profile);
          continue;
        }

        var familyMembers = List.of(familyProfil["members"]);
        familyMembers.remove(familyProfil["mainProfil"]);
        profile["name"] = familyProfil["name"];
        removeProfils += familyMembers;

        newProfilList.add(profile);
    }


    for (var profils in removeProfils){
      newProfilList.removeWhere((profil) => profil["id"] == profils);
    }

    return newProfilList;
  }

  @override
  Widget build(BuildContext context) {
    double iconSize = 28;
    double fontSize = 18;
    hasVisited = widget.location["familien"].contains(userId);

    displayContainer({child, margin}) {
      return Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: child);
    }

    showCurrentlyThere() {
      List familiesThere = getFamiliesThere();
      familiesThere = changeFamilyProfils(profilIdList: familiesThere);

      var familiesOnLocation = familiesThere.length;

      return InkWell(
        onTap: () => showFamilyVisitWindow(familiesThere),
        child: displayContainer(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pin_drop, size: iconSize),
              const SizedBox(width: 10),
              Text(
                  AppLocalizations.of(context)!.aktuellDort +
                      familiesOnLocation.toString() +
                      AppLocalizations.of(context)!.familien,
                  style: TextStyle(
                      fontSize: fontSize,
                      decoration: TextDecoration.underline)),
            ],
          ),
        ),
      );
    }

    showVisited() {
      List visitFamilies = List.of(widget.location["familien"]);
      visitFamilies = changeFamilyProfils(profilIdList: visitFamilies);
      int anzahlFamilien = visitFamilies.length;



      return Row(
        children: [
          InkWell(
            onTap: () => showFamilyVisitWindow(visitFamilies),
            child: displayContainer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.family_restroom, size: iconSize),
                  const SizedBox(width: 10),
                  Text(
                      AppLocalizations.of(context)!.besuchtVon +
                          anzahlFamilien.toString() +
                          AppLocalizations.of(context)!.familien,
                      style: TextStyle(
                          fontSize: fontSize,
                          decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 25,
            width: 25,
            child: FloatingActionButton.small(
              heroTag: "openVisitedStatusWindow",
              onPressed: () => changeVisitedStatusWindow(),
              backgroundColor: hasVisited ? Colors.red : null,
              child: Icon(
                hasVisited ? Icons.remove : Icons.add,
                size: 20,
              ),
            ),
          )
        ],
      );
    }

    showInsiderCount() {
      return displayContainer(
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tips_and_updates,
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text(widget.usersCityInformation.length.toString(),
                style: TextStyle(fontSize: fontSize))
          ],
        ),
      );
    }

    showCost() {
      if (widget.location["kosten"] == null) {
        return const SizedBox.shrink();
      }

      int costRate = widget.location["kosten"];

      return displayContainer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < costRate; i++) const Icon(Icons.attach_money),
            for (var i = costRate; i < 5; i++)
              Icon(
                Icons.attach_money,
                color: Colors.grey[300],
              ),
          ],
        ),
      );
    }

    showInternetSpeed() {
      String internetSpeedText = widget.location["internet"].toString();

      if (widget.location["internet"] == null) {
        return const SizedBox.shrink();
      }

      return displayContainer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.network_check_outlined,
              color: widget.location["internet"] == null
                  ? null
                  : setInternetIconColor(widget.location["internet"]),
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text("$internetSpeedText Mbps",
                style: TextStyle(fontSize: fontSize))
          ],
        ),
      );
    }

    showWeather() {
      if (widget.location["wetter"] == null) {
        return const SizedBox.shrink();
      }

      return displayContainer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.thermostat,
              size: iconSize,
            ),
            const SizedBox(width: 10),
            InkWell(
                onTap: () => global_func.openURL(widget.location["wetter"]),
                child: Text(
                  AppLocalizations.of(context)!.klimatabelle,
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: fontSize,
                      decoration: TextDecoration.underline),
                ))
          ],
        ),
      );
    }

    showBulletInformation() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [showInsiderCount(), showInternetSpeed(), showCost()],
      );
    }

    return SelectionArea(
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: isCity
                    ? getLocationImageWidgetNew()
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: !isCity
                                ? MediaQuery.of(context).size.height / 3 * 1.7
                                : double.infinity,
                            child: getLocationImageWidgetNew(),
                          ),
                          if (!isCity)
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: Image.asset(
                                  "assets/bilder/flaggen/${widget.location["bild"]}.jpeg",
                                  fit: BoxFit.fill,
                                ),
                              ),
                            )
                        ],
                      ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      showBulletInformation(),
                      showCurrentlyThere(),
                      showVisited(),
                      showWeather(),
                    ]),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await createNewChatGroup(widget.location["id"]);

              if (context.mounted) {
                global_func.changePage(
                    context,
                    ChatDetailsPage(
                      isChatgroup: true,
                      connectedWith: "</stadt=${widget.location["id"]}",
                    ));
              }
            },
            tooltip: AppLocalizations.of(context)!.tooltipOrtChatOeffnen,
            child: const Icon(Icons.message),
          ),
        ),
      ),
    );
  }
}
