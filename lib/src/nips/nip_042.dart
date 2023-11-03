import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

///https://github.com/nostr-protocol/nips/blob/master/42.md
///Authentication of clients to relays
class Nip42 {
  static String encode(String challenge, String relay, String privkey) {
    Event event = Event.from(
        kind: 22242,
        tags: [
          ["relay", relay],
          ["challenge", challenge]
        ],
        content: "",
        privkey: privkey);
    var auth = ["AUTH", event.toJson()];
    return jsonEncode(auth);
  }
}
