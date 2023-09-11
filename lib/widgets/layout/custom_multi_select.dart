import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../global/style.dart' as style;



class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  List? selected;
  String hintText;
  Function? onConfirm;
  EdgeInsets? margin;

  getSelected(){
    return selected;
  }


  CustomMultiTextForm({Key? key,
    required this.auswahlList,
    this.selected,
    this.hintText = "",
    this.onConfirm,
    this.margin
  }) : super(key: key);

  @override
  State<CustomMultiTextForm> createState() => _CustomMultiTextFormState();
}

class _CustomMultiTextFormState extends State<CustomMultiTextForm> {

  @override
  void initState() {
    widget.onConfirm ??= (){};
    widget.selected ??= [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    changeSelectToList(select){
      widget.selected = select;
      if(select.isNotEmpty) widget.onConfirm!();
      setState(() {});
    }

    return Container(
      width: style.webWidth,
      margin: widget.margin ?? EdgeInsets.all(style.sideSpace),
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black),
          borderRadius: BorderRadius.circular(style.roundedCorners)
      ),
      child: MultiSelectDialogField(
        decoration: const BoxDecoration(),
        initialValue: widget.selected!,
        buttonIcon: Icon(Icons.arrow_downward, color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black),
        items: widget.auswahlList.map((e) => MultiSelectItem(e, e)).toList(),
        listType: MultiSelectListType.LIST,
        searchable: true,
        onConfirm: changeSelectToList,
        onSelectionChanged: changeSelectToList,
        buttonText: Text(widget.hintText, style: const TextStyle(color: Colors.grey),),
        chipDisplay: MultiSelectChipDisplay(
          onTap: (value){
            setState(() {});
            widget.selected!.remove(value);
            widget.onConfirm!();
            return widget.selected;
          },
        ),
      ),
    );
  }
}