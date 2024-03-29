import '../global/variablen.dart';

isUserInactive(profilData){

  if(profilData == null || profilData.isEmpty) return;

  profilData["lastLogin"] ??= DateTime.parse("2022-02-13");

  var timeDifferenceLastLogin = Duration(
      microseconds: (DateTime.now().microsecondsSinceEpoch -
          DateTime.parse(profilData["lastLogin"].toString())
              .microsecondsSinceEpoch)
          .abs());
  var monthDifference = timeDifferenceLastLogin.inDays / 30.44;

  return monthDifference >= monthsUntilInactive;
}