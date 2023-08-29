import 'dart:convert';
import 'dart:typed_data';

import 'package:nostr_core_dart/nostr.dart';

class Nip57 {
  static Future<ZapReceipt> getZapReceipt(Event event, String privkey) async {
    if (event.kind == 9735) {
      String? bolt11,
          preimage,
          description,
          recipient,
          eventId,
          content,
          sender,
          anon;
      for (var tag in event.tags) {
        if (tag[0] == 'bolt11') bolt11 = tag[1];
        if (tag[0] == 'preimage') preimage = tag[1];
        if (tag[0] == 'description') description = tag[1];
        if (tag[0] == 'p') recipient = tag[1];
        if (tag[0] == 'e') eventId = tag[1];
        if (tag[0] == 'anon') anon = tag[1];
      }
      if (description != null) {
        try {
          Map map = jsonDecode(description);
          content = map['content'];
          sender = map['pubkey'];
        } catch (_) {
          content = '';
        }
      }

      if (anon != null && anon.isNotEmpty) {
        /// recipient decrypt
        String eventString = await Nip44.decryptContent(
            anon, privkey, event.pubkey,
            encodeType: 'bech32', prefix: 'pzap');

        /// try to use sender decrypt
        if (eventString.isEmpty) {
          String derivedPrivkey =
              generateKeyPair(recipient!, event.createdAt, privkey);
          eventString =
              await Nip44.decryptContent(anon, derivedPrivkey, recipient);
        }
        if (eventString.isNotEmpty) {
          Event privEvent = Event.fromJson(jsonDecode(eventString));
          sender = privEvent.pubkey;
          content = privEvent.content;
        }
      }

      ZapReceipt zapReceipt = ZapReceipt(event.createdAt, event.pubkey, bolt11!,
          preimage!, description!, recipient!, eventId, content, sender);
      return zapReceipt;
    } else {
      throw Exception("${event.kind} is not nip57 compatible");
    }
  }

  static Future<Event> zapRequest(List<String> relays, String amount,
      String lnurl, String recipient, String privkey, bool privateZap,
      {String? eventId, String? coordinate, String? content}) async {
    List<String> r = ['relays'];
    r.addAll(relays);
    List<List<String>> tags = [
      r,
      ['amount', amount],
      ['lnurl', lnurl],
      ['p', recipient]
    ];
    if (eventId != null) {
      tags.add(['e', eventId]);
    }
    if (coordinate != null) {
      tags.add(['a', coordinate]);
    }

    int createAt = currentUnixTimestampSeconds();

    String derivedPrivkey = privkey;
    if (privateZap) {
      String derivedPrivkey = generateKeyPair(recipient, createAt, privkey);
      String privreq = await privateRequest(recipient, privkey, derivedPrivkey,
          eventId: eventId, coordinate: coordinate, content: content);
      tags.add(['anon', privreq]);
    }

    return Event.from(
        kind: 9734,
        tags: tags,
        content: privateZap ? '' : content ?? '',
        privkey: derivedPrivkey,
        createdAt: createAt);
  }

  static String generateKeyPair(String receiver, int createAt, String privkey) {
    Uint8List derivedPrivateKey =
        tweakAdd(hexToBytes(privkey), hexToBytes(receiver), salt: createAt);
    return bytesToHex(derivedPrivateKey);
  }

  static Future<String> privateRequest(
      String recipient, String privkey, String derivedPrivkey,
      {String? eventId, String? coordinate, String? content}) async {
    List<List<String>> tags = [
      ['p', recipient]
    ];
    if (eventId != null) {
      tags.add(['e', eventId]);
    }
    if (coordinate != null) {
      tags.add(['a', coordinate]);
    }

    Event event = Event.from(
        kind: 9733, tags: tags, content: content ?? '', privkey: privkey);

    String eventString = jsonEncode(event);
    return await Nip44.encrypt(privkey, recipient, eventString,
        encodeType: 'bech32', prefix: 'pzap');
  }
}

class ZapReceipt {
  int paidAt;
  String zapper;
  String bolt11;
  String preimage;
  String description;
  String recipient;
  String? eventId;
  String? content;
  String? sender;

  ZapReceipt(
      this.paidAt,
      this.zapper,
      this.bolt11,
      this.preimage,
      this.description,
      this.recipient,
      this.eventId,
      this.content,
      this.sender);
}
