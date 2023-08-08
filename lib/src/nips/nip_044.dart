import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:kepler/kepler.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Encrypted Direct Message
/// https://github.com/vitorpamplona/nips/blob/sealed-dms/24.md
/// {
///   "ciphertext": "<Base64-encoded ByteArray>"
///   "nonce": "<Base64-encoded Nonce>"
///   "v": <Version Code>
/// }
class Nip44 {
  /// Returns the EDMessage Encrypted Direct Message event (kind=44)
  static Future<EDMessage> decode(Event event, String pubkey, String privkey) async {
    if (event.kind == 44) {
      return await _toEDMessage(event, pubkey, privkey);
    }
    throw Exception("${event.kind} is not nip44 compatible");
  }

  /// Returns EDMessage from event
  static Future<EDMessage> _toEDMessage(Event event, String receiver, String privkey) async {
    String sender = event.pubkey;
    int createdAt = event.createdAt;
    String receiver = "";
    String replyId = "";
    String content = "";

    for (var tag in event.tags) {
      if (tag[0] == "p") receiver = tag[1];
      if (tag[0] == "e") replyId = tag[1];
    }

    if (receiver.isNotEmpty && receiver.compareTo(receiver) == 0) {
      content = await decryptContent(event.content, privkey, sender);
    } else if (receiver.isNotEmpty && sender.compareTo(receiver) == 0) {
      content = await decryptContent(event.content, privkey, receiver);
    } else {
      throw Exception("not correct receiver, is not nip44 compatible");
    }

    return EDMessage(sender, receiver, createdAt, content, replyId);
  }

  static Future<String> decryptContent(String content, String privkey, String pubkey) async {
    try {
      Map map = jsonDecode(content);
      final cipherText = base64Decode(map["ciphertext"]);
      final nonce = base64Decode(map["nonce"]);
      final v = map["v"];
      if(v == 1){
        final algorithm = Xchacha20(macAlgorithm: MacAlgorithm.empty);
        final secretKey = shareSecret(privkey, '02$pubkey');
        SecretBox secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac.empty);
        final result = await algorithm.decrypt(secretBox, secretKey: secretKey);
        return utf8.decode(result);
      }
      else{
        print("nip44: decryptContent error: unknown algorithm version: $v");
        return "";
      }
    } catch (e) {
      print("nip44: decryptContent error: $e");
      return "";
    }
  }

  static Future<Event> encode(
      String receiver, String content, String replyId, String privkey) async {
    String enContent = await encryptContent(content, privkey, receiver);
    List<List<String>> tags = toTags(receiver, replyId);
    Event event =
        Event.from(kind: 44, tags: tags, content: enContent, privkey: privkey);
    return event;
  }

  static Future<String> encryptContent(
      String content, String privkey, String pubkey) async {
    return await encrypt(privkey, '02$pubkey', content);
  }

  static List<List<String>> toTags(String p, String e) {
    List<List<String>> result = [];
    result.add(["p", p]);
    if (e.isNotEmpty) result.add(["e", e, '', 'reply']);
    return result;
  }

  static Future<String> encrypt(
      String privateString, String publicString, String content) async {
    final algorithm = Xchacha20(macAlgorithm: MacAlgorithm.empty);
    final secretKey = shareSecret(privateString, publicString);
    // Generate a random 96-bit nonce.
    final nonce = generate24RandomBytes();
    final uintInputText = utf8.encode(content);
    // Encrypt
    final secretBox = await algorithm.encrypt(
      uintInputText,
      secretKey: secretKey,
      nonce: nonce,
    );

    final result = {"ciphertext": base64Encode(secretBox.cipherText), "nonce": base64Encode(nonce), "v": 1};
    return jsonEncode(result);
  }

  static SecretKey shareSecret(String privateString, String publicString) {
    final secretIV = Kepler.byteSecret(privateString, publicString);
    final key = Uint8List.fromList(secretIV[0]);
    Uint8List hashSecret = SHA256Digest().process(key);
    return SecretKey(hashSecret);
  }

  static List<int> generate24RandomBytes() {
    final random = Random.secure();
    return List<int>.generate(24, (i) => random.nextInt(256));
  }
}
