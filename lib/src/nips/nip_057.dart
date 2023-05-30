import 'package:nostr_core_dart/nostr.dart';

class Nip57 {
  static ZapReceipt getZapReceipt(Event event) {
    if (event.kind == 9735 && event.content.isEmpty) {
      String? bolt11, preimage, description, recipient, eventId;
      for (var tag in event.tags) {
        if (tag[0] == 'bolt11') bolt11 = tag[1];
        if (tag[0] == 'preimage') preimage = tag[1];
        if (tag[0] == 'description') description = tag[1];
        if (tag[0] == 'p') recipient = tag[1];
        if (tag[0] == 'e') eventId = tag[1];
      }
      ZapReceipt zapReceipt = ZapReceipt(event.createdAt, event.pubkey, bolt11!,
          preimage!, description!, recipient!, eventId);
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
  String pubkey;
  String bolt11;
  String preimage;
  String description;
  String recipient;
  String? eventId;

  ZapReceipt(this.paidAt, this.pubkey, this.bolt11, this.preimage,
      this.description, this.recipient, this.eventId);
}
