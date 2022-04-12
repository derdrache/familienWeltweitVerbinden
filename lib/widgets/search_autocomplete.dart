import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../global/variablen.dart' as global_var;


class SearchAutocomplete extends StatefulWidget {
  List searchableItems = [];
  var filterList = [];
  var onConfirm;
  var onDelete;
  List autoCompleteItems = [];
  var isDense = false;
  var searchKontroller;
  bool isSearching = false;
  bool withFilter;
  String hintText;
  var sessionToken = Uuid().v4();

  SearchAutocomplete({Key key,
    this.searchableItems,
    this.onConfirm,
    this.onDelete,
    this.withFilter = true,
    this.hintText = "Filter",
    this.searchKontroller
  }) : isDense = !withFilter;


  getSelected(){
    return filterList;
  }


  @override
  _SearchAutocompleteState createState() => _SearchAutocompleteState();
}

class _SearchAutocompleteState extends State<SearchAutocomplete> {
  double dropdownExtraBoxHeight = 55;

  @override
  void initState() {
    widget.searchKontroller ??= TextEditingController();
    super.initState();
  }


  showAutoComplete(text){
    if(text.length == 0) {
      widget.isSearching = false;
    } else{
      widget.isSearching = true;
    }

    setState(() {});

  }

  addAutoCompleteItems(text){
    widget.autoCompleteItems = [];
    if(text.isEmpty) return widget.autoCompleteItems;

    for(var item in widget.searchableItems){
      if(item.toLowerCase().contains(text.toLowerCase())) widget.autoCompleteItems.add(item);
    }
  }

  deleteFilterItem(item){
    widget.filterList.remove(item);

    if(widget.filterList.isEmpty) widget.isDense = false;

    setState(() {});
  }

  addFilterItem(item){
    if(widget.filterList.length == 3) return ;

    if (!widget.filterList.contains(item)){
      widget.filterList.add(item);
      if(widget.withFilter) widget.isDense = true;
    }
  }

  resetSearchBar(){
    widget.isSearching = false;
    widget.autoCompleteItems = [];
    FocusScope.of(context).unfocus();

    setState(() {

    });
  }


  @override
  Widget build(BuildContext context) {

    double dropdownItemSumHeight = widget.autoCompleteItems.length *38.0;
    if(widget.autoCompleteItems.length * 38 > 160) dropdownItemSumHeight = widget.withFilter? 160 : 152;

    dropDownItem(item){
      return GestureDetector(
        onTap: widget.onConfirm,
        onTapUp: (details) async {
            addFilterItem(item);
            resetSearchBar();
        },
        child: Container(
          padding: EdgeInsets.all(10),
          height: 40,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: global_var.borderColorGrey))
          ),
          child: Text(item)
        ),
      );
    }

    autoCompleteDropdownBox(){
      List<Widget> autoCompleteList = [];

      for(var item in widget.autoCompleteItems){
        autoCompleteList.add( dropDownItem(item));
      }

      return Container(
          height: dropdownItemSumHeight,
          margin: EdgeInsets.only(top: (widget.isDense && widget.withFilter)? 25: 0),
          child: ListView(
            padding: EdgeInsets.only(top: widget.withFilter? 0: 5),
            children: autoCompleteList,
          ),
      );
    }

    createFilterBox(){
      List<Widget> boxList = [];

      for(var item in widget.filterList){
        boxList.add(GestureDetector(
          onTap: widget.onDelete,
          onTapUp: (_) => deleteFilterItem(item),
          child: Container(
            padding: EdgeInsets.all(2),
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              border: Border.all(),
              borderRadius: BorderRadius.circular(10)
            ),
            child: Text(
              item,
              style: TextStyle(fontSize: 12),
            )
          ),
        ));
      }

      return Row(
          children: boxList,
        );
    }

    return Container(
      width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          border: Border.all()
        ),
        height:  dropdownExtraBoxHeight + dropdownItemSumHeight,
        margin: EdgeInsets.all(5),
        child:Stack(
          clipBehavior: Clip.none, children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.top,
                    controller: widget.searchKontroller,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(top: widget.withFilter? widget.isDense? 9 : 0 : 15),
                      isDense: widget.isDense,
                      border: InputBorder.none,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey)
                    ),
                    style: const TextStyle(),
                    onChanged: (value) async {
                      showAutoComplete(value);
                      addAutoCompleteItems(value);

                      setState(() {});
                    }
                  ),
                ),
                if(widget.isSearching) autoCompleteDropdownBox()

              ],
            ),
            if(widget.isDense && widget.withFilter) Positioned(
              top: 30,
              child: createFilterBox()
            ),
            Positioned(
              right: 15,
              top: 12,
              child: GestureDetector(
                onTap: null,
                child: Icon(Icons.search, size: 25,)
              )
            ),
          ],
        ),
    );
  }
}