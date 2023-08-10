import 'package:flutter/material.dart';
import '../../global/style.dart' as style;

class CustomDropdownButton extends StatefulWidget {
  List<String> items;
  String hintText;
  String? selected;
  double? width;
  Function? onChange;
  EdgeInsets margin;

  CustomDropdownButton({Key? key,
    required this.items,
    this.hintText = "",
    this.selected = "",
    this.margin = const EdgeInsets.all(10),
    this.onChange,
    this.width
  }) : super(key: key);


  getSelected(){
    return selected;
  }

  @override
  _CustomDropdownButtonState createState() => _CustomDropdownButtonState();
}

class _CustomDropdownButtonState extends State<CustomDropdownButton> {

  createDropdownItems(){
    return widget.items.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? style.webWidth,
      margin: widget.margin,
      padding: const EdgeInsets.only(left: 10, right: 10),
      constraints: const BoxConstraints(
        minHeight: 50.0,
        maxHeight: 70.0,
      ),
      decoration: BoxDecoration(
          border: Border.all(width: 1),
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(style.roundedCorners))
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        icon: Icon(Icons.arrow_downward,color: Colors.black,),
        value: widget.selected == "" ? null : widget.selected,
        hint: Text(widget.hintText, style: const TextStyle(color: Colors.grey)),
        elevation: 16,
        style: const TextStyle(color: Colors.black),
        decoration: const InputDecoration(enabledBorder: InputBorder.none, focusedBorder: InputBorder.none) ,
        onChanged: (newValue){
          setState(() {
            widget.selected = newValue;
          });
          if(widget.onChange != null) widget.onChange!();
        },
        items: createDropdownItems(),
      ),
    );



  }
}
