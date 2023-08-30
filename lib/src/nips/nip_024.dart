import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

/// Sealed Gossip
/// https://github.com/vitorpamplona/nips/blob/sealed-dms/24.md
class Nip24 {
  static Future<Event> encode(Event event, String receiver, String privkey,
      {int? kind,
      int? expiration,
      String? sealedPrivkey,
      String? sealedReceiver}) async {
    Event sealedGossipEvent =
        await _encodeSealedGossip(event, receiver, privkey);
    return Nip59.encode(sealedGossipEvent, sealedReceiver ?? receiver,
        kind: kind?.toString(),
        expiration: expiration,
        sealedPrivkey: sealedPrivkey);
  }

  static Future<Event> _encodeSealedGossip(
      Event event, String receiver, String privkey) async {
    event.sig = '';
    String encodedEvent = jsonEncode(event);
    String content =
        await Nip44.encryptContent(encodedEvent, privkey, receiver);
    return Event.from(kind: 13, tags: [], content: content, privkey: privkey);
  }

  static Future<Event> encodeSealedGossipDM(
      String receiver, String content, String replyId, String privkey,
      {String? sealedPrivkey, String? sealedReceiver}) async {
    List<List<String>> tags = Nip4.toTags(receiver, replyId);
    Event event =
        Event.from(kind: 14, tags: tags, content: content, privkey: privkey);
    return await encode(event, receiver, privkey,
        sealedPrivkey: sealedPrivkey, sealedReceiver: sealedReceiver);
  }

  static Future<Event?> decode(Event event, String privkey, {String? sealedPrivkey}) async {
    try {
      Event sealedGossipEvent = await Nip59.decode(event, sealedPrivkey ?? privkey);
      Event decodeEvent = await _decodeSealedGossip(sealedGossipEvent, privkey);
      return decodeEvent;
    } catch (e) {
      print('decode error: ${e.toString()}');
      return null;
    }
  }

  static Future<Event> _decodeSealedGossip(Event event, String privkey) async {
    if (event.kind == 13) {
      try {
        String content =
            await Nip44.decryptContent(event.content, privkey, event.pubkey);
        Map<String, dynamic> map = jsonDecode(content);
        Event innerEvent = Event.fromJson(map, verify: false);
        if (innerEvent.pubkey == event.pubkey) {
          return innerEvent;
        } else {
          throw Exception("${innerEvent.pubkey} not valid pubkey");
        }
      } catch (e) {
        throw Exception("${event.id} is not nip24 compatible");
      }
    }
    throw Exception("${event.kind} is not nip24 compatible");
  }

  static Future<EDMessage> decodeSealedGossipDM(
      Event dmEvent, String receiver, String privkey) async {
    if (dmEvent.kind == 14) {
      String receiver = "";
      String replyId = "";
      for (var tag in dmEvent.tags) {
        if (tag[0] == "p") receiver = tag[1];
        if (tag[0] == "e") replyId = tag[1];
      }
      return EDMessage(dmEvent.pubkey, receiver, dmEvent.createdAt,
          dmEvent.content, replyId);
    }
    throw Exception("${dmEvent.kind} is not kind14 compatible");
  }
}
