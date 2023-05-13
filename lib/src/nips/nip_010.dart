import 'package:nostr_core_dart/nostr.dart';

class Nip10 {
  static Thread fromTags(List<List<String>> tags) {
    ETags root = ETags('', '', '');
    List<ETags> replys = [];
    List<PTags> ptags = [];
    for (var tag in tags) {
      if (tag[0] == "p") ptags.add(PTags(tag[1], tag[2]));
      if (tag[0] == "e") {
        if (tag[3] == 'root') {
          root = ETags(tag[1], tag[2], tag[3]);
        } else {
          replys.add(ETags(tag[1], tag[2], tag[3]));
        }
      }
    }
    return Thread(root, replys, ptags);
  }

  static ETags rootTag(String eventId, String relay) {
    return ETags(eventId, relay, 'root');
  }

    static List<List<String>> toTags(List<ETags> etags, List<PTags> ptags) {
    List<List<String>> result = [];
    for (var etag in etags) {
      result.add(["e", etag.eventId, etag.relayURL, etag.marker]);
    }
    for (var ptag in ptags) {
      result.add(["p", ptag.pubkey, ptag.relayURL]);
    }
    return result;
  }
}

class ETags {
  String eventId;
  String relayURL;
  String marker; // root/reply/mention

  ETags(this.eventId, this.relayURL, this.marker);
}

class PTags {
  String pubkey;
  String relayURL;

  PTags(this.pubkey, this.relayURL);
}

class Thread {
  ETags root;
  List<ETags> replys;
  List<PTags> ptags;
  Thread(this.root, this.replys, this.ptags);
}
