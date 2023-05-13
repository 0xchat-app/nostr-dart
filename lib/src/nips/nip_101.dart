/// nip 101 - alias exchange
///
import 'dart:convert';
import 'dart:typed_data';
import 'package:kepler/kepler.dart';
import 'package:nostr_core_dart/nostr.dart';

class Nip101 {
  static String encryptContent(String fromPubkey, String fromAliasPrivkey,
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

  static String aliasPrivkey(String toPubkey, String privkey) {
    final secretIV = Kepler.byteSecret(privkey, '02$toPubkey');
    Uint8List tweak = Uint8List.fromList(secretIV[0]);
    Uint8List aliasPrivateKey = tweakAdd(hexToBytes(privkey), tweak);
    return bytesToHex(aliasPrivateKey);
  }

  /// encrypt share secret = (fromAliasPrivkey, toPubkey)
  /// decrypt share secret = (fromPrivkey, toAliasPubkey)
  /// send request then listen event: p = fromAliasPubkey
  static Event request(String fromPubkey, String fromAliasPubkey,
      String fromAliasPrivkey, String toPubkey, String requestContent) {
    return Event.from(
        kind: 10100,
        tags: [
          ['p', toPubkey]
        ],
        content: encryptContent(
            fromPubkey, fromAliasPrivkey, toPubkey, requestContent),
        privkey: fromAliasPrivkey);
  }

  /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  static Event accept(String fromPubkey, String fromAliasPubkey,
      String fromAliasPrivkey, String toAliasPubkey) {
    return Event.from(
        kind: 10101,
        tags: [
          ['p', toAliasPubkey]
        ],
        content: encryptContent(
            fromPubkey, fromAliasPrivkey, toAliasPubkey, "accept"),
        privkey: fromAliasPrivkey);
  }

  /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  static Event reject(String fromPubkey, String fromAliasPubkey,
      String fromAliasPrivkey, String toAliasPubkey) {
    return Event.from(
        kind: 10102,
        tags: [
          ['p', toAliasPubkey]
        ],
        content: encryptContent(
            fromPubkey, fromAliasPrivkey, toAliasPubkey, "reject"),
        privkey: fromAliasPrivkey);
  }

  /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
  static Event remove(String fromPubkey, String fromAliasPubkey,
      String fromAliasPrivkey, String toAliasPubkey) {
    return Event.from(
        kind: 10103,
        tags: [
          ['p', toAliasPubkey]
        ],
        content: encryptContent(
            fromPubkey, fromAliasPrivkey, toAliasPubkey, "remove"),
        privkey: fromAliasPrivkey);
  }

  static String getP(Event event) {
    if (event.tags != null &&
        event.tags[0].length > 1 &&
        event.tags[0][0] == 'p') {
      return event.tags[0][1];
    }
    return '';
  }

  static Alias getRequest(Event event, String pubkey, String privkey) {
    Map<String, dynamic> map = _deContent(event.content, privkey, event.pubkey);
    return Alias(
        pubkey, "", map['p'], event.pubkey, map['content'], event.kind);
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
