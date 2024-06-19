import 'dart:math';

import 'package:nostr_core_dart/nostr.dart';

/// Encrypted Direct Message
class Nip4 {
  /// Returns the EDMessage Encrypted Direct Message event (kind=4)
  ///
  /// ```dart
  ///  var event = Event.from(
  ///    pubkey: senderPubKey,
  ///    created_at: 12121211,
  ///    kind: 4,
  ///    tags: [
  ///      ["p", receiverPubKey],
  ///      ["e", <event-id>, <relay-url>, <marker>],
  ///    ],
  ///    content: "wLzN+Wt2vKhOiO8v+FkSzA==?iv=X0Ura57af2V5SuP80O6KkA==",
  ///  );
  ///
  ///  EDMessage eDMessage = Nip4.decode(event);
  ///```
  static Future<EDMessage?> decode(
      Event event, String myPubkey, String privkey) async {
    if (event.kind == 4) {
      return await _toEDMessage(event, myPubkey, privkey);
    }
    return null;
  }

  /// Returns EDMessage from event
  static Future<EDMessage> _toEDMessage(
      Event event, String myPubkey, String privkey) async {
    String sender = event.pubkey;
    int createdAt = event.createdAt;
    String receiver = "";
    String replyId = "";
    String content = "";
    String subContent = event.content;
    String? expiration;
    for (var tag in event.tags) {
      if (tag[0] == "p") receiver = tag[1];
      if (tag[0] == "e") replyId = tag[1];
      if (tag[0] == "subContent") subContent = tag[1];
      if (tag[0] == "expiration") expiration = tag[1];
    }
    if (receiver.compareTo(myPubkey) == 0) {
      content = await decryptContent(subContent, sender, myPubkey, privkey);
    } else if (sender.compareTo(myPubkey) == 0) {
      content = await decryptContent(subContent, receiver, myPubkey, privkey);
    } else {
      throw Exception("not correct receiver, is not nip4 compatible");
    }

    return EDMessage(sender, receiver, createdAt, content, replyId, expiration);
  }

  static Future<String> decryptContent(String content, String peerPubkey,
      String myPubkey, String privkey) async {
    int ivIndex = content.indexOf("?iv=");
    if (ivIndex <= 0) {
      print("Invalid content for dm, could not get ivIndex: $content");
      return "";
    }
    String iv = content.substring(ivIndex + "?iv=".length, content.length);
    String encString = content.substring(0, ivIndex);
    try {
      if (SignerHelper.needSigner(privkey)) {
        return await SignerHelper.decryptNip04(content, peerPubkey, myPubkey);
      } else {
        return decrypt(privkey, '02$peerPubkey', encString, iv);
      }
    } catch (e) {
      return "";
    }
  }

  static Future<Event> encode(String sender, String receiver, String content,
      String replyId, String privkey,
      {String? subContent, int? expiration}) async {
    String enContent = await encryptContent(content, receiver, sender, privkey);
    List<List<String>> tags = toTags(receiver, replyId, expiration);
    if (subContent != null && subContent.isNotEmpty) {
      String enSubContent =
          await encryptContent(subContent, receiver, sender, privkey);
      tags.add(['subContent', enSubContent]);
    }
    Event event = await Event.from(
        kind: 4,
        tags: tags,
        content: enContent,
        pubkey: sender,
        privkey: privkey);
    return event;
  }

  static Future<String> encryptContent(String plainText, String peerPubkey,
      String myPubkey, String privkey) async {
    if (SignerHelper.needSigner(privkey)) {
      return await SignerHelper.encryptNip04(plainText, peerPubkey, myPubkey);
    } else {
      return encrypt(privkey, '02$peerPubkey', plainText);
    }
  }

  static List<List<String>> toTags(String p, String e, int? expiration,
      {List<String>? members}) {
    List<List<String>> result = [];
    result.add(["p", p]);
    for (var m in members ?? []) {
      if (m != p) result.add(["p", m]);
    }
    if (e.isNotEmpty) result.add(["e", e, '', 'reply']);
    if (expiration != null) result.add(['expiration', expiration.toString()]);
    return result;
  }
}

/// ```
class EDMessage {
  String sender;

  String receiver;

  int createdAt;

  String content;

  String replyId;

  String? expiration;

  String? groupId;

  String? subject;

  List<String>? members;

  /// Default constructor
  EDMessage(this.sender, this.receiver, this.createdAt, this.content,
      this.replyId, this.expiration,
      {this.groupId, this.subject, this.members});
}
