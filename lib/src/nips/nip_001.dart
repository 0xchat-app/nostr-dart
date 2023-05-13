import 'package:nostr_core_dart/nostr.dart';

class Nip1 {
  static Event setMetadata(String content, String privkey) {
    return Event.from(kind: 0, tags: [], content: content, privkey: privkey);
  }

  static Event textNote(String content, String privkey) {
    return Event.from(kind: 1, tags: [], content: content, privkey: privkey);
  }

  static Event recommendServer(String content, String privkey) {
    return Event.from(kind: 2, tags: [], content: content, privkey: privkey);
  }
}
