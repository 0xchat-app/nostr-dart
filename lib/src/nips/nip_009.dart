import 'package:nostr_core_dart/nostr.dart';

/// Event Deletion
class Nip9 {
  static List<List<String>> toTags(List<String> events) {
    List<List<String>> result = [];
    for (var event in events) {
      result.add(["e", event]);
    }
    return result;
  }

  static Event encode(List<String> events, String content, String privkey) {
    return Event.from(
        kind: 5, tags: toTags(events), content: content, privkey: privkey);
  }

  static DeleteEvent? toDeleteEvent(Event event) {
    List<String> deleteEvents = [];
    for (var tag in event.tags) {
      if (tag[0] == "e") deleteEvents.add(tag[1]);
    }
    return DeleteEvent(
        event.pubkey, deleteEvents, event.content, event.createdAt);
  }

  static decode(Event event) {
    if (event.kind == 5) {
      return toDeleteEvent(event);
    }
    throw Exception("${event.kind} is not nip9 compatible");
  }
}

class DeleteEvent {
  String pubkey;
  List<String> deleteEvents;
  String reason;
  int deleteTime;

  DeleteEvent(this.pubkey, this.deleteEvents, this.reason, this.deleteTime);
}
