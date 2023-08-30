import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

/// Gift Wrap
/// https://github.com/v0l/nips/blob/59/59.md
class Nip59 {
  static Future<Event> encode(Event event, String receiver,
      {String? sealedPrivkey, String? kind, int? expiration}) async {
    String encodedEvent = jsonEncode(event);
    sealedPrivkey ??= Keychain.generate().private;
    String content =
        await Nip44.encryptContent(encodedEvent, sealedPrivkey, receiver);
    List<List<String>> tags = [
      ["p", receiver]
    ];
    if (kind != null) tags.add(['k', kind]);
    if (expiration != null) tags.add(['expiration', '$expiration']);
    return Event.from(
        kind: 1059, tags: tags, content: content, privkey: sealedPrivkey);
  }

  static Future<Event> decode(Event event, String privkey) async {
    if (event.kind == 1059) {
      String content =
          await Nip44.decryptContent(event.content, privkey, event.pubkey);
      Map<String, dynamic> map = jsonDecode(content);
      return Event.fromJson(map);
    }
    throw Exception("${event.kind} is not nip59 compatible");
  }
}
