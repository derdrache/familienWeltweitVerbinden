import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/pages/show_profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/google_autocomplete.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_var;
import '../../widgets/image_galerie.dart';

var userId = FirebaseAuth.instance.currentUser.uid;
var isWebDesktop = kIsWeb && (defaultTargetPlatform != TargetPlatform.iOS || defaultTargetPlatform != TargetPlatform.android);
double fontsize = isWebDesktop? 12 : 16;
var isGerman = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";


class EventCardDetails extends StatelessWidget {
  var event;
  var offlineEvent;
  var isCreator;
  var isApproved;
  var isPublic;

  EventCardDetails({
    Key key,
    this.event,
    this.offlineEvent=true,
    this.isApproved = false
  }) :
        isCreator = event["erstelltVon"] == userId,
        isPublic = event["art"] == "öffentlich" || event["art"] == "public", super(key: key);

  @override
  Widget build(BuildContext context) {
    var isAssetImage = event["bild"].substring(0,5) == "asset" ? true : false;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    if(screenWidth > 500) screenWidth = kIsWeb ? 400 : 500;
    double cardWidth = screenWidth / 1.12;
    double cardHeight = screenHeight / 1.34;
    event["eventInterval"] = isGerman ? global_var.changeEnglishToGerman(event["eventInterval"]):
      global_var.changeGermanToEnglish(event["eventInterval"]);
    

    bildAndTitleBox(){
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Stack(
            children: [
              ImageGalerie(
                id: event["id"],
                isCreator: isCreator,
                child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    child: isAssetImage ?  Image.asset(event["bild"], fit: BoxFit.fitWidth) :
                    Image.network(event["bild"], fit: BoxFit.fitWidth,)
                ),

              ),

            ],
          ),
          Positioned.fill(
              bottom: -10,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      padding: const EdgeInsets.only(top:10, bottom: 10),
                      decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3), // changes position of shadow
                            ),
                          ]
                      ),
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      width: 800,
                      child: ShowDataAndChangeWindow(
                          eventId: event["id"],
                          windowTitle: AppLocalizations.of(context).eventNameAendern,
                          rowData: event["name"],
                          inputHintText: AppLocalizations.of(context).neuenNamenEingeben,
                          isCreator: isCreator,
                          modus: "textInput",
                          singleShow: true,
                          databaseKennzeichnung: "name"
                      )
                  )
              )
          ),
        ],
      );
    }

    eventInformationBox(){
      return Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          children: [
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventDatumAendern,
                rowTitle: AppLocalizations.of(context).datum,
                rowData: event["wann"].substring(0,16),
                inputHintText: AppLocalizations.of(context).neuesDatumEingeben,
                isCreator: isCreator,
                modus: "date",
                oldDate: event["wann"],
                databaseKennzeichnung: "wann"
            ),
            const SizedBox(height: 5),
            ShowDataAndChangeWindow(
              eventId: event["id"],
              windowTitle: AppLocalizations.of(context).eventZeitzoneAendern,
              rowTitle: AppLocalizations.of(context).zeitzone,
              rowData: event["zeitzone"],
              inputHintText: AppLocalizations.of(context).neueZeitzoneEingeben,
              isCreator: isCreator,
              modus: "dropdown",
              databaseKennzeichnung: "zeitzone",
              items: global_var.eventZeitzonen
            ),
            const SizedBox(height: 5),
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventStadtAendern,
                rowTitle: AppLocalizations.of(context).ort,
                rowData: event["stadt"] + ", " + event["land"],
                inputHintText: AppLocalizations.of(context).neueStadtEingeben,
                isCreator: isCreator,
                modus: "googleAutoComplete",
                databaseKennzeichnung: "location"
            ),
            const SizedBox(height: 5),
            if(isApproved|| isPublic) ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventMapLinkAendern,
                rowTitle: "Map: ",
                rowData: event["link"],
                inputHintText: AppLocalizations.of(context).neuenKartenlinkEingeben,
                isCreator: isCreator,
                modus: "textInput",
                databaseKennzeichnung: "link"
            ),
            if(isApproved|| isPublic) const SizedBox(height: 5),
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventIntervalAendern,
                inputHintText: "",
                isCreator: isCreator,
                rowTitle: "Interval",
                rowData: event["eventInterval"],
                items: isGerman ? global_var.eventInterval : global_var.eventIntervalEnglisch,
                modus: "dropdown",
                databaseKennzeichnung: "eventInterval"
            ),
            const SizedBox(height: 5),
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventSpracheAendern,
                inputHintText: "",
                isCreator: isCreator,
                rowTitle: AppLocalizations.of(context).sprache,
                rowData: event["sprache"].join(", "),
                items: isGerman ? global_var.sprachenListe : global_var.sprachenListeEnglisch,
                modus: "dropdown",
                databaseKennzeichnung: "sprache"
            ),
          ],
        ),
      );
    }

    eventBeschreibung(){
      return Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.only(bottom: 20),
          child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 25.0,
                ),
                child: ShowDataAndChangeWindow(
                    eventId: event["id"],
                    windowTitle: AppLocalizations.of(context).eventBeschreibungAendern,
                    rowData: event["beschreibung"],
                    inputHintText: AppLocalizations.of(context).neueBeschreibungEingeben,
                    isCreator: isCreator,
                    modus: "textInput",
                    multiLines: true,
                    databaseKennzeichnung: "beschreibung"
                ),
              )
          )
      );
    }

    creatorChangeHintBox(){
      if (isCreator){
        return Center(
          child: Text(
              AppLocalizations.of(context).antippenZumAendern,
              style: const TextStyle(color: Colors.grey)
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: cardWidth,
            height: cardHeight,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.6),
                    spreadRadius: 12,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ]
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                bildAndTitleBox(),
                const SizedBox(height: 20),
                creatorChangeHintBox(),
                eventInformationBox(),
                if(isApproved || isPublic) eventBeschreibung(),
              ],
            ),
          ),
          if(!isApproved && !isPublic) Container(
            width: cardWidth,
            height: cardHeight,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.withOpacity(0.6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: ()  async {
                    var isOnList = event["freischalten"].contains(userId);

                    if(isOnList) {
                      customSnackbar(context,
                          AppLocalizations.of(context).eventOrganisatorMussFreischalten,
                          color: Colors.green);
                      return;
                    } else{
                      customSnackbar(context,
                          AppLocalizations.of(context).eventInteresseMitgeteilt,
                          color: Colors.green);

                      var dbDaten = await EventDatabase()
                          .getData("freischalten, interesse", "WHERE id = '${event["id"]}'");

                      var freischaltenList = dbDaten["freischalten"];
                      freischaltenList.add(userId);

                      var interessenList = dbDaten["interesse"];
                      interessenList.add(userId);

                      EventDatabase().update(
                          event["id"],
                          "freischalten = '${json.encode(freischaltenList)}', "
                          "interesse = '${json.encode(interessenList)}'"
                      );
                    }
                  } ,
                  child: const Icon(Icons.add_circle, size: 80, color: Colors.black,)
                ),
                const Text(""),
                const SizedBox(height: 40,)
              ],
            )
          ),
          if(!isCreator) Positioned(
              top: 25,
              right: 28,
              child: InteresseButton(
                hasIntereset: event["interesse"].contains(userId),
                id: event["id"],
              )
          ),
          Positioned(
            bottom: 30,
            left: 30,
            child: CardFeed(
              organisator: event["erstelltVon"],
              eventId: event["id"],
              eventZusage: event["zusage"],
              width: cardWidth
            )
          )
        ],
      ),
    );
  }
}


