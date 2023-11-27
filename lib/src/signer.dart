import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

class SignerHelper {
  static bool needSigner(String privkey) {
    return privkey.isEmpty || privkey.startsWith('signer');
  }

  static Future<Event> signEvent(Event event) async {
    final eventString = jsonEncode(event.toJson());
    //todo:
    return event;
  }

  static Future<String> encryptNip04(
      String plainText, String peerPubkey, String myPubkey) async {
    //todo:
    return plainText;
  }

  static Future<String> decryptNip04(
      String encryptedText, String peerPubkey, String myPubkey) async {
    //todo:
    return encryptedText;
  }

  static Future<String> encryptNip44(
      String plainText, String peerPubkey, String myPubkey) async {
    //todo:
    return plainText;
  }

  static Future<String> decryptNip44(
      String encryptedText, String peerPubkey, String myPubkey) async {
    //todo:
    return encryptedText;
  }
}
