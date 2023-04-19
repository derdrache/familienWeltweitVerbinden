import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class FlexibleDatePicker extends StatefulWidget {
  final int startYear;
  final int endYear;
  int selectedDay, selectedMonth, selectedYear;
  bool withMonth;
  bool withDay;
  bool language;
  String hintText;

  FlexibleDatePicker(
      {Key key,
      this.startYear,
      this.endYear,
      this.withDay = false,
      this.withMonth = false,
      this.language,
      this.hintText = ""})
      : super(key: key);

  getDate() {
    return DateTime(selectedYear, selectedMonth ?? 1, selectedDay ?? 1,
        selectedDay != null ? 1 : 0);
  }

  @override
  State<FlexibleDatePicker> createState() => _FlexibleDatePickerState();
}

class _FlexibleDatePickerState extends State<FlexibleDatePicker> {
  final int daysForListdays = 32;
  List listDays;
  List listMonths;
  List listYears;
  bool withDay;
  bool withMonth;
  DateTime selectedDate;
  bool moreDateData = false;
  List<dynamic> listMonths_de = [
    {"id": 1, "value": "Januar"},
    {"id": 2, "value": "Februar"},
    {"id": 3, "value": "März"},
    {"id": 4, "value": "April"},
    {"id": 5, "value": "Mai"},
    {"id": 6, "value": "Juni"},
    {"id": 7, "value": "Juli"},
    {"id": 8, "value": "August"},
    {"id": 9, "value": "September"},
    {"id": 10, "value": "Oktober"},
    {"id": 11, "value": "November"},
    {"id": 12, "value": "Dezember"}
  ];
  List<dynamic> listMonths_en = [
    {"id": 1, "value": "January"},
    {"id": 2, "value": "February"},
    {"id": 3, "value": "March"},
    {"id": 4, "value": "April"},
    {"id": 5, "value": "May"},
    {"id": 6, "value": "June"},
    {"id": 7, "value": "July"},
    {"id": 8, "value": "August"},
    {"id": 9, "value": "September"},
    {"id": 10, "value": "October"},
    {"id": 11, "value": "November"},
    {"id": 12, "value": "December"}
  ];

  @override
  void initState() {
    withDay = true;
    withMonth = true;
    listDays = Iterable<int>.generate(daysForListdays).skip(1).toList();
    listMonths = widget.language == "deutsch" ? listMonths_de : listMonths_en;
    listYears =
        Iterable<int>.generate((widget.endYear ?? DateTime.now().year) + 1)
            .skip(widget.startYear ?? DateTime.now().year)
            .toList()
            .reversed
            .toList();

    super.initState();
  }

  save() {
    bool daySelected = widget.selectedDay != null;
    bool monthSelected = widget.selectedMonth != null;
    bool yearSelected = widget.selectedYear != null;

    bool allFilledAll = withDay && daySelected && monthSelected && yearSelected;
    bool allFilledPart = !withDay && yearSelected && ((widget.withMonth && monthSelected) || !widget.withMonth);

    if (!allFilledAll && !allFilledPart) {
      return;
    }

    setState(() {
      selectedDate = DateTime(widget.selectedYear, widget.selectedMonth ?? 1,
          widget.selectedDay ?? 1, widget.selectedDay != null ? 1 : 0);
    });
  }

  reset() {}

  createDateText() {
    if (selectedDate == null) return widget.hintText;

    if(!withDay && !widget.withMonth) return selectedDate.year.toString();
    if(!withDay && widget.withMonth) return selectedDate.day.toString() + "." +selectedDate.month.toString();

    return selectedDate.day.toString() +
        "." +
        selectedDate.month.toString() +
        "." +
        selectedDate.year.toString();
  }

  showPickerWindow() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, windowSetState) {
            return CustomAlertDialog(
              title: "",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (withDay)
                      Column(
                        children: [
                          Text("Tag"), //AppLocalizations.of(context).tag),
                          dateDropDown(listDays, "day",
                              onClick: () => windowSetState(() {})),
                        ],
                      ),
                    if (withMonth)
                      Column(
                        children: [
                          Text("Monat"), //AppLocalizations.of(context).monat),
                          dateDropDown(listMonths, "month",
                              onClick: () => windowSetState(() {})),
                        ],
                      ),
                    Column(
                      children: [
                        Text("Jahr"), //AppLocalizations.of(context).jahr),
                        dateDropDown(listYears, "year",
                            onClick: () => windowSetState(() {})),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!widget.withDay)
                      Text("Genaues Datum"), //AppLocalizations.of(context).genauesDatum
                    if (!widget.withDay)
                      Switch(
                          value: withDay,
                          onChanged: (newValue) {
                            windowSetState(() {
                              withDay = newValue;

                              if (withDay || !widget.withMonth)
                                withMonth = newValue;

                              if(!newValue){
                                widget.selectedDay = null;
                                if(!widget.withMonth) widget.selectedMonth = null;
                              }
                            });
                          })
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () {
                          reset();
                          Navigator.pop(context);
                        },
                        child: Text("Cancel")),
                    TextButton(
                        onPressed: () {
                          save();
                          Navigator.pop(context);
                        },
                        child: Text("Ok")),
                  ],
                )
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showPickerWindow(),
      child: Container(
        width: 80,
        height: 50,
        decoration: BoxDecoration(border: Border.all()),
        child: Center(
            child: Text(
          createDateText(),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selectedDate == null ? Colors.grey : Colors.black),
        )),
      ),
    );
  }

  Widget dateDropDown(items, typ, {onClick}) {
    var dropdownValue;
    if (typ == "day") {
      dropdownValue = widget.selectedDay;
    } else if (typ == "month") {
      dropdownValue = widget.selectedMonth;
    } else if (typ == "year") {
      dropdownValue = widget.selectedYear;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
      child: Container(
        padding: EdgeInsets.only(left: 20, right: 5, top: 5, bottom: 5),
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(5),
        ),
        child: DropdownButton(
            value: dropdownValue,
            items: items.map<DropdownMenuItem>((item) {
              var value = item.runtimeType == int ? item : item["id"];
              var text =
                  item.runtimeType == int ? item.toString() : item["value"];
      
              return DropdownMenuItem(
                value: value,
                child: Text(text),
              );
            }).toList(),
            onChanged: (value) {
              if (typ == "day") {
                widget.selectedDay = value;
              } else if (typ == "month") {
                widget.selectedMonth = value;
              } else if (typ == "year") {
                widget.selectedYear = value;
              }
      
              onClick();
            },
            icon: Icon(Icons.calendar_month),
            underline: Container(),
          ),
      ),
    );
  }
}