class ShowDataAndChangeWindow extends StatefulWidget {
  var windowTitle;
  var rowTitle;
  var rowData;
  var inputHintText;
  var isCreator;
  var items;
  var modus;
  var singleShow;
  var multiLines;
  var databaseKennzeichnung;
  var oldDate;
  var eventId;

  ShowDataAndChangeWindow({
    Key key,
    this.windowTitle,
    this.isCreator,
    this.rowTitle,
    this.rowData,
    this.inputHintText,
    this.items,
    this.modus,
    this.singleShow = false,
    this.multiLines = false,
    this.databaseKennzeichnung,
    this.oldDate,
    this.eventId
  }) : super(key: key);

  @override
  _ShowDataAndChangeWindowState createState() => _ShowDataAndChangeWindowState();
}

class _ShowDataAndChangeWindowState extends State<ShowDataAndChangeWindow> {
  var dropdownInput = CustomDropDownButton();
  var inputKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete();
  var uhrZeitButton = DateButton();
  var datumButton = DateButton(getDate: true);
  var uhrZeit;


  @override
  void initState() {
    if(widget.rowData != String) widget.rowData = widget.rowData.toString();
    if(!(widget.databaseKennzeichnung == "link")) inputKontroller.text = widget.rowData;

    dropdownInput = CustomDropDownButton(
      hintText: widget.inputHintText,
      items: widget.items,
      selected: widget.rowData,
    );

    ortAuswahlBox.hintText = widget.inputHintText;

    super.initState();
  }

