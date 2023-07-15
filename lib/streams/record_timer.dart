import 'dart:async';

import 'package:flutter/material.dart';


class RecordTimer{
  double recordTime = 0;
  var timer;

  void start(){
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) => recordTime += 1);
  }

  void stop(){

  }

  void dispose(){

  }

  stream(){
    return Stream.periodic(const Duration(
        milliseconds: 100), (recordTime) => recordTime);
  }
}