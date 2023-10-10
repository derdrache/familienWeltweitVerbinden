import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../functions/user_speaks_german.dart';
import '../../../../services/database.dart';
import '../../../../widgets/automatic_translation_notice.dart';
import '../../../../widgets/layout/custom_snackbar.dart';
import '../../../../widgets/layout/custom_text_input.dart';
import '../../../../windows/dialog_window.dart';

class LocationRating extends StatefulWidget {
  final Map location;

  const LocationRating({super.key, required this.location});

  @override
  State<LocationRating> createState() => _LocationRatingState();
}

class _LocationRatingState extends State<LocationRating> {
  final String ownUserId = FirebaseAuth.instance.currentUser!.uid;
  List ratingCategories = [
    "familyFriendly",
    "security",
    "kindness",
    "surrounding",
    "activities",
    "alternativeFood"
  ];
  late List allRatings;
  late String ratingCount;
  late Map locationRating;
  late Map newRating;
  bool hasRated = false;
  TextEditingController newCommentController = TextEditingController();
  List showOriginalComment = [];

  void calculateAndSetLocationRatingData() {
    locationRating = {"comments": []};

    for (Map rating in allRatings) {
      Map ratingValues = getAllRatingValues(rating);
      Map commentInfo = {
        "commentGer": rating["commentGer"],
        "commentEng": rating["commentEng"],
        "sprache": rating["sprache"],
        "userId": rating["user"],
        "userName":
            getProfilFromHive(profilId: rating["user"], getNameOnly: true) ??
                AppLocalizations.of(context)!.geloeschterUser,
        "sumRating": calculateSumRating(ratingValues),
        "date": rating["date"]
      };

      locationRating["comments"].add(commentInfo);

      if (rating["user"] == ownUserId) {
        newRating = rating;
        hasRated = true;
      }

      ratingValues.forEach((key, value) {
        if (value >= 1) {
          locationRating["${key}Count"] ??= 0;
          locationRating["${key}Count"] += 1;
        }

        locationRating[key] ??= 0.0;
        locationRating[key] += value;
      });
    }

    Map allRatingValues = getAllRatingValues(locationRating);
    Map adjustedRatingValues = {};
    allRatingValues.forEach((key, value) {
      locationRating[key] = value / locationRating[key + "Count"];
      adjustedRatingValues[key] = value / locationRating[key + "Count"];
    });

    double sumRating = calculateSumRating(adjustedRatingValues);

    locationRating["sum"] = adjustedRatingValues.isEmpty ? 0.0 : sumRating;
  }

  Map getAllRatingValues(Map rating) {
    Map ratingValues = {};

    rating.forEach((key, value) {
      if (ratingCategories.contains(key)) {
        ratingValues[key] = value + 0.0;
      }
    });

    return ratingValues;
  }

  calculateSumRating(Map ratingValues) {
    double sum = 0.0;
    int divider = 0;

    ratingValues.forEach((key, value) {
      if (value >= 1) {
        sum += value;
        divider += 1;
      }
    });

    if (divider == 0) return 0.0;

    return sum / divider;
  }

  changeNewRating(double rate, category) {
    if (category == null) return;
    newRating[category] = rate + 1;
  }

  saveNewRating() async {
    newRating["commentGer"] = newCommentController.text;
    newRating["commentEng"] = newCommentController.text;
    newRating["sprache"] = "de";

    widget.location["ratings"].add(newRating);

    dbSaveNewRating();
  }

  dbSaveNewRating() async {
    final translator = GoogleTranslator();
    var languageCheck = await translator.translate(newCommentController.text);
    bool commentIsGerman = languageCheck.sourceLanguage.code == "de";

    if (commentIsGerman) {
      newRating["sprache"] = "de";
      var translation = await translator.translate(newCommentController.text,
          from: "de", to: "auto");
      newRating["commentEng"] = translation.text;
    } else {
      newRating["sprache"] = "auto";
      var translation = await translator.translate(newCommentController.text,
          from: "auto", to: "de");
      newRating["commentGer"] = translation.text;
    }

    StadtInfoRatingDatabase().addNewRating(newRating);
  }

