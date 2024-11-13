import 'package:flutter/material.dart';

class DaySelectionWidget extends StatefulWidget {
  List<String> dayList;
  List<bool> daySelection = [false, false, false, false, false, false, false];

  DaySelectionWidget({
    required this.dayList,
    super.key});

  getSelection(){
    var selection = [];

    for(var i = 0; i < daySelection.length; i++){
      if(daySelection[i]) selection.add(i);
    }

    return selection.join(",");
  }

  @override
  State<DaySelectionWidget> createState() => _daySelectionState();
}

class _daySelectionState extends State<DaySelectionWidget> {


  dayChip(int workdayIndex){

    return ChoiceChip(
      label: Text(widget.dayList[workdayIndex]),
      selected: widget.daySelection[workdayIndex],
      selectedColor: Colors.green,
      onSelected: (bool) {
        setState(() {
          widget.daySelection[workdayIndex] = bool;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 10,
        children: [
          dayChip(0),
          dayChip(1),
          dayChip(2),
          dayChip(3),
          dayChip(4),
          dayChip(5),
          dayChip(6),
        ],),
    );
  }
}
