import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

/// Sealed Gossip
/// https://github.com/vitorpamplona/nips/blob/sealed-dms/24.md
class Nip24 {
  static Future<Event> encode(Event event, String receiver, String privkey,
      {int? kind,
      int? expiration,
      String? sealedPrivkey,
      String? sealedReceiver, int? createAt}) async {
    Event sealedGossipEvent =
        await _encodeSealedGossip(event, receiver, privkey);
    return await Nip59.encode(sealedGossipEvent, sealedReceiver ?? receiver,
        kind: kind?.toString(),
        expiration: expiration,
        sealedPrivkey: sealedPrivkey, createAt: createAt);
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
      {String? sealedPrivkey, String? sealedReceiver, int? createAt, String? subContent, int? expiration}) async {
    List<List<String>> tags = Nip4.toTags(receiver, replyId, expiration);
    if(subContent != null && subContent.isNotEmpty){
      tags.add(['subContent', subContent]);
    }
    Event event =
        await Event.from(kind: 14, tags: tags, content: content, privkey: privkey);
    return await encode(event, receiver, privkey,
        sealedPrivkey: sealedPrivkey, sealedReceiver: sealedReceiver, createAt: createAt, expiration: expiration);
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
      try{
        String content =
        await Nip44.decryptContent(event.content, privkey, event.pubkey);
        Map<String, dynamic> map = jsonDecode(content);
        map['sig'] = '';
        Event innerEvent = Event.fromJson(map, verify: false);
        if (innerEvent.pubkey == event.pubkey) {
          return innerEvent;
        }
      }
      catch(e){
        throw Exception(e);
      }
    }
    throw Exception("${event.kind} is not nip24 compatible");
  }

  static Future<EDMessage?> decodeSealedGossipDM(
      Event dmEvent, String receiver) async {
    if (dmEvent.kind == 14) {
      List<String> receivers = [];
      String replyId = "";
      String subContent = dmEvent.content;
      String? expiration;
      for (var tag in dmEvent.tags) {
        if (tag[0] == "p") receivers.add(tag[1]);
        if (tag[0] == "e") replyId = tag[1];
        if (tag[0] == "subContent") subContent = tag[1];
        if (tag[0] == "expiration") expiration = tag[1];
      }
      if(receivers.length == 1) {
        return EDMessage(dmEvent.pubkey, receivers.first, dmEvent.createdAt,
            subContent, replyId, expiration);
      }
      else{
        return null;
      }
    }
    return null;
  }
}