  editRating() {
    print(newCommentController.text);
    newRating["comment"] = newCommentController.text;
    newRating["date"] = DateTime.now().toString();

    StadtInfoRatingDatabase().update(
        "familyFriendly = '${newRating["familyFriendly"]}', "
            "security = '${newRating["security"]}', "
            "kindness = '${newRating["kindness"]}', "
            "surrounding = '${newRating["surrounding"]}', "
            "activities = '${newRating["activities"]}', "
            "alternativeFood = '${newRating["alternativeFood"]}', "
            "comment = '${newRating["comment"]}', "
            "date = '${newRating["date"]}'",
        "where locationId = ${widget.location["id"]} AND user = '$ownUserId'");
  }

  @override
  void initState() {
    super.initState();

    newRating = {
      "locationId": widget.location["id"],
      "user": ownUserId,
      "familyFriendly": 0.0,
      "security": 0.0,
      "kindness": 0.0,
      "surrounding": 0.0,
      "activities": 0.0,
      "alternativeFood": 0.0,
      "commentGer": "",
      "commentEng": "",
      "sprache": "",
      "date": DateTime.now().toString()
    };
  }

  @override
  Widget build(BuildContext context) {
    allRatings = widget.location["ratings"] ?? [];
    ratingCount = allRatings.length.toString();
    calculateAndSetLocationRatingData();

    Widget starIcon(
        {required rate, required fillIcon, category, windowSetState}) {
      double iconSize = 26;

      return GestureDetector(
        onTap: () {
          setState(() {});
          if (windowSetState != null) windowSetState(() {});
          changeNewRating(rate.toDouble(), category);
        },
        child: Icon(
          fillIcon ? Icons.star : Icons.star_border_outlined,
          size: iconSize,
        ),
      );
    }

    ratingRow(title, double rating, {category, windowSetState, totalSpezial = false}) {
      int maxRating = 5;
      List<Widget> starRating = List.generate(
          maxRating,
          (i) => Opacity(
            opacity: totalSpezial && rating == 0.0 ? 0 : 1,
            child: starIcon(
                rate: i,
                fillIcon: i < rating.round(),
                category: category,
                windowSetState: windowSetState),
          ));

      return Container(
        margin: const EdgeInsets.only(top: 5, bottom: 5),
        child: Row(
          children: [
            Expanded(
                child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
            ...starRating,
            const SizedBox(
              width: 30,
            ),
            Text(rating.toStringAsFixed(1))
          ],
        ),
      );
    }

    commentSection() {
      bool userSpeakGerman = getUserSpeaksGerman();
      List comments = locationRating["comments"];
      List<Widget> commentWidgets = [];

      for (var i = 0; i < comments.length; i++) {
        String comment = "";
        String originalComment = "";
        String translatedComment = "";
        bool translated = false;

        bool commentIsGerman = comments[i]["sprache"] == "de";
        bool commentGerAndUserGer = commentIsGerman && userSpeakGerman;
        bool commentEngAndUserGer = !commentIsGerman && userSpeakGerman;

        if (showOriginalComment.length < i + 1) {
          showOriginalComment.add(commentGerAndUserGer || commentEngAndUserGer);
        }

        if (commentIsGerman) {
          originalComment = comments[i]["commentGer"];
          translatedComment = comments[i]["commentEng"];
        } else {
          originalComment = comments[i]["commentEng"];
          translatedComment = comments[i]["commentGer"];
        }

        if (showOriginalComment[i] || comments[i]["userId"] == ownUserId) {
          comment = originalComment;
        } else {
          translated = true;
          comment = translatedComment;
        }

        commentWidgets.add(Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star),
                  Text(comments[i]["sumRating"].toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                      child: Center(
                          child: Text(
                    comments[i]["userName"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ))),
                  if (comments[i]["userId"] != ownUserId)
                    InkWell(
                      onTap: () => setState(() {
                        showOriginalComment[i] = !showOriginalComment[i];
                      }),
                      child: Text(
                        showOriginalComment[i]
                            ? AppLocalizations.of(context)!.uebersetzen
                            : "Original",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Text(comment),
              AutomaticTranslationNotice(translated: translated, padding: EdgeInsets.all(10),),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    comments[i]["date"]
                        .split(" ")[0]
                        .split("-")
                        .reversed
                        .toList()
                        .join("."),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                ],
              )
            ],
          ),
        ));
      }

