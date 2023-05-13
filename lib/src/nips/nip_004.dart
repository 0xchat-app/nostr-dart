import 'package:nostr_dart/nostr.dart';

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
  static EDMessage decode(Event event, String pubkey, String privkey) {
    if (event.kind == 4) {
      return _toEDMessage(event, pubkey, privkey);
    }
    throw Exception("${event.kind} is not nip4 compatible");
  }

  /// Returns EDMessage from event
  static EDMessage _toEDMessage(Event event, String pubkey, String privkey) {
    String sender = event.pubkey;
    int createdAt = event.createdAt;
    String receiver = "";
    String replyId = "";
    String content = "";

    for (var tag in event.tags) {
      if (tag[0] == "p") receiver = tag[1];
      if (tag[0] == "e") replyId = tag[1];
    }

    if (receiver.isNotEmpty && receiver.compareTo(pubkey) == 0) {
      content = decryptContent(event.content, privkey, sender);
    } else {
      throw Exception("not correct receiver, is not nip4 compatible");
    }

    return EDMessage(sender, receiver, createdAt, content, replyId);
  }

  static String decryptContent(String content, String privkey, String pubkey) {
    int ivIndex = content.indexOf("?iv=");
    if (ivIndex <= 0) {
      print("Invalid content for dm, could not get ivIndex: $content");
      return "";
    }
    String iv = content.substring(ivIndex + "?iv=".length, content.length);
    String encString = content.substring(0, ivIndex);

    String result = decrypt(privkey, '02$pubkey', encString, iv);

    return result;
  }

  static Event encode(String sender, String receiver, String content,
      String replyId, String privkey) {
    String enContent = encryptContent(content, privkey, receiver);
    List<List<String>> tags = toTags(receiver, replyId);
    Event event =
        Event.from(kind: 4, tags: tags, content: enContent, privkey: privkey);
    return event;
  }

  static String encryptContent(String content, String privkey, String pubkey) {
    return encrypt(privkey, '02$pubkey', content);
  }

  static List<List<String>> toTags(String p, String e) {
    List<List<String>> result = [];
    result.add(["p", p]);
    if (e.isNotEmpty) result.add(["e", e]);
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

  /// Default constructor
  EDMessage(
      this.sender, this.receiver, this.createdAt, this.content, this.replyId);
}
