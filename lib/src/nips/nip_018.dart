import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

/// Reposts & Quote Reposts
class Nip18 {
  static Reposts decodeReposts(Event event) {
    if (event.kind == 6) {
      String repostId = '';
      Note? repostNote;
      for (var tag in event.tags) {
        if (tag[0] == "e") repostId = tag[1];
      }
      try {
        var repostJson = jsonDecode(event.content);
        Event repostEvent = Event.fromJson(repostJson);
        repostNote = Nip1.decodeNote(repostEvent);
        repostId = repostNote.nodeId;
      } catch (_) {}

      return Reposts(event.id, event.pubkey, event.createdAt, event.content,
          repostId, repostNote);
    }
    throw Exception("${event.kind} is not nip18 compatible");
  }

  static Future<Event> encodeReposts(String repostId, String repostEventRelay,
      Event? event, String pubkey, String privkey) {
    List<List<String>> tags = [];
    tags.add(['e', repostId, repostEventRelay ?? '']);
    String content = '';
    if (event != null) content = jsonEncode(event.toJson());
    return Event.from(
        kind: 6,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
  }
}

class Reposts {
  String eventId;
  String pubkey;
  int createAt;
  String content;
  String repostId;
  Note? repostNote;

  Reposts(this.eventId, this.pubkey, this.createAt, this.content, this.repostId,
      this.repostNote);
}
