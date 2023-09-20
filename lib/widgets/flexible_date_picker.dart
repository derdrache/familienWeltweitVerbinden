import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/windows/dialog_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/style.dart' as style;

class FlexibleDatePicker extends StatefulWidget {
  final int? startYear;
  final int? endYear;
  int? selectedDay, selectedMonth, selectedYear;
  int? selectedEndDay, selectedEndMonth, selectedEndYear;
  bool withMonth;
  bool withDay;
  bool multiDate;
  DateTime? selectedDate;
  bool withEndDateSwitch;
  bool inaccurateDate;

  FlexibleDatePicker(
      {Key? key,
      this.startYear,
      this.endYear,
      this.withDay = false,
      this.withMonth = false,
      this.multiDate = false,
      this.selectedDate,
      this.withEndDateSwitch = false,
      this.inaccurateDate = false})
      : super(key: key);

  setDate(DateTime date) {
    selectedDay = date.day;
    selectedMonth = date.month;
    selectedYear = date.year;
    selectedDate = date;
  }

  getDate() {
    if (multiDate) {
      if (selectedYear == null) return null;

      DateTime start = DateTime(selectedYear!, selectedMonth ?? 1,
          selectedDay ?? 1, selectedDay != null ? 1 : 0);
      DateTime end = DateTime(selectedEndYear!, selectedEndMonth ?? 1,
          selectedEndDay ?? 1, selectedDay != null ? 1 : 0);

      return [start, end];
    } else {
      if(selectedDate == null) return;

      selectedYear ??= selectedDate!.year;
      selectedMonth ??= selectedDate!.month;
      selectedDay ??= selectedDate!.day;

      return DateTime(selectedYear!, selectedMonth ?? 1, selectedDay ?? 1,
          selectedDay != null ? 1 : 0);
    }
  }

  clear() {
    selectedDay = null;
    selectedEndDay = null;
    selectedMonth = null;
    selectedEndMonth = null;
    selectedYear = null;
    selectedEndYear = null;
  }

  @override
  State<FlexibleDatePicker> createState() => _FlexibleDatePickerState();
}

class _FlexibleDatePickerState extends State<FlexibleDatePicker> {
  final String defaultLocale = PlatformDispatcher.instance.locale.languageCode;
  final int daysForListdays = 32;
  late List listDays;
  late List listMonths;
  late List listYears;
  late bool withDay;
  late bool withMonth;
  bool withEndDate = true;
  String errorText = "";
  var globalWindowSetState;

