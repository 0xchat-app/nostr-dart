import 'package:nostr/nostr.dart';

class Nip10 {
  static Thread fromTags(List<List<String>> tags){
    List<ETags> etags = [];
    List<PTags> ptags = [];
    for (var tag in tags) {
      if (tag[0] == "p") ptags.add(PTags(tag[1], tag[2]));
      if (tag[0] == "e") etags.add(ETags(tag[1], tag[2], tag[3]));
    }
    return Thread(etags, ptags);
  }

  static List<List<String>> toTags(List<ETags> etags, List<PTags> ptags) {
    List<List<String>> result = [];
    for (var etag in etags) {
      result.add(["e", etag.eventId, etag.relayURL, etag.marker]);
    }
    for (var ptag in ptags) {
      result.add(["e", ptag.pubkey, ptag.relayURL]);
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
  List<ETags> etags;
  List<PTags> ptags;
  Thread(this.etags, this.ptags);
}