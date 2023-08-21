/// nip 101 - alias exchange
///
import 'dart:convert';
import 'dart:math';

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

  static Event update(String myNewAliasPubkey, String toPubkey,
      String sessionId, String privkey) {
    return Event.from(
        kind: 10103,
        tags: [
          ['p', toPubkey, myNewAliasPubkey],
          ['e', sessionId]
        ],
        content: '',
        privkey: privkey);
  }

  static Event close(String toPubkey, String sessionId, String privkey) {
    return Event.from(
        kind: 10104,
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

  static String getRelay(List<List<String>> tags) {
    for (var tag in tags) {
      if (tag[0] == 'r') {
        return tag[1];
      }
    }
    return '';
  }

  static int getExpiration(Event event) {
    return Nip40.getExpiration(event);
  }

  static KeyExchangeSession getRequest(Event event) {
    return KeyExchangeSession(
        event.pubkey,
        event.content,
        getP(event.tags),
        '',
        event.id,
        event.kind,
        event.createdAt,
        getExpiration(event),
        getRelay(event.tags));
  }

  static KeyExchangeSession getAccept(Event event) {
    return KeyExchangeSession(
        getP(event.tags),
        '',
        event.pubkey,
        event.content,
        getE(event.tags),
        event.kind,
        event.createdAt,
        getExpiration(event),
        getRelay(event.tags));
  }

  static KeyExchangeSession getReject(Event event) {
    return KeyExchangeSession(
        getP(event.tags),
        '',
        event.pubkey,
        '',
        getE(event.tags),
        event.kind,
        event.createdAt,
        getExpiration(event),
        getRelay(event.tags));
  }

  static KeyExchangeSession getUpdate(Event event, String creator) {
    if (creator == event.pubkey) {
      return KeyExchangeSession(
          event.pubkey,
          event.content,
          getP(event.tags),
          '',
          event.id,
          event.kind,
          event.createdAt,
          getExpiration(event),
          getRelay(event.tags));
    } else {
      return KeyExchangeSession(
          getP(event.tags),
          '',
          event.pubkey,
          event.content,
          getE(event.tags),
          event.kind,
          event.createdAt,
          getExpiration(event),
          getRelay(event.tags));
    }
  }

  static KeyExchangeSession getClose(Event event, String creator) {
    if (creator == event.pubkey) {
      return KeyExchangeSession(event.pubkey, '', getP(event.tags), '', event.id, event.kind,
          event.createdAt, getExpiration(event), getRelay(event.tags));
    } else {
      return KeyExchangeSession(
          getP(event.tags),
          '',
          event.pubkey,
          '',
          getE(event.tags),
          event.kind,
          event.createdAt,
          getExpiration(event),
          getRelay(event.tags));
    }
  }
}

class KeyExchangeSession {
  String sessionId;

  String fromPubkey; // sender
  String fromAliasPubkey;
  String toPubkey; // receiver
  String toAliasPubkey;

  int kind;
  int createTime;

  int expiration;
  String relay;

  KeyExchangeSession(
      this.fromPubkey,
      this.fromAliasPubkey,
      this.toPubkey,
      this.toAliasPubkey,
      this.sessionId,
      this.kind,
      this.createTime,
      this.expiration,
      this.relay);
}