  getData(){
    var data;

    if(widget.databaseKennzeichnung == "name"){
      data = inputKontroller.text;
    } else if (widget.databaseKennzeichnung == "location"){
      data = ortAuswahlBox.googleSearchResult;
    } else if (widget.databaseKennzeichnung == "link"){
      data = inputKontroller.text;
    }else if (widget.databaseKennzeichnung == "art"){
      data = dropdownInput.getSelected();
    }else if (widget.databaseKennzeichnung == "eventInterval"){
      data = dropdownInput.getSelected();
    }else if (widget.databaseKennzeichnung == "beschreibung"){
      data = inputKontroller.text;
    }else if (widget.modus == "date"){
      var date = datumButton.eventDatum ?? DateTime.parse(widget.oldDate);
      var time = uhrZeitButton.uhrZeit ?? DateTime.parse(widget.oldDate);

      data = DateTime(date.year, date.month, date.day,
          time.hour, time.minute).toString().substring(0,16);
    }

    return data;
  }

  checkValidation(data){
    var validationText = "";

    if(widget.databaseKennzeichnung == "name"){
      if(data.isEmpty) validationText = AppLocalizations.of(context).bitteNameEingeben;
      if(data.length > 40) validationText = AppLocalizations.of(context).usernameZuLang;
    }else if(widget.databaseKennzeichnung == "link"){
      if(data.substring(0,4) != "http" && data.substring(0,3) != "www") {
        validationText = AppLocalizations.of(context).eingabeKeinLink;
      }
    }

    return validationText;
  }

  changeRowData(data){
    if(widget.databaseKennzeichnung == "location"){
      widget.rowData = data["city"] + ", " + data["countryname"];
    }else{
      widget.rowData = data;
    }
  }

  saveChanges(){
    var data = getData();

    var errorText = checkValidation(data);
    if(!errorText.isEmpty){
      customSnackbar(context, errorText);
      return;
    }

    changeRowData(data);

    Navigator.pop(context);

    setState(() {});

    if(widget.databaseKennzeichnung == "location"){
      EventDatabase().updateLocation(widget.eventId, data);
    } else{
      EventDatabase().update(widget.eventId, "${widget.databaseKennzeichnung} = '$data'");
    }
  }

  @override
  Widget build(BuildContext context) {

    inputBox(){
      if(widget.modus == "textInput"){
        return customTextInput(widget.inputHintText, inputKontroller, moreLines: widget.multiLines? 7: 1);
      }
      if(widget.modus == "dropdown") return dropdownInput;
      if(widget.modus == "googleAutoComplete") return ortAuswahlBox;
      if(widget.modus== "date"){
        return Column(children: [
          datumButton,
          const SizedBox(height: 20),
          uhrZeitButton,
          const SizedBox(height: 50)
        ]);
      }
    }

    openChangeWindow(){

      showDialog(
          context: context,
          builder: (BuildContext buildContext){
            return CustomAlertDialog(
                title: widget.windowTitle,
                height: widget.multiLines || widget.modus == "googleAutoComplete" ||
                    widget.modus == "date"? 300 : 180,
                children: [
                  inputBox(),
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: Text(AppLocalizations.of(context).abbrechen, style: TextStyle(fontSize: fontsize)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                              child: Text(AppLocalizations.of(context).speichern, style: TextStyle(fontSize: fontsize)),
                              onPressed: () => saveChanges()
                          ),
                        ]
                    ),
                  )
                ]
            );
          });



    }

    openLinkAskWindow(){
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  openChangeWindow();
                },
                child: Text(AppLocalizations.of(context).linkBearbeiten),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  launch(widget.rowData);
                },
                child: Text(AppLocalizations.of(context).linkOeffnen),
              ),
            ],
          );
        },
      );
    }


    return InkWell(
        onTap: !widget.isCreator ? null:  (){
          openChangeWindow();
        },
        child: !widget.singleShow && !widget.multiLines ? Row(
          children: [
            Text(widget.rowTitle + " ", style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold)),
            const Expanded(child: SizedBox.shrink()),
            InkWell(
                child: SizedBox(
                  width: 200,
                  child: Text(
                    widget.databaseKennzeichnung =="zeitzone" ? "UTC " + widget.rowData.toString():
                      widget.rowData,
                    style: TextStyle(
                        fontSize: fontsize,
                        color: widget.databaseKennzeichnung != "link" ?
                          Colors.black : Colors.blue
                    ),
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.end,
                  ),
                ),
              onTap: widget.databaseKennzeichnung != "link" || widget.rowData == "" ? null : (){
                  if(widget.isCreator){
                    openLinkAskWindow();
                  }else{
                    launch(widget.rowData);
                  }
              },
            )
          ],
        ):
        Text(
          widget.rowData,
          style: !widget.multiLines ?
          TextStyle(fontSize: fontsize +8, fontWeight: FontWeight.bold) :
          TextStyle(fontSize: fontsize),
          textAlign: TextAlign.center,
        )
    );
  }
}

