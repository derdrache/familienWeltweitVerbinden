import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FlexibleDatePicker extends StatefulWidget {
  final int startYear;
  final int endYear;
  int selectedDay, selectedMonth, selectedYear;
  bool withMonth;
  bool withDay;
  bool language;

  FlexibleDatePicker({
    Key key, 
    this.startYear, 
    this.endYear, 
    this.withDay = false, 
    this.withMonth = false,
    this.language
    }) : super(key: key);

  getDate(){
    return DateTime(selectedYear, selectedMonth ?? 1, selectedDay ?? 1, selectedDay != null ? 1 : 0);
  }

  showMore({day = false, month = false}){
    if(day) withDay = true;
    if(month) withMonth = true;
    
  }

  @override
  State<FlexibleDatePicker> createState() => _FlexibleDatePickerState();
}

class _FlexibleDatePickerState extends State<FlexibleDatePicker> {
  final int daysForListdays = 32;

  List listDays;
  List listMonths;
  List listYears;
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

  @override
  Widget build(BuildContext context) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if(widget.withDay) Column(children: [
          Text(AppLocalizations.of(context).tag),
          dateDropDown(listDays, "day"),
        ],),
        if(widget.withMonth) Column(children: [
          Text(AppLocalizations.of(context).monat),
          dateDropDown(listMonths, "month"),
        ],),
        Column(children: [
          Text(AppLocalizations.of(context).jahr),
          dateDropDown(listYears, "year"),
        ],)
        
      ],);
  }

  Widget dateDropDown(items, typ){
    var dropdownValue;
          if(typ == "day"){
            dropdownValue = widget.selectedDay;
          }else if(typ == "month"){
            dropdownValue = widget.selectedMonth;      
          }else if(typ == "year"){
            dropdownValue = widget.selectedYear;
          }


    return DropdownButton(
        value: dropdownValue,
        items: items.map<DropdownMenuItem>((item) {
          var value = item.runtimeType == int ? item : item["id"];
          var text = item.runtimeType == int ? item.toString() : item["value"];
          
          return DropdownMenuItem(
            value: value,
            child: Text(text),
          );
        }).toList(),
        onChanged: (value){
          if(typ == "day"){
            widget.selectedDay = value;
          }else if(typ == "month"){
            widget.selectedMonth = value;      
          }else if(typ == "year"){
            widget.selectedYear = value;
          }
    
          setState(() {});
        }
    );
  }

}
