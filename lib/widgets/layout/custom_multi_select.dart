import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../global/style.dart' as style;

class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  List? selected;
  String hintText;
  Function? onConfirm;
  var validator;

  getSelected(){
    return selected;
  }


  CustomMultiTextForm({Key? key,
    required this.auswahlList,
    this.selected,
    this.hintText = "",
    this.onConfirm,
    this.validator
  }) : super(key: key);

  @override
  _CustomMultiTextFormState createState() => _CustomMultiTextFormState();
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
    }

    return Container(
      width: style.webWidth,
      margin: EdgeInsets.all(style.sideSpace),
      decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(5)
      ),
      child: MultiSelectDialogField(
        initialValue: widget.selected!,
        items: widget.auswahlList.map((e) => MultiSelectItem(e, e)).toList(),
        listType: MultiSelectListType.LIST,
        searchable: true,
        onConfirm: changeSelectToList,
        onSelectionChanged: changeSelectToList,
        buttonText: Text(widget.hintText),
        chipDisplay: MultiSelectChipDisplay(
          onTap: (value){
            widget.selected!.remove(value);
            if(widget.selected!.length > 1) widget.onConfirm!();
            return widget.selected;
          },
        ),
      ),
    );
  }
}