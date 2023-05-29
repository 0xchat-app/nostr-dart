import 'package:nostr_core_dart/nostr.dart';

class Nip57 {
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
