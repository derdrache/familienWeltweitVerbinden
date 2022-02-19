import 'package:flutter/material.dart';
import 'variablen.dart' as global_var;


class SearchAutocomplete extends StatefulWidget {
  List searchableItems;
  var filterList = [];
  var onConfirm;
  var onDelete;
  List autoCompleteItems = [];
  var isDense = false;
  var searchKontroller = TextEditingController();
  bool isSearching = false;

  getSelected(){
    return filterList;
  }



  SearchAutocomplete({Key? key,
    required this.searchableItems,
    this.onConfirm,
    this.onDelete
  }) : super(key: key);

  @override
  _SearchAutocompleteState createState() => _SearchAutocompleteState();
}

class _SearchAutocompleteState extends State<SearchAutocomplete> {



  double dropdownExtraBoxHeight = 55;




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
      if(item.toLowerCase().contains(text)) widget.autoCompleteItems.add(item);
    }

    setState(() {});
  }

  deleteFilterItem(item){
    widget.filterList.remove(item);

    if(widget.filterList.isEmpty) widget.isDense = false;

    setState(() {});
  }

  addFilterItem(item){
    widget.filterList.add(item);
    widget.isDense = true;
    widget.searchKontroller.text = "";
    widget.isSearching = false;
    widget.autoCompleteItems = [];

    setState(() {

    });

  }

  @override
  Widget build(BuildContext context) {
    double dropdownItemSumHeight = widget.autoCompleteItems.length *40 ;
    if(widget.autoCompleteItems.length *40 > 160) dropdownItemSumHeight = 160;

    dropDownItem(item){
      return GestureDetector(
        onTap: widget.onConfirm,
        onTapUp: (details) => addFilterItem(item) ,
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
        autoCompleteList.add( dropDownItem(item) );
      }

      return Container(
          height: dropdownItemSumHeight,
          child: ListView(
          padding: EdgeInsets.only(top: widget.isDense? 25 : 0),
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
              color: Theme.of(context).colorScheme.tertiary,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(7)),
        border: Border.all()
      ),
      height:  dropdownExtraBoxHeight + dropdownItemSumHeight,
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.only(left: 5),
      child:Stack(
        overflow: Overflow.visible,
        children: [
          Column(
            children: [
              TextField(
                textAlignVertical: TextAlignVertical.top,
                controller: widget.searchKontroller,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top:5),
                  isDense: widget.isDense,
                  border: InputBorder.none,
                  hintText: 'Search',
                ),
                style: TextStyle(
                ),
                onChanged: (value) {
                  showAutoComplete(value);
                  addAutoCompleteItems(value);
                },
            ),
              if(widget.isSearching) autoCompleteDropdownBox()

            ],
          ),
          if(widget.isDense) Positioned(
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
