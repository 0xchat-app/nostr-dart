import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

/// Sealed Gossip
/// https://github.com/vitorpamplona/nips/blob/sealed-dms/24.md
class Nip24 {
  static Future<Event> encode(Event event, String receiver,
      {String? privkey, int? kind, int? expiration}) async {
    // random key default
    privkey ??= Keychain.generate().private;
    Event sealedGossipEvent =
        await encodeSealedGossip(event, receiver, privkey);
    return Nip59.encode(sealedGossipEvent, receiver, privkey,
        kind: kind.toString(), expiration: expiration);
  }

  static Future<Event> encodeSealedGossip(
      Event event, String receiver, String privkey) async {
    event.sig = '';
    String encodedEvent = jsonEncode(event);
    String content =
        await Nip44.encryptContent(encodedEvent, privkey, receiver);
    return Event.from(kind: 13, tags: [], content: content, privkey: privkey);
  }

  static Future<Event> decode(Event event, String privkey) async {
    Event sealedGossipEvent = await Nip59.decode(event, privkey);
    return decodeSealedGossip(sealedGossipEvent, privkey);
  }

  static Future<Event> decodeSealedGossip(Event event, String privkey) async {
    if (event.kind == 13) {
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
          tags, map['content'], map['sig'] ?? '',
          verify: false);
    }
    throw Exception("${event.kind} is not nip24 compatible");
  }

  static Future<EDMessage> decodeSealedGossipDM(
      Event event, String receiver, String privkey) async {
    if (event.kind == 14) {
      return await Nip44.decode(event, receiver, privkey);
    }
    throw Exception("${event.kind} is not nip24 compatible");
  }
}
