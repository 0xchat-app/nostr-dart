import 'package:nostr_core_dart/nostr.dart';

/// Basic Event Kinds
/// 0: set_metadata: the content is set to a stringified JSON object {name: <username>, about: <string>, picture: <url, string>} describing the user who created the event. A relay may delete past set_metadata events once it gets a new one for the same pubkey.
/// 1: text_note: the content is set to the plaintext content of a note (anything the user wants to say). Do not use Markdown! Clients should not have to guess how to interpret content like [](). Use different event kinds for parsable content.
/// 2: recommend_server: the content is set to the URL (e.g., wss://somerelay.com) of a relay the event creator wants to recommend to its followers.
class Nip1 {
  static Event setMetadata(String content, String privkey) {
    return Event.from(kind: 0, tags: [], content: content, privkey: privkey);
  }

  static Event encodeNote(String content, Thread thread, String privkey) {
    return Event.from(kind: 1, tags: Nip10.toTags(thread), content: content, privkey: privkey);
  }

  static Note decodeNote(Event event) {
    if(event.kind == 1){
      return Note(event.pubkey, event.createdAt, Nip10.fromTags(event.tags), event.content);
    }
    throw Exception("${event.kind} is not nip1 compatible");
  }

  static Event recommendServer(String content, String privkey) {
    return Event.from(kind: 2, tags: [], content: content, privkey: privkey);
  }
}

class Note {
  String pubkey;
  int createAt;
  Thread thread;
  String content;

  Note(this.pubkey, this.createAt, this.thread, this.content);
}
