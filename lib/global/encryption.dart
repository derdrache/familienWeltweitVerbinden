import 'package:encrypt/encrypt.dart';
import '../auth/secrets.dart';

decrypt(String encrypted) {
  final key = Key.fromUtf8(phpCryptoKey);
  final iv = IV.fromUtf8(phpCryptoIV);

  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  Encrypted enBase64 = Encrypted.from64(encrypted);
  final decrypted = encrypter.decrypt(enBase64, iv: iv);
  return decrypted;
}


encrypt(String decrypted){
  final key = Key.fromUtf8(phpCryptoKey);
  final iv = IV.fromUtf8(phpCryptoIV);

  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

  Encrypted encryptedData = encrypter.encrypt(decrypted, iv: iv);
  return encryptedData.base64;

}