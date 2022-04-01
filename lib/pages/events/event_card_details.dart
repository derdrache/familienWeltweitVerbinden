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
import '../../global/google_autocomplete.dart';
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

  EventCardDetails({Key key,
    this.event,
    this.offlineEvent=true,
    this.isApproved = false
  }) :
        isCreator = event["erstelltVon"] == userId,
        isPublic = event["art"] == "öffentlich" || event["art"] == "public";

  @override
  Widget build(BuildContext context) {
    var isAssetImage = event["bild"].substring(0,5) == "asset" ? true : false;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    if(screenWidth > 500) screenWidth = kIsWeb ? 400 : 500;
    double cardWidth = screenWidth / 1.12;//isWebDesktop ? 300 : 450; // Handy 392 => 350: Tablet 768
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
                rowData: event["wann"].split(" ")[0].split("-").reversed.join("."),
                inputHintText: AppLocalizations.of(context).neuesDatumEingeben,
                isCreator: isCreator,
                modus: "date",
                oldDate: event["wann"],
                databaseKennzeichnung: "wann"
            ),
            const SizedBox(height: 5),
            if(isApproved|| isPublic) ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventUhrzeitAendern,
                rowTitle: AppLocalizations.of(context).uhrzeit,
                rowData: event["wann"].split(" ")[1].split(":").take(2).join(":"),
                inputHintText: AppLocalizations.of(context).neueUhrzeitEingeben,
                isCreator: isCreator,
                modus: "dateTime",
                oldDate: event["wann"],
                databaseKennzeichnung: "wann"
            ),
            if(isApproved|| isPublic) const SizedBox(height: 5),
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
          padding: EdgeInsets.only(bottom: 20),
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

                      var freischaltenList = await EventDatabase().getOneData("freischalten", event["id"]);
                      freischaltenList.add(userId);
                      EventDatabase().updateOne(event["id"], "freischalten", freischaltenList);

                      var interessenList = await EventDatabase().getOneData("interesse", event["id"]);
                      interessenList.add(userId);
                      EventDatabase().updateOne(event["id"], "interesse", interessenList);
                    }
                  } ,
                  child: const Icon(Icons.add_circle, size: 80, color: Colors.black,)
                ),
                const Text(""),
                const SizedBox(height: 40,)
              ],
            )
          ),
          EventArtButton(event: event, isCreator: isCreator),
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
  });

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
      data = datumButton.eventDatum;
      var date = DateTime.parse(widget.oldDate);

      data = DateTime(data.year, data.month, data.day,
          date.hour, date.minute).toString();
    }else if (widget.modus == "dateTime"){
      data = uhrZeitButton.uhrZeit;
      var date = DateTime.parse(widget.oldDate);
      data = DateTime(date.year, date.month, date.day,
          data.hour, data.minute).toString();
    }

    return data;
  }

  checkValidation(data){
    var validationText = "";

    if(widget.databaseKennzeichnung == "name"){
      if(data.isEmpty) validationText = AppLocalizations.of(context).bitteNameEingeben;
      if(data.length > 40) validationText = AppLocalizations.of(context).usernameZuLang;
    }else if(widget.databaseKennzeichnung == "link"){
      if(data.substring(0,4) != "http" && data.substring(0,3) != "www")
        validationText = AppLocalizations.of(context).eingabeKeinLink;
    }

    return validationText;
  }

  changeRowData(data){
    if(widget.modus == "date") {
      widget.rowData = data.split(" ")[0];
    } else if(widget.modus == "dateTime"){
      widget.rowData = data.split(" ")[1] + " Uhr";
    }else if(widget.databaseKennzeichnung == "location"){
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
      EventDatabase().updateOne(widget.eventId, widget.databaseKennzeichnung, data);
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
      if(widget.modus == "dateTime") return uhrZeitButton;
      if(widget.modus == "date") return datumButton;

    }

    openChangeWindow(){
      CustomWindow(
          context: context,
          title: widget.windowTitle,
          height: widget.multiLines || widget.modus == "googleAutoComplete"? 300 : 180,
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
            const Expanded(child: const SizedBox.shrink()),
            InkWell(
                child: Container(
                  width: 200,
                  child: Text(
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

  CardFeed({Key key, this.organisator, this.width, this.eventId}) : super(key: key);

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
    setTeilnehmerAnzahl();
    super.initState();
  }

  setOrganisatorText()async{
    organisatorProfil = await ProfilDatabase().getProfil("id", widget.organisator);

    setState(() {
      organisatorText = Text(
          organisatorProfil["name"],
          style: TextStyle(color: Colors.blue, fontSize: fontsize)
      );
    });
  }
  
  setTeilnehmerAnzahl() async{
    var teilnehmer = await EventDatabase().getOneData("zusage", widget.eventId);

    teilnehmerAnzahl = teilnehmer.length.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 20),
      width: widget.width,
      child: Row(
        children: [
          Text(AppLocalizations.of(context).teilnehmer, style: TextStyle(fontSize: fontsize)),
          Text(teilnehmerAnzahl, style: TextStyle(fontSize: fontsize)),
          Expanded(child: SizedBox()),
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

          var interesseList = await EventDatabase().getOneData("interesse", widget.id);

          if(widget.hasIntereset){
            interesseList.add(userId);
          } else{
            interesseList.remove(userId);
          }

          EventDatabase().updateOne(widget.id, "interesse", interesseList);


        },
        child: Icon(Icons.favorite, color: widget.hasIntereset ? Colors.red : Colors.black, size: 30,)
    );
  }
}

class EventArtButton extends StatefulWidget {
  var event;
  var isCreator;

  EventArtButton({Key key, this.event, this.isCreator}) : super(key: key);

  @override
  _EventArtButtonState createState() => _EventArtButtonState();
}

class _EventArtButtonState extends State<EventArtButton> {
  var eventTypInput = CustomDropDownButton();
  var icon;

  eventArtSave(){
    var auswahl = eventTypInput.getSelected();
    if(auswahl == widget.event["art"]) return;


    widget.event["art"] = auswahl;
    setState(() {});

    EventDatabase().updateOne(widget.event["id"], "art", auswahl);

    Navigator.pop(context);

  }

  eventArtInformation(){
    return Positioned(
        top: -15,
        left:10,
        child: IconButton(
          icon: const Icon(Icons.help,size: 15),
          onPressed: () => CustomWindow(
              height: 500,
              context: context,
              title: AppLocalizations.of(context).informationEventArt,
              children: [
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(left: 5, right: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("privat       ", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(AppLocalizations.of(context).privatInformationText,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ]),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.only(left: 5, right: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        width: 70,
                        child: Text(AppLocalizations.of(context).halbOeffentlich,style: const TextStyle(fontWeight: FontWeight.bold))
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(AppLocalizations.of(context).halbOeffentlichInformationText,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ]),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.only(left: 5, right: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppLocalizations.of(context).oeffentlich, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(AppLocalizations.of(context).oeffentlichInformationText,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                )
              ]
          ),
        )
    );
  }

  @override
  void initState() {
    icon = widget.event["art"] == "öffentlich" || widget.event["art"] == "public" ?
    Icons.lock_open:
    widget.event["art"] == "privat" || widget.event["art"] == "private" ?
    Icons.enhanced_encryption :
    Icons.lock;

    eventTypInput = CustomDropDownButton(
      items: isGerman ? global_var.eventArt : global_var.eventArtEnglisch,
      selected: isGerman ? global_var.changeEnglishToGerman(widget.event["art"]):
        global_var.changeGermanToEnglish(widget.event["art"]),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Positioned(
      top: -5,
      left: -10,
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        onPressed: !widget.isCreator ? null : () => CustomWindow(
            context: context,
            title: AppLocalizations.of(context).eventArtAendern,
            height: 180,
            children: [
              eventTypInput,
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
                          onPressed: () => eventArtSave()
                      ),
                    ]
                ),
              )
            ]
        ),
      ),
    );
  }
}


