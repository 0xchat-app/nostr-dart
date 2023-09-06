import 'dart:convert';
import 'package:bip340/bip340.dart' as bip340;
import 'package:nostr_core_dart/nostr.dart';

/// Lists
class Nip51 {
  static List<List<String>> peoplesToTags(List<People> items) {
    List<List<String>> result = [];
    for (People item in items) {
      result.add([
        "p",
        item.pubkey,
        item.mainRelay ?? "",
        item.petName ?? "",
        item.aliasPubKey ?? "",
      ]);
    }
    return result;
  }

  static List<List<String>> bookmarksToTags(List<String> items) {
    List<List<String>> result = [];
    for (String item in items) {
      result.add(["e", item]);
    }
    return result;
  }

  static Future<String> peoplesToContent(
      List<People> items, String privkey, String pubkey) async {
    var list = [];
    for (People item in items) {
      list.add([
        'p',
        item.pubkey,
        item.mainRelay ?? "",
        item.petName ?? "",
        item.aliasPubKey ?? "",
      ]);
    }
    String content = jsonEncode(list);
    return await Nip44.encryptContent(content, privkey, pubkey);
  }

  static Future<String> bookmarksToContent(
      List<String> items, String privkey, String pubkey) async {
    var list = [];
    for (String item in items) {
      list.add(['e', item]);
    }
    String content = jsonEncode(list);
    return await Nip44.encryptContent(content, privkey, pubkey);
  }

  static Future<Map<String, List>?> fromContent(
      String content, String privkey, String pubkey) async {
    List<People> people = [];
    List<String> bookmarks = [];
    int ivIndex = content.indexOf("?iv=");
    String deContent = '';
    if (ivIndex <= 0) {
      /// try nip44 decrypted
      deContent = await Nip44.decryptContent(content, privkey, pubkey);
    }
    else{
      /// try nip4 decrypted
      String iv = content.substring(ivIndex + "?iv=".length, content.length);
      String encString = content.substring(0, ivIndex);
      deContent =
      decrypt(privkey, "02$pubkey", encString, iv);
    }

    for (List tag in jsonDecode(deContent)) {
      if (tag[0] == "p") {
        people.add(People(tag[1], tag.length > 2 ? tag[2] : "",
            tag.length > 3 ? tag[3] : "", tag.length > 4 ? tag[4] : ""));
      } else if (tag[0] == "e") {
        // bookmark
        bookmarks.add(tag[1]);
      }
    }
    return {"people": people, "bookmarks": bookmarks};
  }

  static Future<Event> createMutePeople(List<People> items, List<People> encryptedItems,
      String privkey, String pubkey) async {
    String content = await peoplesToContent(encryptedItems, privkey, pubkey);
    return Event.from(
        kind: 10000,
        tags: peoplesToTags(items),
        content: content,
        privkey: privkey);
  }

  static Future<Event> createPinEvent(List<String> items, List<String> encryptedItems,
      String privkey, String pubkey) async {
    String content = await bookmarksToContent(encryptedItems, privkey, pubkey);
    return Event.from(
        kind: 10001,
        tags: bookmarksToTags(items),
        content: content,
        privkey: privkey);
  }

  static Future<Event> createCategorizedPeople(String identifier, List<People> items,
      List<People> encryptedItems, String privkey, String pubkey) async {
    List<List<String>> tags = peoplesToTags(items);
    tags.add(["d", identifier]);
    String content = await peoplesToContent(encryptedItems, privkey, pubkey);
    return Event.from(
        kind: 30000,
        tags: tags,
        content: content,
        privkey: privkey);
  }

  static Future<Event> createCategorizedBookmarks(String identifier, List<String> items,
      List<String> encryptedItems, String privkey, String pubkey) async {
    List<List<String>> tags = bookmarksToTags(items);
    tags.add(["d", identifier]);
    String content = await bookmarksToContent(encryptedItems, privkey, pubkey);
    return Event.from(
        kind: 30001,
        tags: tags,
        content: content,
        privkey: privkey);
  }

  static Future<Lists> getLists(Event event, String privkey) async {
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
        people.add(People(tag[1], tag.length > 2 ? tag[2] : "",
            tag.length > 3 ? tag[3] : "", tag.length > 4 ? tag[4] : ""));
      }
      if (tag[0] == "e") {
        bookmarks.add(tag[1]);
      }
      if (tag[0] == "d") identifier = tag[1];
    }
    String pubkey = bip340.getPublicKey(privkey);
    Map? content = await Nip51.fromContent(event.content, privkey, pubkey);
    if(content != null){
      people.addAll(content["people"]);
      bookmarks.addAll(content["bookmarks"]);
    }
    if (event.kind == 10000) identifier = "Mute";
    if (event.kind == 10001) identifier = "Pin";

    return Lists(event.pubkey, identifier, people, bookmarks, event.createdAt);
  }
}

///
class People {
  String pubkey;
  String? mainRelay;
  String? petName;
  String? aliasPubKey;

  /// Default constructor
  People(this.pubkey, this.mainRelay, this.petName, this.aliasPubKey);
}

class Lists {
  String owner;

  String identifier;

  List<People> people;

  List<String> bookmarks;

  int createTime;

  /// Default constructor
  Lists(this.owner, this.identifier, this.people, this.bookmarks, this.createTime);
}
