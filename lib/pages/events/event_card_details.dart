import 'package:familien_suche/pages/show_profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                          windowTitle: "Event Name ändern",
                          rowData: event["name"],
                          inputHintText: "Event Name eingeben",
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
                windowTitle: "Datum ändern",
                rowTitle: "Datum",
                rowData: event["wann"].split(" ")[0].split("-").reversed.join("."),
                inputHintText: "Neues Datum eingeben",
                isCreator: isCreator,
                modus: "date",
                oldDate: event["wann"],
                databaseKennzeichnung: "wann"
            ),
            const SizedBox(height: 10),
            if(isApproved|| event["art"] == "Öffentlich") ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: "Uhrzeit ändern",
                rowTitle: "Uhrzeit",
                rowData: event["wann"].split(" ")[1].split(":").take(2).join(":") + " Uhr",
                inputHintText: "Neue Uhrzeit eingeben",
                isCreator: isCreator,
                modus: "dateTime",
                oldDate: event["wann"],
                databaseKennzeichnung: "wann"
            ),
            if(isApproved|| event["art"] == "Öffentlich") const SizedBox(height: 10),
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: "Stadt verändern",
                rowTitle: "Ort",
                rowData: event["stadt"] + ", " + event["land"],
                inputHintText: "Neue Stadt eingeben",
                isCreator: isCreator,
                modus: "googleAutoComplete",
                databaseKennzeichnung: "location"
            ),
            const SizedBox(height: 10),
            if(isApproved|| event["art"] == "Öffentlich") ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: "Map Link verändern",
                rowTitle: "Map",
                rowData: event["link"],
                inputHintText: "Karten Link eingeben",
                isCreator: isCreator,
                modus: "textInput",
                databaseKennzeichnung: "link"
            ),
            if(isApproved|| event["art"] == "Öffentlich") const SizedBox(height: 10),
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: "Event Art ändern",
                isCreator: isCreator,
                rowTitle: "Art",
                rowData: event["art"],
                inputHintText: "Öffentliches oder Privates Event ?",
                items: global_var.eventArt,
                modus: "dropdown",
                databaseKennzeichnung: "art"
            ),
            const SizedBox(height: 10),
            ShowDataAndChangeWindow(
                eventId: event["id"],
                windowTitle: "Event Wiederholung ändern",
                isCreator: isCreator,
                rowTitle: "Häufigkeit",
                rowData: event["eventInterval"],
                inputHintText: "Einmalig oder regelmäßig ?",
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
                    windowTitle: "Event Beschreibung ändern",
                    rowData: event["beschreibung"],
                    inputHintText: "Event Beschreibung eingeben",
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
        return const Center(
          child: Text(
              "Antippen, um Einträge zu ändern",
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
            width: isWebDesktop ? 300 : 350,
            height: isWebDesktop ? 450: 500,
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
                if(isApproved || event["art"] == "Öffentlich") eventBeschreibung(),
                OrganisatorBox(organisator: event["erstelltVon"],)
              ],
            ),
          ),
          if(!isApproved && event["art"] != "Öffentlich") Container(
            width: isWebDesktop ? 300 : 350,
            height: isWebDesktop ? 450 : 500,
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
                      customSnackbar(context, "Der Organisator muss dich noch freischalten");
                      return;
                    } else{
                      var freischaltenList = await EventDatabase().getOneData("freischalten", event["id"]);
                      freischaltenList.add(userId);
                      EventDatabase().updateOne(event["id"], "freischalten", freischaltenList);
                      customSnackbar(context,
                          "Dein Interesse am Event wurde dem Organisator mitgeteilt",
                          color: Colors.green);
                    }
                  } ,
                  child: Icon(Icons.add_circle, size: 80, color: Colors.black,)
                ),
                Text(""),
                SizedBox(height: 40,)
              ],
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
                          child: Text("Abbrechen", style: TextStyle(fontSize: fontsize)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                            child: Text("Speichern", style: TextStyle(fontSize: fontsize)),
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
            title: "Event Bild ändern",
            height: 180,
            children: [
              dropdownInput,
              Container(
                margin: EdgeInsets.only(right: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text("Abbrechen", style: TextStyle(fontSize: fontsize)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                          child: Text("Speichern", style: TextStyle(fontSize: fontsize)),
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
    var dateString = "Neues Datum auswählen";
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
      child: Text(widget.uhrZeit == null ? "Neue Uhrzeit auswählen" : widget.uhrZeit.format(context)),
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

