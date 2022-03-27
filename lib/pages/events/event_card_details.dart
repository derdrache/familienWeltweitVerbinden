import 'package:familien_suche/pages/show_profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart';
import '../../global/google_autocomplete.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_var;

var userId = FirebaseAuth.instance.currentUser.uid;
var isWebDesktop = kIsWeb && (defaultTargetPlatform != TargetPlatform.iOS || defaultTargetPlatform != TargetPlatform.android);
double fontsize = isWebDesktop? 12 : 16;

class EventCardDetails extends StatelessWidget {
  var event;
  var offlineEvent;
  var isCreator;
  var isApproved;

  EventCardDetails({Key key, this.event, this.offlineEvent=true, this.isApproved = false}) :
        isCreator = event["erstelltVon"] == userId;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    if(screenWidth > 500) screenWidth = kIsWeb ? 400 : 500;
    double cardWidth = screenWidth / 1.12;//isWebDesktop ? 300 : 450; // Handy 392 => 350: Tablet 768
    double cardHeight = screenHeight / 1.34;
    

    bildAndTitleBox(){
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Stack(
            children: [
              ShowImageAndChangeWindow(
                id: event["id"],
                isCreator: isCreator,
                currentImage: event["bild"],
                items: ["Fußball", "Pool", "Spielplatz", "Strand"]
              ),
              if(!isCreator) Positioned(
                  top: 5,
                  right: 8,
                  child: InteresseButton(
                    interesse: event["interesse"],
                    id: event["id"],
                  )
              )
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
          )
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
                rowTitle: "Datum",
                rowData: event["wann"].split(" ")[0].split("-").reversed.join("."),
                inputHintText: AppLocalizations.of(context).neuesDatumEingeben,
                isCreator: isCreator,
                modus: "date",
                oldDate: event["wann"],
                databaseKennzeichnung: "wann"
            ),
            const SizedBox(height: 10),
            if(isApproved|| event["art"] == "öffentlich") ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventUhrzeitAendern,
                rowTitle: "Uhrzeit",
                rowData: event["wann"].split(" ")[1].split(":").take(2).join(":") + " Uhr",
                inputHintText: AppLocalizations.of(context).neueUhrzeitEingeben,
                isCreator: isCreator,
                modus: "dateTime",
                oldDate: event["wann"],
                databaseKennzeichnung: "wann"
            ),
            if(isApproved|| event["art"] == "öffentlich") const SizedBox(height: 10),
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventStadtAendern,
                rowTitle: "Ort",
                rowData: event["stadt"] + ", " + event["land"],
                inputHintText: AppLocalizations.of(context).neueStadtEingeben,
                isCreator: isCreator,
                modus: "googleAutoComplete",
                databaseKennzeichnung: "location"
            ),
            const SizedBox(height: 10),
            if(isApproved|| event["art"] == "öffentlich") ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventMapLinkAendern,
                rowTitle: "Map",
                rowData: event["link"],
                inputHintText: AppLocalizations.of(context).neuenKartenlinkEingeben,
                isCreator: isCreator,
                modus: "textInput",
                databaseKennzeichnung: "link"
            ),
            if(isApproved|| event["art"] == "öffentlich") const SizedBox(height: 10),
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: AppLocalizations.of(context).eventIntervalAendern,
                isCreator: isCreator,
                rowTitle: "Häufigkeit",
                rowData: event["eventInterval"],
                items: global_var.eventInterval,
                modus: "dropdown",
                databaseKennzeichnung: "eventInterval"
            ),
          ],
        ),
      );
    }

    eventBeschreibung(){
      return Container(
          margin: const EdgeInsets.all(10),
          child: Center(
              child: Container(
                width: double.infinity,
                constraints: new BoxConstraints(
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
              style: TextStyle(color: Colors.grey)
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
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.6),
                    spreadRadius: 12,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
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
                if(isApproved || event["art"] == "öffentlich") eventBeschreibung(),
                OrganisatorBox(organisator: event["erstelltVon"],)
              ],
            ),
          ),
          if(!isApproved && event["art"] != "öffentlich") Container(
            width: cardWidth,
            height: cardHeight,
            margin: EdgeInsets.all(20),
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
                      customSnackbar(context, AppLocalizations.of(context).eventOrganisatorMussFreischalten);
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
                  child: Icon(Icons.add_circle, size: 80, color: Colors.black,)
                ),
                Text(""),
                SizedBox(height: 40,)
              ],
            )
          ),
          EventArtButton(event: event)
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

    return InkWell(
        onTap: !widget.isCreator ? null:  (){
          CustomWindow(
              context: context,
              title: widget.windowTitle,
              height: widget.multiLines || widget.modus == "googleAutoComplete"? 300 : 180,
              children: [
                inputBox(),
                Container(
                  margin: EdgeInsets.only(right: 10),
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
        },
        child: !widget.singleShow && !widget.multiLines ? Row(
          children: [
            Text(widget.rowTitle + " ", style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold)),
            const Expanded(child: const SizedBox.shrink()),
            Text(widget.rowData, style: TextStyle(fontSize: fontsize))
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

class ShowImageAndChangeWindow extends StatefulWidget {
  var items;
  var currentImage;
  var id;
  var isCreator;

  ShowImageAndChangeWindow({
    Key key, this.items,
    this.currentImage,
    this.id,
    this.isCreator
  }) : super(key: key);

  @override
  _ShowImageAndChangeWindowState createState() => _ShowImageAndChangeWindowState();
}

class _ShowImageAndChangeWindowState extends State<ShowImageAndChangeWindow> {
  var dropdownInput = CustomDropDownButton();

  @override
  void initState() {
    var selected = widget.currentImage.split("/").last.split(".")[0];
    selected = selected[0].toUpperCase() + selected.substring(1);

    dropdownInput = CustomDropDownButton(
      selected: selected,
      items: widget.items
    );

    super.initState();
  }

  saveChanges(){
    var selectedImage = dropdownInput.selected;
    var imageDatei = "assets/bilder/" + selectedImage[0].toLowerCase() + selectedImage.substring(1) + ".jpg";

    widget.currentImage = imageDatei;
    setState(() {});

    EventDatabase().updateOne(widget.id, "bild", imageDatei);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: !widget.isCreator ? null: () {
        CustomWindow(
            context: context,
            title: AppLocalizations.of(context).eventBildAendern,
            height: 180,
            children: [
              dropdownInput,
              Container(
                margin: EdgeInsets.only(right: 10),
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
      },
      child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: Image.asset(widget.currentImage)
      ),
    );
  }
}

class OrganisatorBox extends StatefulWidget {
  var organisator;

  OrganisatorBox({Key key, this.organisator}) : super(key: key);

  @override
  _OrganisatorBoxState createState() => _OrganisatorBoxState();
}

class _OrganisatorBoxState extends State<OrganisatorBox> {
  var organisatorText = Text("");
  var organisatorProfil;
  var ownName = FirebaseAuth.instance.currentUser.displayName;

@override
  void initState() {
    setOrganisatorText();
    super.initState();
  }

  setOrganisatorText()async{
    organisatorProfil = await ProfilDatabase().getProfil("id", widget.organisator);

    setState(() {
      organisatorText = Text(
          organisatorProfil["name"],
          style: TextStyle(color: Colors.grey)
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        changePage(context, ShowProfilPage(
          userName: ownName,
          profil: organisatorProfil,
          ));
      },
      child: Container(
        alignment: Alignment.centerRight,
        margin: EdgeInsets.all(20),
        child: organisatorText
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
          initialTime: TimeOfDay(hour: 12, minute: 00),
        );

        setState(() {

        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: widget.getDate ? dateBox() : timeBox(),
    );
  }
}


class InteresseButton extends StatefulWidget {
  var interesse;
  var id;

  InteresseButton({Key key, this.interesse, this.id}) : super(key: key);

  @override
  _InteresseButtonState createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;
  var hasIntereset = false;

  @override
  void initState() {
    hasIntereset = widget.interesse.contains(userId);

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          hasIntereset = hasIntereset ? false : true;

          setState(() {});

          var interesseList = await EventDatabase().getOneData("interesse", widget.id);

          if(hasIntereset){
            interesseList.add(userId);
          } else{
            interesseList.remove(userId);
          }

          EventDatabase().updateOne(widget.id, "interesse", interesseList);


        },
        child: Icon(Icons.favorite, color: hasIntereset ? Colors.red : Colors.black, size: 30,)
    );
  }
}

class EventArtButton extends StatefulWidget {
  var event;

  EventArtButton({Key key, this.event}) : super(key: key);

  @override
  _EventArtButtonState createState() => _EventArtButtonState();
}

class _EventArtButtonState extends State<EventArtButton> {
  var eventTypInput = CustomDropDownButton();


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
          icon: Icon(Icons.help,size: 15),
          onPressed: () => CustomWindow(
              height: 500,
              context: context,
              title: AppLocalizations.of(context).informationEventArt,
              children: [
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.only(left: 5, right: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("privat       ", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(AppLocalizations.of(context).privatInformationText,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ]),
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.only(left: 5, right: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        width: 70,
                        child: Text(AppLocalizations.of(context).halbOeffentlich,style: TextStyle(fontWeight: FontWeight.bold))
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(AppLocalizations.of(context).halbOeffentlichInformationText,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ]),
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.only(left: 5, right: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppLocalizations.of(context).oeffentlich, style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 5),
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
    eventTypInput = CustomDropDownButton(
      items: global_var.eventArt,
      selected: widget.event["art"],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Positioned(
      top: 0,
      left: -10,
      child: IconButton(
        icon: Icon(widget.event["art"] != "öffentlich" ?
          Icons.lock : Icons.lock_open, color: Theme.of(context).colorScheme.primary),
        onPressed: () => CustomWindow(
            context: context,
            title: AppLocalizations.of(context).eventArtAendern,
            height: 180,
            children: [
              eventTypInput,
              Container(
                margin: EdgeInsets.only(right: 10),
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


