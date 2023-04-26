import 'dart:convert';
import 'package:nostr/nostr.dart';

/// Lists
class Nip51 {
  static List<List<String>> toTags(List<String> items) {
    List<List<String>> result = [];
    for (String item in items) {
      result.add(["p", item]);
    }
    return result;
  }

  static String toContent(List<String> items, String privkey, String pubkey) {
    var map = {for (String item in items) "p": item};
    String content = jsonEncode(map);
    return encrypt(privkey, '02$pubkey', content);
  }

  static Event createMute(List<String> items, String privkey, String pubkey) {
    return Event.from(
        kind: 10000,
        tags: toTags(items),
        content: toContent(items, privkey, pubkey),
        privkey: privkey);
  }

  static Event createCategorizedPeople(
      String identifier, List<String> items, String privkey, String pubkey) {
    List<List<String>> tags = toTags(items);
    tags.add(["d", identifier]);
    return Event.from(
        kind: 30000,
        tags: tags,
        content: toContent(items, privkey, pubkey),
        privkey: privkey);
  }

  static createPin() {}
  static createCategorizedBookmarks() {}

  static Lists getLists(Event event, String privkey) {
    if (event.kind == 10000 ||
        event.kind == 10001 ||
        event.kind == 30000 ||
        event.kind == 30001) {
      throw Exception("${event.kind} is not nip51 compatible");
    }
    String identifier = "";
    List<String> people = [];
    List<String> bookmarks = [];
    for (var tag in event.tags) {
      if (tag[0] == "p") people.add(tag[1]);
      if (tag[0] == "d") identifier = tag[1];
    }
    String pubkey = Keychain.getPublicKey(privkey);
    String content = decrypt(privkey, pubkey, event.content);
    for(var tag in jsonDecode(content)){
      if (tag[0] == "p") people.add(tag[1]);
      if (tag[0] == "d") identifier = tag[1];
    }
    if (event.kind == 10000) identifier = "Mute";
    if (event.kind == 10001) identifier = "Pin";

    return Lists(event.pubkey, identifier, people, bookmarks);
  }
}

/// ```
class Lists {
  String owner;

  String identifier;

  List<String> people;

  List<String> bookmarks;

  /// Default constructor
  Lists(this.owner, this.identifier, this.people, this.bookmarks);
}
