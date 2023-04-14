import 'package:flutter/material.dart';

class FlexibleDatePicker extends StatefulWidget {
  final int startYear;
  final int endYear;

  const FlexibleDatePicker({Key key, this.startYear, this.endYear}) : super(key: key);

  @override
  State<FlexibleDatePicker> createState() => _FlexibleDatePickerState();
}

class _FlexibleDatePickerState extends State<FlexibleDatePicker> {
  final int daysForListdays = 32;
  List listDays;
  List listMonths;
  List listYears;
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
    listMonths = listMonths_en;
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
        dateDropDown(listDays),
      ],);
  }

  Widget dateDropDown(items){
    return DropdownButton(
        items: items.map<DropdownMenuItem>((items) {
          return DropdownMenuItem(
            value: items,
            child: Text(items.toString()),
          );
        }).toList(),
        onChanged: (value){}
    );
  }
}
