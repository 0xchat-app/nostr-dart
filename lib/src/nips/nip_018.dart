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

  static Future<Event> encodeReposts(String repostId, String? repostEventRelay,
      String? rawEvent, String pubkey, String privkey) {
    List<List<String>> tags = [];
    tags.add(['e', repostId, repostEventRelay ?? '']);
    String content = rawEvent ?? '';
    return Event.from(
        kind: 6,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
  }

  static QuoteReposts decodeQuoteReposts(Event event) {
    if (event.kind == 1) {
      String quoteRepostId = '';
      for (var tag in event.tags) {
        if (tag[0] == "q") quoteRepostId = tag[1];
      }

      return QuoteReposts(event.id, event.pubkey, event.createdAt,
          event.content, quoteRepostId);
    }
    throw Exception("${event.kind} is not nip18 compatible");
  }

  static Future<Event> encodeQuoteReposts(
      String quoteRepostId, String content, String pubkey, String privkey) {
    List<List<String>> tags = [];
    tags.add(['q', quoteRepostId]);
    return Event.from(
        kind: 1,
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

class QuoteReposts {
  String eventId;
  String pubkey;
  int createAt;
  String content;
  String quoteRepostsId;

  QuoteReposts(this.eventId, this.pubkey, this.createAt, this.content,
      this.quoteRepostsId);
}
