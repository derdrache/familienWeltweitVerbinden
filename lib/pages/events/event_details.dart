import 'package:familien_suche/global/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../global/google_autocomplete.dart';
import '../../services/database.dart';
import '../../global/style.dart' as global_style;
import '../../global/variablen.dart' as global_var;

var userId = FirebaseAuth.instance.currentUser.uid;
double fontsize = 16;

class EventDetailsPage extends StatelessWidget {
  var event;
  var offlineEvent;
  var isCreator;

  EventDetailsPage({
    Key key,
    this.event,
    this.offlineEvent = true
  }) :
        isCreator = event["erstelltVon"] == userId;


  @override
  Widget build(BuildContext context) {

    bildAndTitleBox(){
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Stack(
            children: [
              Image.asset(event["bild"]),
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
                        windowTitle: "Event Name ändern",
                        rowData: event["name"],
                        inputHintText: "Event Name eingeben",
                        isCreator: isCreator,
                        modus: "textInput",
                        singleShow: true,
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
              windowTitle: "Datum ändern",
              rowTitle: "Datum",
              rowData: event["wann"].split(" ")[0].split("-").reversed.join("."),
              inputHintText: "Neues Datum eingeben",
              isCreator: isCreator,
              modus: "date",
            ),
            const SizedBox(height: 10),
            ShowDataAndChangeWindow(
                windowTitle: "Uhrzeit ändern",
                rowTitle: "Uhrzeit",
                rowData: event["wann"].split(" ")[1].split(":").take(2).join(":") + " Uhr",
                inputHintText: "Neue Uhrzeit eingeben",
                isCreator: isCreator,
                modus: "uhrzeit",
            ),
            const SizedBox(height: 10),
            ShowDataAndChangeWindow(
              windowTitle: "Stadt verändern",
              rowTitle: "Ort",
              rowData: event["stadt"] + ", " + event["land"],
              inputHintText: "Neue Stadt eingeben",
              isCreator: isCreator,
              modus: "googleAutoComplete"
            ),
            const SizedBox(height: 10),
            ShowDataAndChangeWindow(
              windowTitle: "Map Link verändern",
              rowTitle: "Map",
              rowData: event["link"],
              inputHintText: "Karten Link eingeben",
              isCreator: isCreator,
              modus: "textInput",
            ),
            const SizedBox(height: 10),
            ShowDataAndChangeWindow(
              windowTitle: "Event Art ändern",
              isCreator: isCreator,
              rowTitle: "Art",
              rowData: event["art"],
              inputHintText: "Öffentliches oder Privates Event ?",
              items: global_var.eventArt,
              modus: "dropdown"
            ),
            const SizedBox(height: 10),
            ShowDataAndChangeWindow(
              windowTitle: "Event Wiederholung ändern",
              isCreator: isCreator,
              rowTitle: "Häufigkeit",
              rowData: event["eventInterval"],
              inputHintText: "Einmalig oder regelmäßig ?",
              items: global_var.eventInterval,
              modus: "dropdown"
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
                  minHeight: 100.0,
                ),
                child: ShowDataAndChangeWindow(
                  windowTitle: "Event Beschreibung ändern",
                  rowData: event["beschreibung"],
                  inputHintText: "Event Beschreibung eingeben",
                  isCreator: isCreator,
                  modus: "textInput",
                  multiLines: true,
                ),
              )
          )
      );
    }

    creatorChngeHintBox(){
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


    return Scaffold(
      appBar: customAppBar(
        title: "",
        buttons: [
          TextButton(
            style: global_style.textButtonStyle(),
            child: const Icon(Icons.message),
            onPressed: () => print("message"),
          ),
          TextButton(
            style: global_style.textButtonStyle(),
            child: const Icon(Icons.more_vert),
            onPressed: () => print("more"),
          ),

        ]
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  bildAndTitleBox(),
                  const SizedBox(height: 20),
                  creatorChngeHintBox(),
                  eventInformationBox(),
                  eventBeschreibung()
                ],
              ),
            ),
          ],

        )
      ),
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
        onTap: (){
          hasIntereset = hasIntereset ? false : true;

          if(hasIntereset){
            widget.interesse.add(userId);
          } else{
            widget.interesse.remove(userId);
          }

          EventDatabase().updateOne(widget.id, "interesse", widget.interesse);

          setState(() {

          });
        },
        child: Icon(Icons.favorite, color: hasIntereset ? Colors.red : Colors.black, size: 30,)
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

  ShowDataAndChangeWindow({
    this.windowTitle,
    this.isCreator,
    this.rowTitle,
    this.rowData,
    this.inputHintText,
    this.items,
    this.modus,
    this.singleShow = false,
    this.multiLines = false
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
    dropdownInput = CustomDropDownButton(
      hintText: widget.inputHintText,
      items: widget.items,
    );

    ortAuswahlBox.hintText = widget.inputHintText;

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    inputBox(){
      if(widget.modus == "textInput"){
        return customTextInput(widget.inputHintText, inputKontroller, moreLines: widget.multiLines? 6: 1);
      }
      if(widget.modus == "dropdown") return dropdownInput;
      if(widget.modus == "googleAutoComplete") return ortAuswahlBox;
      if(widget.modus == "uhrzeit") return uhrZeitButton;
      if(widget.modus == "date") return datumButton;
    }

    return InkWell(
      onTap: !widget.isCreator ? null:  (){
        CustomWindow(
            context: context,
            title: widget.windowTitle,
            height: widget.multiLines? 270 : 180,
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
                          onPressed: () => print("Database")
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


class DateButton extends StatefulWidget {
  var uhrZeit;
  var eventDatum;
  var getDate;

  DateButton({Key key, this.getDate = false}) : super(key: key);

  getData(){
    if(getDate) return uhrZeit;

    return eventDatum;
  }

  @override
  _DateButtonState createState() => _DateButtonState();
}

class _DateButtonState extends State<DateButton> {

  dateBox(){
    var dateString = "Datum auswählen";
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
      child: Text(widget.uhrZeit == null ? "Uhrzeit auswählen" : widget.uhrZeit.format(context)),
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

