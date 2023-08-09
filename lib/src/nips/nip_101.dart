/// nip 101 - alias exchange
///
import 'package:nostr_core_dart/nostr.dart';

class Nip101 {
  static Event request(String myAliasPubkey, String toPubkey, String privkey) {
    return Event.from(
        kind: 10100,
        tags: [
          ['p', toPubkey]
        ],
        content: myAliasPubkey,
        privkey: privkey);
  }

  static Event accept(
      String myAliasPubkey, String toPubkey, String sessionId, String privkey) {
    return Event.from(
        kind: 10101,
        tags: [
          ['p', toPubkey],
          ['e', sessionId]
        ],
        content: myAliasPubkey,
        privkey: privkey);
  }

  static Event reject(String toPubkey, String sessionId, String privkey) {
    return Event.from(
        kind: 10102,
        tags: [
          ['p', toPubkey],
          ['e', sessionId]
        ],
        content: '',
        privkey: privkey);
  }

  static Event close(String toPubkey, String sessionId, String privkey) {
    return Event.from(
        kind: 10103,
        tags: [
          ['p', toPubkey],
          ['e', sessionId]
        ],
        content: '',
        privkey: privkey);
  }

  static String getP(List<List<String>> tags) {
    for (var tag in tags) {
      if (tag[0] == 'p') {
        return tag[1];
      }
    }
    return '';
  }

  static String getE(List<List<String>> tags) {
    for (var tag in tags) {
      if (tag[0] == 'e') {
        return tag[1];
      }
    }
    return '';
  }

  static Alias getRequest(Event event) {
    return Alias(event.pubkey, event.content, getP(event.tags), '', event.id,
        event.kind, event.createdAt);
  }

  static Alias getAccept(Event event) {
    return Alias(getP(event.tags), '', event.pubkey, event.content,
        getE(event.tags), event.kind, event.createdAt);
  }

  static Alias getReject(Event event) {
    return Alias(getP(event.tags), '', event.pubkey, '', getE(event.tags),
        event.kind, event.createdAt);
  }

  static Alias getClose(Event event, String creator) {
    if (creator == event.pubkey) {
      return Alias(event.pubkey, '', getP(event.tags), '', event.id, event.kind,
          event.createdAt);
    } else {
      return Alias(getP(event.tags), '', event.pubkey, '', getE(event.tags),
          event.kind, event.createdAt);
    }
  }
}

class Alias {
  String sessionId;

  String fromPubkey; // session creator
  String fromAliasPubkey;
  String toPubkey; // session counterparty
  String toAliasPubkey;

  int kind;
  int createTime;

  Alias(this.fromPubkey, this.fromAliasPubkey, this.toPubkey,
      this.toAliasPubkey, this.sessionId, this.kind, this.createTime);
}
