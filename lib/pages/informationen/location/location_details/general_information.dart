import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../global/global_functions.dart' as global_func;
import '../../../../functions/is_user_inactive.dart';
import '../../../../services/database.dart';
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
  List familiesThere = [];

  @override
  void initState() {
    isCity = widget.location["isCity"] == 1;

    super.initState();
  }

  removeInactiveFamilies(familyList) {
    List allActiveProfils = List.of(getAllActiveProfilsHive());
    List activeFamilies = [];

    for (var profil in allActiveProfils) {
      if (familyList.contains(profil["id"])) activeFamilies.add(profil["id"]);
    }

    return activeFamilies;
  }

  showFamilyVisitWindow(list) {
    List<Widget> familiesList = [];

    for (var family in list) {
      var profil = getProfilFromHive(profilId: family);
      var isInactive = isUserInactive(profil);

      if (profil == null) continue;

      familiesList.add(InkWell(
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
                if (isInactive)
                  Text(
                    " - ${AppLocalizations.of(context)!.inaktiv}",
                    style: const TextStyle(color: Colors.red),
                  )
              ],
            )),
      ));
    }

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
    int familiesOnLocation = 0;
    var allProfils = getAllActiveProfilsHive();

    for (var profil in allProfils) {
      if (profil["ort"].isEmpty) continue;

      bool inLocation;

      if (isCity) {
        inLocation = widget.location["ort"].contains(profil["ort"]) ?? false;
      } else {
        inLocation = widget.location["ort"].contains(profil["land"]) ?? false;
      }

      if (inLocation) {
        familiesThere.add(profil["id"]);
        familiesOnLocation += 1;
      }
    }

    return familiesOnLocation;
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

  @override
  Widget build(BuildContext context) {
    double iconSize = 28;
    double fontSize = 18;
    var anzahlFamilien = widget.location["familien"]?.length ?? 0;

    showCurrentlyThere() {
      var familiesOnLocation = getFamiliesThere();

      return InkWell(
        onTap: () => showFamilyVisitWindow(familiesThere),
        child: Container(
          margin: const EdgeInsets.all(5),
          child: Row(
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
      return InkWell(
        onTap: () => showFamilyVisitWindow(widget.location["familien"]),
        child: Container(
          margin: const EdgeInsets.all(5),
          child: Row(
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
      );
    }

    showInsiderCount() {
      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(
              Icons.tips_and_updates,
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text("${AppLocalizations.of(context)!.insiderInformation}: ",
                style: TextStyle(fontSize: fontSize)),
            const SizedBox(width: 5),
            Text(widget.usersCityInformation.length.toString(),
                style: TextStyle(fontSize: fontSize))
          ],
        ),
      );
    }

    showCost() {
      setCostIconColor(indikator) {
        if (indikator <= 1) return Colors.green[800];
        if (indikator <= 2) return Colors.green;
        if (indikator <= 3) return Colors.yellow;
        if (indikator <= 4) return Colors.orange;

        return Colors.red;
      }

      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(
              Icons.monetization_on_outlined,
              color: widget.location["kosten"] == null
                  ? null
                  : setCostIconColor(widget.location["kosten"]),
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.kosten,
                style: TextStyle(fontSize: fontSize)),
            const SizedBox(width: 5),
            Text(
                widget.location["kosten"] == null
                    ? "?"
                    : "\$ " * widget.location["kosten"],
                style: TextStyle(fontSize: fontSize))
          ],
        ),
      );
    }

    showInternetSpeed() {
      String internetSpeedText = widget.location["internet"] == null
          ? "?"
          : widget.location["internet"].toString();

      setInternetIconColor(indikator) {
        if (indikator <= 20) return Colors.red;
        if (indikator <= 40) return Colors.orange;
        if (indikator <= 60) return Colors.yellow;
        if (indikator <= 80) return Colors.green;

        return Colors.green[800];
      }

      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(
              Icons.network_check_outlined,
              color: widget.location["internet"] == null
                  ? null
                  : setInternetIconColor(widget.location["internet"]),
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text("Internet: ", style: TextStyle(fontSize: fontSize)),
            const SizedBox(width: 5),
            Text(
                widget.location["internet"] == null
                    ? "?"
                    : "Ø $internetSpeedText Mbps",
                style: TextStyle(fontSize: fontSize))
          ],
        ),
      );
    }

    showWeather() {
      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(
              Icons.thermostat,
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.wetter,
                style: TextStyle(fontSize: fontSize)),
            if (widget.location["wetter"] != null)
              Flexible(
                  child: InkWell(
                      onTap: () =>
                          global_func.openURL(widget.location["wetter"]),
                      child: Text(widget.location["wetter"],
                          style:
                          TextStyle(color: Colors.blue, fontSize: fontSize),
                          overflow: TextOverflow.ellipsis)))
          ],
        ),
      );
    }

    return SelectionArea(
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      showCurrentlyThere(),
                      showVisited(),
                      showInsiderCount(),
                      showCost(),
                      showInternetSpeed(),
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