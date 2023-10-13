import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:kepler/kepler.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Encrypted Direct Message
/// https://github.com/nostr-protocol/nips/pull/715///
class Nip44 {
  /// Returns the EDMessage Encrypted Direct Message event (kind=44)
  static Future<EDMessage?> decode(
      Event event, String receiver, String privkey) async {
    if (event.kind == 44 || event.kind == 14) {
      return await _toEDMessage(event, receiver, privkey);
    }
    return null;
  }

  /// Returns EDMessage from event
  static Future<EDMessage> _toEDMessage(
      Event event, String receiver, String privkey) async {
    String sender = event.pubkey;
    int createdAt = event.createdAt;
    String receiver = "";
    String replyId = "";
    String content = "";
    String subContent = event.content;

    for (var tag in event.tags) {
      if (tag[0] == "p") receiver = tag[1];
      if (tag[0] == "e") replyId = tag[1];
      if (tag[0] == "subContent") subContent = tag[1];
    }

    if (receiver.isNotEmpty && receiver.compareTo(receiver) == 0) {
      content = await decryptContent(subContent, privkey, sender);
    } else if (receiver.isNotEmpty && sender.compareTo(receiver) == 0) {
      content = await decryptContent(subContent, privkey, receiver);
    } else {
      throw Exception("not correct receiver, is not nip44 compatible");
    }

    return EDMessage(sender, receiver, createdAt, content, replyId, null);
  }

  static Future<String> decryptContent(
      String content, String privkey, String pubkey,
      {String encodeType = 'base64', String? prefix}) async {
    try {
      Uint8List? decodeContent;
      if (encodeType == 'base64') {
        decodeContent = base64Decode(content);
      } else if (encodeType == 'bech32') {
        Map map = bech32Decode(content, maxLength: content.length);
        assert(map['prefix'] == prefix);
        decodeContent = hexToBytes(map['data']);
      }
      final v = decodeContent![0];
      final nonce = decodeContent.sublist(1, 25);
      final cipherText = decodeContent.sublist(25);
      if (v == 1) {
        final algorithm = Xchacha20(macAlgorithm: MacAlgorithm.empty);
        final secretKey = shareSecret(privkey, pubkey);
        SecretBox secretBox =
            SecretBox(cipherText, nonce: nonce, mac: Mac.empty);
        final result =
            await algorithm.decrypt(secretBox, secretKey: SecretKey(secretKey));
        return utf8.decode(result);
      } else {
        print("nip44: decryptContent error: unknown algorithm version: $v");
        return "";
      }
    } catch (e) {
      print("nip44: decryptContent error: $e");
      return "";
    }
  }

  static Future<Event> encode(
      String receiver, String content, String replyId, String privkey, {String? subContent}) async {
    String enContent = await encryptContent(content, privkey, receiver);
    List<List<String>> tags = toTags(receiver, replyId);
    if(subContent != null && subContent.isNotEmpty){
      String enSubContent = await encryptContent(subContent, privkey, receiver);
      tags.add(['subContent', enSubContent]);
    }
    Event event =
        Event.from(kind: 44, tags: tags, content: enContent, privkey: privkey);
    return event;
  }

  static Future<String> encryptContent(
      String content, String privkey, String pubkey) async {
    return await encrypt(privkey, pubkey, content);
  }

  static List<List<String>> toTags(String p, String e) {
    List<List<String>> result = [];
    result.add(["p", p]);
    if (e.isNotEmpty) result.add(["e", e, '', 'reply']);
    return result;
  }

  static Future<String> encrypt(
      String privateString, String publicString, String content,
      {String encodeType = 'base64', String? prefix}) async {
    final algorithm = Xchacha20(macAlgorithm: MacAlgorithm.empty);
    final secretKey = shareSecret(privateString, publicString);
    // Generate a random 96-bit nonce.
    final nonce = generate24RandomBytes();
    final uintInputText = utf8.encode(content);
    // Encrypt
    final secretBox = await algorithm.encrypt(
      uintInputText,
      secretKey: SecretKey(secretKey),
      nonce: nonce,
    );

    List<int> result = [];
    result.add(1);
    result.addAll(nonce);
    result.addAll(secretBox.cipherText);
    if (encodeType == 'base64') {
      return base64Encode(result);
    } else if (encodeType == 'bech32' && prefix != null) {
      String hexData = result
          .map((int value) => value.toRadixString(16).padLeft(2, '0'))
          .join();
      return bech32Encode(prefix, hexData, maxLength: hexData.length);
    }
    return '';
  }

  static Uint8List shareSecret(String privateString, String publicString) {
    final secretIV = Kepler.byteSecret(privateString, '02$publicString');
    final key = Uint8List.fromList(secretIV[0]);
    return SHA256Digest().process(key);
  }

  static List<int> generate24RandomBytes() {
    final random = Random.secure();
    return List<int>.generate(24, (i) => random.nextInt(256));
  }
}