      return Expanded(
        child: ListView(
          children: commentWidgets
        ),
      );
    }

    openRatingWindow() {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(
                builder: (context, StateSetter windowsSetState) {
              Map ratingValues = getAllRatingValues(newRating);
              newCommentController.text = newRating["sprache"] == "de"
                  ? newRating["commentGer"]
                  : newRating["commentEng"];

              return CustomAlertDialog(
                title:
                    "${AppLocalizations.of(context)!.bewerten1} ${widget.location["ort"]} ${AppLocalizations.of(context)!.bewerten2}",
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        ratingRow(AppLocalizations.of(context)!.gesamt,
                            calculateSumRating(ratingValues),
                            category: null, windowSetState: windowsSetState, totalSpezial: true),
                        ratingRow(
                            AppLocalizations.of(context)!.familienfreundlich,
                            ratingValues["familyFriendly"],
                            category: "familyFriendly",
                            windowSetState: windowsSetState),
                        ratingRow(AppLocalizations.of(context)!.sicherheit,
                            ratingValues["security"],
                            category: "security",
                            windowSetState: windowsSetState),
                        ratingRow(AppLocalizations.of(context)!.freundlichkeit,
                            ratingValues["kindness"],
                            category: "kindness",
                            windowSetState: windowsSetState),
                        ratingRow(AppLocalizations.of(context)!.umlandNatur,
                            ratingValues["surrounding"],
                            category: "surrounding",
                            windowSetState: windowsSetState),
                        ratingRow(AppLocalizations.of(context)!.aktivitaeten,
                            ratingValues["activities"],
                            category: "activities",
                            windowSetState: windowsSetState),
                        ratingRow(
                            AppLocalizations.of(context)!
                                .alternativeLebensmittel,
                            ratingValues["alternativeFood"],
                            category: "alternativeFood",
                            windowSetState: windowsSetState),
                      ],
                    ),
                  ),
                  CustomTextInput(
                    newRating["commentGer"],
                    newCommentController,
                    hintText: AppLocalizations.of(context)!.deinKommentar,
                    moreLines: 8,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Align(
                      child: SizedBox(
                          width: 100,
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              Navigator.pop(context);

                              setState(() {
                                if (hasRated) {
                                  editRating();
                                  customSnackBar(
                                      context,
                                      AppLocalizations.of(context)!
                                          .erfolgreichGeaender,
                                      color: Colors.green);
                                } else {
                                  saveNewRating();
                                }
                              });
                            },
                            label: Text(hasRated
                                ? AppLocalizations.of(context)!.aendern
                                : AppLocalizations.of(context)!.senden),
                          ))),
                  const SizedBox(
                    height: 10,
                  )
                ],
              );
            });
          });
    }

    return SafeArea(
      child: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${AppLocalizations.of(context)!.bewertungen} $ratingCount",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                    FloatingActionButton.extended(
                      onPressed: () => openRatingWindow(),
                      label: Text( !hasRated ? AppLocalizations.of(context)!.ortBewerten : AppLocalizations.of(context)!.bewertungAendern),
                      tooltip: AppLocalizations.of(context)!.ortBewerten,
                    )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ratingRow(AppLocalizations.of(context)!.gesamt,
                  locationRating["sum"] ?? 0.0),
              ratingRow(AppLocalizations.of(context)!.familienfreundlich,
                  locationRating["familyFriendly"] ?? 0.0),
              ratingRow(AppLocalizations.of(context)!.sicherheit,
                  locationRating["security"] ?? 0.0),
              ratingRow(AppLocalizations.of(context)!.freundlichkeit,
                  locationRating["kindness"] ?? 0.0),
              ratingRow(AppLocalizations.of(context)!.umlandNatur,
                  locationRating["surrounding"] ?? 0.0),
              ratingRow(AppLocalizations.of(context)!.aktivitaeten,
                  locationRating["activities"] ?? 0.0),
              ratingRow(AppLocalizations.of(context)!.alternativeLebensmittel,
                  locationRating["alternativeFood"] ?? 0.0),
              const SizedBox(
                height: 30,
              ),
              Text(
                AppLocalizations.of(context)!.kommentare,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              commentSection()
            ],
          ),
        ),
      ),
    );
  }
}
