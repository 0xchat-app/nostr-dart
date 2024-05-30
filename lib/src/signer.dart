import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

class SignerHelper {
  static bool needSigner(String privkey) {
    return privkey.isEmpty || privkey.startsWith('signer');
  }

  static Future<String?> signMessage(String hexMessage, String currentUser) async {
    Map<String, String>? map = await ExternalSignerTool.signMessage(hexMessage, hexMessage,
         Nip19.encodePubkey(currentUser));
    String? sign = map?['signature'];
    return sign;
  }

  static Future<Event> signEvent(Event event, String currentUser) async {
    final eventString = jsonEncode(event.toJson());
    Map<String, String>? map = await ExternalSignerTool.signEvent(
        eventString, event.id, Nip19.encodePubkey(currentUser));
    String? eventJson = map?['event'];
    if (eventJson != null) {
      event = await Event.fromJson(jsonDecode(eventJson));
    }
    return event;
  }

  static Future<String> encryptNip04(
      String plainText, String peerPubkey, String myPubkey) async {
    Map<String, String>? map = await ExternalSignerTool.nip04Encrypt(plainText,
        generate64RandomHexChars(), Nip19.encodePubkey(myPubkey), peerPubkey);
    String? encryptedText = map?['signature'];
    if (encryptedText != null) {
      plainText = encryptedText;
    }
    return plainText;
  }

  static Future<String> decryptNip04(
      String encryptedText, String peerPubkey, String myPubkey) async {
    // print('decryptNip04 content = $encryptedText');
    Map<String, String>? map = await ExternalSignerTool.nip04Decrypt(
        encryptedText,
        generate64RandomHexChars(),
        Nip19.encodePubkey(myPubkey),
        peerPubkey);
    String? plainText = map?['signature'];
    if (plainText != null) {
      encryptedText = plainText;
    }
    return encryptedText;
  }

  static Future<String> encryptNip44(
      String plainText, String peerPubkey, String myPubkey) async {
    Map<String, String>? map = await ExternalSignerTool.nip44Encrypt(plainText,
        generate64RandomHexChars(), Nip19.encodePubkey(myPubkey), peerPubkey);
    String? encryptedText = map?['signature'];
    if (encryptedText != null) {
      plainText = encryptedText;
    }
    return plainText;
  }

  static Future<String> decryptNip44(
      String encryptedText, String peerPubkey, String myPubkey) async {
    Map<String, String>? map = await ExternalSignerTool.nip44Decrypt(
        encryptedText,
        generate64RandomHexChars(),
        Nip19.encodePubkey(myPubkey),
        peerPubkey);
    String? plainText = map?['signature'];
    if (plainText != null) {
      encryptedText = plainText;
    }
    return encryptedText;
  }
}
