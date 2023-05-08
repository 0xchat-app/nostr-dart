import 'dart:convert';
import 'package:nostr/nostr.dart';

/// Lists
class Nip51 {
  static List<List<String>> toTags(List<People> items) {
    List<List<String>> result = [];
    for (People item in items) {
      result.add([
        "p",
        item.pubkey,
        item.aliasPubKey ?? "",
        item.mainRelay ?? "",
        item.petName ?? ""
      ]);
    }
    return result;
  }

  static String toContent(List<People> items, String privkey, String pubkey) {
    var list = [];
    for (People item in items) {
      list.add([
        'p',
        item.pubkey,
        item.aliasPubKey ?? "",
        item.mainRelay ?? "",
        item.petName ?? ""
      ]);
    }
    String content = jsonEncode(list);
    return encrypt(privkey, '02$pubkey', content);
  }

  static List<People> fromContent(
      String content, String privkey, String pubkey) {
    List<People> item = [];
    int ivIndex = content.indexOf("?iv=");
    if (ivIndex <= 0) {
      print("Invalid content, could not get ivIndex: $content");
    }
    String iv = content.substring(ivIndex + "?iv=".length, content.length);
    String encString = content.substring(0, ivIndex);
    String deContent = decrypt(privkey, '02$pubkey', encString, iv);
    for (List tag in jsonDecode(deContent)) {
      if (tag[0] == "p") {
        item.add(People(tag[1], tag.length > 2 ? tag[2] : "", tag.length > 3 ? tag[3] : "", tag.length > 4 ? tag[4] : ""));
      }
    }
    return item;
  }

  static Event createMute(List<People> items, String privkey, String pubkey) {
    return Event.from(
        kind: 10000,
        tags: toTags(items),
        content: toContent(items, privkey, pubkey),
        privkey: privkey);
  }

  static Event createCategorizedPeople(String identifier, List<People> items,
      List<People> contentItems, String privkey, String pubkey) {
    List<List<String>> tags = toTags(items);
    tags.add(["d", identifier]);
    return Event.from(
        kind: 30000,
        tags: tags,
        content: toContent(contentItems, privkey, pubkey),
        privkey: privkey);
  }

  static createPin() {}
  static createCategorizedBookmarks() {}

  static Lists getLists(Event event, String privkey) {
    if (event.kind != 10000 &&
        event.kind != 10001 &&
        event.kind != 30000 &&
        event.kind != 30001) {
      throw Exception("${event.kind} is not nip51 compatible");
    }
    String identifier = "";
    List<People> people = [];
    List<String> bookmarks = [];
    for (List tag in event.tags) {
      if (tag[0] == "p") {
        people.add(People(tag[1], tag.length > 2 ? tag[2] : "", tag.length > 3 ? tag[3] : "", tag.length > 4 ? tag[4] : ""));
      }
      if (tag[0] == "d") identifier = tag[1];
    }
    String pubkey = Keychain.getPublicKey(privkey);
    List<People> content = Nip51.fromContent(event.content, privkey, pubkey);
    people.addAll(content);
    if (event.kind == 10000) identifier = "Mute";
    if (event.kind == 10001) identifier = "Pin";

    return Lists(event.pubkey, identifier, people, bookmarks);
  }
}

///
class People {
  String pubkey;
  String? aliasPubKey;
  String? mainRelay;
  String? petName;

  /// Default constructor
  People(this.pubkey, this.aliasPubKey, this.mainRelay, this.petName);
}

class Lists {
  String owner;

  String identifier;

  List<People> people;

  List<String> bookmarks;

  /// Default constructor
  Lists(this.owner, this.identifier, this.people, this.bookmarks);
}
