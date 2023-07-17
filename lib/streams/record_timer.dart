import 'dart:async';

class RecordTimer{
  int recordTime = 0;
  late Timer timer;

  void start(){
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) => recordTime += 1);
  }

  void stop(){
    timer.cancel();
  }

  void dispose(){
    recordTime = 0;
    timer.cancel();
  }

  stream(){
    return Stream.periodic(
        const Duration(milliseconds: 500), (_) => Duration(milliseconds: recordTime*100));
  }
}