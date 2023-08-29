/// nip 101 - Key exchange
import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

class Nip101 {
  static Event request(String myAliasPubkey, String toPubkey, String privkey,
      {int? expiration, int? interval, String? relay}) {
    Map map = {};
    String content = '';
    if (expiration != null && expiration > 0) map["expiration"] = expiration;
    if (interval != null && interval > 0) map["interval"] = interval;
    if (relay != null && relay.isNotEmpty) map["r"] = relay;
    if (map.isNotEmpty) content = jsonEncode(map);

    return Event.from(
        kind: 10100,
        tags: [
          ['p', toPubkey, myAliasPubkey]
        ],
        content: content,
        privkey: privkey);
  }

  static Event accept(
      String myAliasPubkey, String toPubkey, String sessionId, String privkey) {
    return Event.from(
        kind: 10101,
        tags: [
          ['p', toPubkey, myAliasPubkey],
          ['e', sessionId]
        ],
        content: '',
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

  static Event update(String myNewAliasPubkey, String toPubkey,
      String sessionId, String privkey) {
    return Event.from(
        kind: 10104,
        tags: [
          ['p', toPubkey, myNewAliasPubkey],
          ['e', sessionId]
        ],
        content: '',
        privkey: privkey);
  }

  static KeyExchangeSession decode(Event event) {
    late String fromAliasPubkey, toPubkey, sessionId;
    for (var tag in event.tags) {
      if (tag[0] == 'p' && tag.length > 2) {
        toPubkey = tag[1];
        fromAliasPubkey = tag[2];
      }
      if (tag[0] == 'e' && tag.length > 1) {
        sessionId = tag[1];
      }
    }
    if (event.kind == 10100) {
      sessionId = event.id;
    }
    else if(event.kind == 10103){
      fromAliasPubkey = '';
    }
    int? expiration, interval;
    String? relay;
    if (event.content.isNotEmpty) {
      Map map = jsonDecode(event.content);
      if (map.isNotEmpty) {
        expiration = map["expiration"];
        interval = map["interval"];
        relay = map["relay"].toString();
      }
    }
    return KeyExchangeSession(event.pubkey, fromAliasPubkey, toPubkey,
        sessionId, event.kind, event.createdAt, expiration, interval, relay);
  }

  static KeyExchangeSession getRequest(Event event) {
    if (event.kind == 10100) {
      return decode(event);
    }
    throw Exception("${event.kind} is not nip101 compatible");
  }

  static KeyExchangeSession getAccept(Event event) {
    if (event.kind == 10101) {
      return decode(event);
    }
    throw Exception("${event.kind} is not nip101 compatible");
  }

  static KeyExchangeSession getReject(Event event) {
    if (event.kind == 10102) {
      return decode(event);
    }
    throw Exception("${event.kind} is not nip101 compatible");
  }

  static KeyExchangeSession getClose(Event event) {
    if (event.kind == 10103) {
      return decode(event);
    }
    throw Exception("${event.kind} is not nip101 compatible");
  }

  static KeyExchangeSession getUpdate(Event event) {
    if (event.kind == 10104) {
      return decode(event);
    }
    throw Exception("${event.kind} is not nip101 compatible");
  }
}

class KeyExchangeSession {
  String sessionId;
  int kind;
  int createTime;

  String fromPubkey; // sender
  String fromAliasPubkey;
  String toPubkey; // receiver

  int? expiration;
  int? interval;
  String? relay;

  KeyExchangeSession(
      this.fromPubkey,
      this.fromAliasPubkey,
      this.toPubkey,
      this.sessionId,
      this.kind,
      this.createTime,
      this.expiration,
      this.interval,
      this.relay);
}
