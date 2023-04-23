/// nip 101 - alias exchange
///
import 'dart:convert';
import 'package:nostr/nostr.dart';

class Nip101 {
  static String _enContent(String fromPubkey, String fromAliasPrivkey,
      String toPubkey, String content) {
    Map<String, dynamic> map = {
      'p': fromPubkey,
      'content': content,
    };
    String encodeContent = jsonEncode(map);
    String enContent =
        Nip4.encryptContent(encodeContent, fromAliasPrivkey, toPubkey);
    return enContent;
  }

  static Map<String, dynamic> _deContent(
      String enContent, String privkey, String sender) {
    String content = Nip4.decryptContent(enContent, privkey, sender);
    return jsonDecode(content);
  }

  /// encrypt share secret = (fromAliasPrivkey, toPubkey)
  /// decrypt share secret = (fromPrivkey, toAliasPubkey)
  /// send request then listen event: p = fromAliasPubkey
  static Event request(String fromPubkey, String fromAliasPubkey,
      String fromAliasPrivkey, String toPubkey, String requestContent) {
    return Event.from(
        kind: 10100,
        tags: [],
        content:
            _enContent(fromPubkey, fromAliasPrivkey, toPubkey, requestContent),
        privkey: fromAliasPrivkey);
  }

  /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  static Event accept(String fromPubkey, String fromAliasPubkey,
      String fromAliasPrivkey, String toAliasPubkey) {
    return Event.from(
        kind: 10101,
        tags: [],
        content:
            _enContent(fromPubkey, fromAliasPrivkey, toAliasPubkey, "accept"),
        privkey: fromAliasPrivkey);
  }

  /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  static Event reject(String fromPubkey, String fromAliasPubkey,
      String fromAliasPrivkey, String toAliasPubkey) {
    return Event.from(
        kind: 10102,
        tags: [],
        content:
            _enContent(fromPubkey, fromAliasPrivkey, toAliasPubkey, "reject"),
        privkey: fromAliasPrivkey);
  }

  /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  static Event remove(String fromPubkey, String fromAliasPubkey,
      String fromAliasPrivkey, String toAliasPubkey) {
    return Event.from(
        kind: 10103,
        tags: [],
        content:
            _enContent(fromPubkey, fromAliasPrivkey, toAliasPubkey, "remove"),
        privkey: fromAliasPrivkey);
  }

  static Alias getRequest(
      Event event, String pubkey, String privkey, String aliasPubkey) {
    Map<String, dynamic> map = _deContent(event.content, privkey, event.pubkey);
    return Alias(pubkey, aliasPubkey, map['p'], event.pubkey, map['content'],
        event.kind);
  }

  static Alias getAccept(
      Event event, String pubkey, String aliasPubkey, String aliasPrikey) {
    Map<String, dynamic> map =
        _deContent(event.content, aliasPrikey, event.pubkey);
    return Alias(pubkey, aliasPubkey, map['p'], event.pubkey, map['content'],
        event.kind);
  }

  static Alias getReject(
      Event event, String pubkey, String aliasPubkey, String aliasPrikey) {
    Map<String, dynamic> map =
        _deContent(event.content, aliasPrikey, event.pubkey);
    return Alias(pubkey, aliasPubkey, map['p'], event.pubkey, map['content'],
        event.kind);
  }

  static Alias getRemove(
      Event event, String pubkey, String aliasPubkey, String aliasPrikey) {
    Map<String, dynamic> map =
        _deContent(event.content, aliasPrikey, event.pubkey);
    return Alias(pubkey, aliasPubkey, map['p'], event.pubkey, map['content'],
        event.kind);
  }
}

class Alias {
  String fromPubkey;
  String fromAliasPubkey;
  String toPubkey;
  String toAliasPubkey;

  String content;
  int kind;

  Alias(this.fromPubkey, this.fromAliasPubkey, this.toPubkey,
      this.toAliasPubkey, this.content, this.kind);
}
