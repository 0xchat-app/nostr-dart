import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

/// Gift Wrap
/// https://github.com/v0l/nips/blob/59/59.md
class Nip59 {
  static Future<Event> encode(Event event, String receiver, String privkey,
      {String? kind}) async {
    String encodedEvent = jsonEncode(event);
    String content =
        await Nip44.encryptContent(encodedEvent, privkey, receiver);
    List<List<String>> tags = [
      ["p", receiver]
    ];
    if (kind != null) tags.add(['k', kind]);
    return Event.from(
        kind: 1059, tags: tags, content: content, privkey: privkey);
  }

  static Future<Event> decode(Event event, String privkey) async {
    if (event.kind == 1059) {
      String content =
          await Nip44.decryptContent(event.content, privkey, event.pubkey);
      Map map = jsonDecode(content);
      List<dynamic> dynamicTags = map['tags'];
      List<List<String>> tags = dynamicTags.map<List<String>>((e) {
        if (e is List) {
          return e.map<String>((e) => e.toString()).toList();
        } else {
          throw Exception('Unexpected element in list: $e');
        }
      }).toList();
      return Event(map['id'], map['pubkey'], map['created_at'], map['kind'],
          tags, map['content'], map['sig']);
    }
    throw Exception("${event.kind} is not nip59 compatible");
  }
}
