import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

class Nip57 {
  static ZapReceipt getZapReceipt(Event event) {
    if (event.kind == 9735 && event.content.isEmpty) {
      String? bolt11, preimage, description, recipient, eventId, content, sender;
      for (var tag in event.tags) {
        if (tag[0] == 'bolt11') bolt11 = tag[1];
        if (tag[0] == 'preimage') preimage = tag[1];
        if (tag[0] == 'description') description = tag[1];
        if (tag[0] == 'p') recipient = tag[1];
        if (tag[0] == 'e') eventId = tag[1];
      }
      if(description != null){
        try{
          Map map = jsonDecode(description);
          content = map['content'];
          sender = map['pubkey'];
        }
        catch(_){
          content = '';
        }
      }

      ZapReceipt zapReceipt = ZapReceipt(event.createdAt, event.pubkey, bolt11!,
          preimage!, description!, recipient!, eventId, content, sender);
      return zapReceipt;
    } else {
      throw Exception("${event.kind} is not nip57 compatible");
    }
  }

  static Event zapRequest(List<String> relays, String amount, String lnurl,
      String recipient, String privkey,
      {String? eventId, String? coordinate, String? content}) {
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
    return Event.from(
        kind: 9734, tags: tags, content: content ?? '', privkey: privkey);
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

  ZapReceipt(this.paidAt, this.zapper, this.bolt11, this.preimage,
      this.description, this.recipient, this.eventId, this.content, this.sender);
}
