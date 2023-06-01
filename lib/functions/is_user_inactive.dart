import '../global/variablen.dart';

isUserInactive(profilData){
  if(profilData == null) return;

  var timeDifferenceLastLogin = Duration(
      microseconds: (DateTime.now().microsecondsSinceEpoch -
          DateTime.parse(profilData["lastLogin"].toString())
              .microsecondsSinceEpoch)
          .abs());
  var monthDifference = timeDifferenceLastLogin.inDays / 30.44;

  return monthDifference >= monthsUntilInactive;
}