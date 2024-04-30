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
          repostId, repostNote, Nip10.fromTags(event.tags));
    }
    throw Exception("${event.kind} is not nip18 compatible");
  }

  static Future<Event> encodeReposts(String repostId, String? repostEventRelay,
      String repostPubkey, String? rawEvent, String pubkey, String privkey) {
    List<List<String>> tags = [];
    tags.add(['e', repostId, repostEventRelay ?? '']);
    tags.add(['p', repostPubkey]);
    String content = rawEvent ?? '';
    return Event.from(
        kind: 6,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
  }

  static bool hasQTag(Event event) {
    for (var tag in event.tags) {
      if (tag[0] == "q") return true;
    }
    return false;
  }

  static QuoteReposts decodeQuoteReposts(Event event) {
    if (event.kind == 1) {
      String quoteRepostId = '';
      for (var tag in event.tags) {
        if (tag[0] == "q") quoteRepostId = tag[1];
      }

      return QuoteReposts(event.id, event.pubkey, event.createdAt,
          event.content, quoteRepostId, Nip10.fromTags(event.tags));
    }
    throw Exception("${event.kind} is not nip18 compatible");
  }

  static Future<Event> encodeQuoteReposts(String quoteRepostId,
      String quoteRepostPubkey, String content, String pubkey, String privkey) {
    List<List<String>> tags = [];
    tags.add(['q', quoteRepostId]);
    tags.add(['p', quoteRepostPubkey]);
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
  Thread thread;

  Reposts(this.eventId, this.pubkey, this.createAt, this.content, this.repostId,
      this.repostNote, this.thread);
}

class QuoteReposts {
  String eventId;
  String pubkey;
  int createAt;
  String content;
  String quoteRepostsId;
  Thread thread;

  QuoteReposts(this.eventId, this.pubkey, this.createAt, this.content,
      this.quoteRepostsId, this.thread);
}