  late DateTime selectedEndDate;
  bool moreDateData = false;
  List<dynamic> monthsDE = [
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
  List<dynamic> monthsENG = [
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
    if (widget.selectedDate != null) {
      widget.selectedYear = widget.selectedDate!.year;
      widget.selectedMonth = widget.selectedDate!.month;
      widget.selectedDay = widget.selectedDate!.day;
    }

    withDay = !widget.inaccurateDate;
    withMonth = true;
    listDays = Iterable<int>.generate(daysForListdays).skip(1).toList();
    listMonths = defaultLocale == "de" ? monthsDE : monthsENG;
    listYears =
        Iterable<int>.generate((widget.endYear ?? DateTime.now().year + 10) + 1)
            .skip(widget.startYear ?? DateTime.now().year)
            .toList();

    super.initState();
  }

  save() {
    bool daySelected = widget.selectedDay != null;
    bool monthSelected = widget.selectedMonth != null;
    bool yearSelected = widget.selectedYear != null;
    bool startNormalFilled =
        withDay && daySelected && monthSelected && yearSelected;
    bool startSecretFilled = !withDay &&
        yearSelected &&
        ((widget.withMonth && monthSelected) || !widget.withMonth);

    bool endDaySelected = widget.selectedEndDay != null;
    bool endMonthSelected = widget.selectedEndMonth != null;
    bool endYearSelected = widget.selectedEndYear != null;
    bool endNormalFilled =
        withDay && endDaySelected && endMonthSelected && endYearSelected;
    bool endSecretFilled = !withDay &&
        endYearSelected &&
        ((widget.withMonth && endMonthSelected) || !widget.withMonth);

    if ( !(startNormalFilled || startSecretFilled) ||
        widget.multiDate && !(endNormalFilled || endSecretFilled)){
      showErrorMessage(AppLocalizations.of(context)!.vollesDatumEingeben);
      return false;
    }

    DateTime startDate = DateTime(
        widget.selectedYear!,
        widget.selectedMonth ?? 1,
        widget.selectedDay ?? 1,
        widget.selectedDay != null ? 1 : 0);
    widget.selectedDate = startDate;

    if (widget.multiDate) {
      DateTime endDate = DateTime(
          widget.selectedEndYear!,
          widget.selectedEndMonth ?? 1,
          widget.selectedEndDay ?? 1,
          widget.selectedDay != null ? 1 : 0);

      if (endDate.isBefore(startDate)) {
        showErrorMessage(AppLocalizations.of(context)!.bisDatumFalsch);
        return false;
      }

      selectedEndDate = DateTime(
          widget.selectedEndYear!,
          widget.selectedEndMonth ?? 1,
          widget.selectedEndDay ?? 1,
          widget.selectedDay != null ? 1 : 0);
    }

    return true;
  }

  showErrorMessage(text) {
    globalWindowSetState(() {
      errorText = text;
    });
  }

  reset() {}

  createDateText() {
    if (widget.selectedDate == null) {
      return AppLocalizations.of(context)!.datumEingeben;
    }

    if (!withDay && !widget.withMonth) {
      if (widget.multiDate) {
        return "${widget.selectedDate!.year} - ${selectedEndDate.year}";
      } else {
        return widget.selectedDate!.year.toString();
      }
    } else if (!withDay && widget.withMonth) {
      if (widget.multiDate) {
        return "${widget.selectedDate!.month}.${widget.selectedDate!.year} - ${selectedEndDate.month}.${selectedEndDate.year}";
      } else {
        return "${widget.selectedDate!.month}.${widget.selectedDate!.year}";
      }
    } else {
      if (widget.multiDate) {
        return "${widget.selectedDate!.day}.${widget.selectedDate!.month}.${widget.selectedDate!.year} - ${selectedEndDate.day}.${selectedEndDate.month}.${selectedEndDate.year}";
      } else {
        return "${widget.selectedDate!.day}.${widget.selectedDate!.month}.${widget.selectedDate!.year}";
      }
    }
  }

  showPickerWindow() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, windowSetState) {
            globalWindowSetState = windowSetState;
            return CustomAlertDialog(
              title: "",
              children: [
                datePickerBox(windowSetState, multiDateTitle: "Start"),
                if (widget.multiDate) const SizedBox(height: 15),
                if (widget.multiDate)
                  datePickerBox(windowSetState,
                      endDate: true, multiDateTitle: "End"),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!widget.withDay)
                      Text(AppLocalizations.of(context)!.genauesDatum),
                    if (!widget.withDay)
                      Switch(
                          value: withDay,
                          onChanged: (newValue) {
                            windowSetState(() {
                              withDay = newValue;

                              if (withDay || !widget.withMonth) {
                                withMonth = newValue;
                              }

                              if (!newValue) {
                                widget.selectedDay = null;
                                if (!widget.withMonth) {
                                  widget.selectedMonth = null;
                                }
                              }
                            });
                          }),
                  ],
                ),
                if (widget.withEndDateSwitch)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.zeitraumSuche),
                      Switch(
                          value: withEndDate,
                          onChanged: (newValue) {
                            windowSetState(() {
                              withEndDate = newValue;
                              widget.multiDate = newValue;
                            });
                          }),
                    ],
                  ),
                const SizedBox(height: 10),
                if(errorText.isNotEmpty) Text(errorText, style: const TextStyle(color: Colors.red),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () {
                          reset();
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel")),
                    TextButton(
                        onPressed: () {
                          bool succsess = save();

                          if (succsess) {
                            setState(() {});
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Ok")),
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
        width: widget.multiDate ? 160 : 80,
        height: 50,
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black),
            borderRadius: const BorderRadius.all(Radius.circular(style.roundedCorners))),
        child: Center(
            child: Text(
          createDateText(),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: widget.selectedDate == null? null :FontWeight.bold,
              fontSize: 14,
              color: widget.selectedDate == null  || Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey
                  : Colors.black),
        )),
      ),
    );
  }

  Widget dateDropDown(items, typ, {onClick, endDate = false}) {
    int? dropdownValue;
    if (typ == "day" && !endDate) {
      dropdownValue = widget.selectedDay;
    } else if (typ == "month" && !endDate) {
      dropdownValue = widget.selectedMonth;
    } else if (typ == "year" && !endDate) {
      dropdownValue = widget.selectedYear;
    } else if (typ == "day" && endDate) {
      dropdownValue = widget.selectedEndDay;
    } else if (typ == "month" && endDate) {
      dropdownValue = widget.selectedEndMonth;
    } else if (typ == "year" && endDate) {
      dropdownValue = widget.selectedEndYear;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 5),
      child: Container(
        padding: const EdgeInsets.only(left: 20, right: 5, top: 5, bottom: 5),
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(5),
        ),
        child: DropdownButton(
          value: dropdownValue,
          items: items.map<DropdownMenuItem<int>>((item) {
            var value = item.runtimeType == int ? item : item["id"];
            var text =
                item.runtimeType == int ? item.toString() : item["value"];

            return DropdownMenuItem<int>(
              value: value,
              child: Text(text),
            );
          }).toList(),
          onChanged: (value) {
            if (typ == "day" && !endDate) {
              widget.selectedDay = value as int?;
            } else if (typ == "month" && !endDate) {
              widget.selectedMonth = value as int?;
            } else if (typ == "year" && !endDate) {
              widget.selectedYear = value as int?;
            } else if (typ == "day" && endDate) {
              widget.selectedEndDay = value as int?;
            } else if (typ == "month" && endDate) {
              widget.selectedEndMonth = value as int?;
            } else if (typ == "year" && endDate) {
              widget.selectedEndYear = value as int?;
            }

            onClick();
          },
          icon: const Icon(Icons.calendar_month),
          underline: Container(),
        ),
      ),
    );
  }

  Widget multiDateTitleBox(text) {
    return Container(
      width: 50,
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const Text(""), Text(text)],
      ),
    );
  }

  Widget datePickerBox(windowSetState, {endDate = false, multiDateTitle = ""}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.multiDate) multiDateTitleBox(multiDateTitle),
        if (withDay)
          Column(
            children: [
              if (!endDate) Text(AppLocalizations.of(context)!.tag),
              dateDropDown(listDays, "day",
                  endDate: endDate, onClick: () => windowSetState(() {})),
            ],
          ),
        if (withMonth)
          Column(
            children: [
              if (!endDate) Text(AppLocalizations.of(context)!.monat),
              dateDropDown(listMonths, "month",
                  endDate: endDate, onClick: () => windowSetState(() {})),
            ],
          ),
        Column(
          children: [
            if (!endDate) Text(AppLocalizations.of(context)!.jahr),
            dateDropDown(listYears, "year",
                endDate: endDate, onClick: () => windowSetState(() {})),
          ],
        )
      ],
    );
  }
}