class CardFeed extends StatefulWidget {
  var organisator;
  var eventId;
  var width;
  var eventZusage;

  CardFeed({Key key, this.organisator, this.width, this.eventId, this.eventZusage}) : super(key: key);

  @override
  _CardFeedState createState() => _CardFeedState();
}

class _CardFeedState extends State<CardFeed> {
  var organisatorText = const Text("");
  var organisatorProfil;
  var ownName = FirebaseAuth.instance.currentUser.displayName;
  var teilnehmerAnzahl = "";

@override
  void initState() {
    setOrganisatorText();
    super.initState();
  }

  setOrganisatorText()async{
    organisatorProfil = await ProfilDatabase().getData("*", "WHERE id = '${widget.organisator}'");

    organisatorText = Text(
        organisatorProfil["name"],
        style: TextStyle(color: Colors.blue, fontSize: fontsize)
    );

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.only(right: 20),
      width: widget.width,
      child: Row(
        children: [
          Text(AppLocalizations.of(context).teilnehmer, style: TextStyle(fontSize: fontsize)),
          Text(
              widget.eventZusage.length.toString(),
              style: TextStyle(fontSize: fontsize)
          ),
          const Expanded(child: SizedBox()),
          InkWell(
            child: organisatorText,
            onTap: () {
              changePage(context, ShowProfilPage(
                userName: ownName,
                profil: organisatorProfil,
              ));
            },
          )
        ],
      ),
    );
  }
}


class DateButton extends StatefulWidget {
  var uhrZeit;
  var eventDatum;
  var getDate;

  DateButton({Key key, this.getDate = false}) : super(key: key);


  @override
  _DateButtonState createState() => _DateButtonState();
}

class _DateButtonState extends State<DateButton> {

  dateBox(){
    var dateString = AppLocalizations.of(context).neuesDatumAuswaehlen;
    if(widget.eventDatum != null){
      var dateFormat = DateFormat('dd.MM.yyyy');
      var dateTime = DateTime(widget.eventDatum.year, widget.eventDatum.month, widget.eventDatum.day);
      dateString = dateFormat.format(dateTime);
    }

    return ElevatedButton(
      child: Text(dateString),
      onPressed: () async {
        widget.eventDatum = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(DateTime.now().year + 1)
        );

        setState(() {});
      },
    );
  }

  timeBox(){
    return ElevatedButton(
      child: Text(
          widget.uhrZeit == null ? AppLocalizations.of(context).neueUhrzeitAuswaehlen:
          widget.uhrZeit.format(context)
      ),
      onPressed: () async {
        widget.uhrZeit = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 12, minute: 00),
        );

        setState(() {

        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: widget.getDate ? dateBox() : timeBox(),
    );
  }
}


class InteresseButton extends StatefulWidget {
  var hasIntereset;
  var id;

  InteresseButton({Key key, this.hasIntereset, this.id}) : super(key: key);

  @override
  _InteresseButtonState createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          widget.hasIntereset = widget.hasIntereset ? false : true;

          setState(() {});

          var interesseList = await EventDatabase()
              .getData("interesse", "WHERE id = '${widget.id}'");

          if(widget.hasIntereset){
            interesseList.add(userId);
          } else{
            interesseList.remove(userId);
          }

          EventDatabase()
              .update(widget.id, "interesse = '${json.encode(interesseList)}'");


        },
        child: Icon(Icons.favorite, color: widget.hasIntereset ? Colors.red : Colors.black, size: 30,)
    );
  }
}


