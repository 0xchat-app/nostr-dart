/// nip 104 - MLS
import 'package:nostr_core_dart/nostr.dart';

class Nip104 {
  static Future<Event> encodeKeyPackageEvent(String ciphersuite, List<String> extensions,
      String signing_key, List<String> relays, String myPubkey, String privkey,
      {String mlsVersion = '1.0', String client = '0xchat'}) async {
    var tags = [
      ['mls_protocol_version', mlsVersion],
      ['ciphersuite', ciphersuite],
      ['extensions', ...extensions],
      ['signing_key', signing_key],
      ['relays', ...relays],
      ['client', client],
      ['-']
    ];
    return await Event.from(kind: 443, tags: tags, content: '', pubkey: myPubkey, privkey: privkey);
  }

  static decodePackageEvent(Event event) {
    String pubkey;
    int createTime;
    late String mls_protocol_version;
    late String ciphersuite;
    late List<String> extensions;
    late String signing_key;
    late List<String> relays;
    late String client;
    for (var tag in event.tags) {
      if (tag[0] == 'mls_protocol_version') mls_protocol_version = tag[1];
      if (tag[0] == 'ciphersuite') ciphersuite = tag[1];
      if (tag[0] == 'extensions') extensions = tag.sublist(1);
      if (tag[0] == 'signing_key') signing_key = tag[1];
      if (tag[0] == 'relays') relays = tag.sublist(1);
      if (tag[0] == 'client') client = tag[1];
    }
    pubkey = event.pubkey;
    createTime = event.createdAt;
    return KeyPackageEvent(pubkey, createTime, mls_protocol_version, ciphersuite, extensions,
        signing_key, relays, client);
  }

  static Future<Event> encodeWelcomeEvent(
      String welcome, List<String> relays, String myPubkey, String privkey) async {
    var tags = [
      ['relays', ...relays],
    ];
    Event event = await Event.from(
        kind: 444, tags: tags, content: welcome, pubkey: myPubkey, privkey: privkey);
    event.sig = '';
    return event;
  }

  static decodeWelcomeEvent(Event event) {
    String pubkey;
    int createTime;
    String welcome;
    late List<String> relays;
    for (var tag in event.tags) {
      if (tag[0] == 'relays') relays = tag.sublist(1);
    }
    pubkey = event.pubkey;
    createTime = event.createdAt;
    welcome = event.content;
    return WelcomeEvent(pubkey, createTime, relays, welcome);
  }

  static Future<Event> encodeGroupEvent(
      String message, String groupId, String myPubkey, String privkey) async {
    var tags = [
      ['h', groupId],
    ];
    Event event = await Event.from(
        kind: 445, tags: tags, content: message, pubkey: myPubkey, privkey: privkey);
    event.sig = '';
    return event;
  }

  static decodeGroupEvent(Event event) {
    String pubkey;
    int createTime;
    late String groupId;
    String message;
    for (var tag in event.tags) {
      if (tag[0] == 'h') groupId = tag[1];
    }
    pubkey = event.pubkey;
    createTime = event.createdAt;
    message = event.content;
    return GroupEvent(pubkey, createTime, groupId, message);
  }
}

class KeyPackageEvent {
  String pubkey;
  int createTime;
  String mls_protocol_version;
  String ciphersuite;
  List<String> extensions;
  String signing_key;
  List<String> relays;
  String client;

  KeyPackageEvent(this.pubkey, this.createTime, this.mls_protocol_version, this.ciphersuite,
      this.extensions, this.signing_key, this.relays, this.client);
}

class WelcomeEvent {
  String pubkey;
  int createTime;
  List<String> relays;
  String welcome;

  WelcomeEvent(this.pubkey, this.createTime, this.relays, this.welcome);
}

class GroupEvent {
  String pubkey;
  int createTime;
  String groupId;
  String message;

  GroupEvent(this.pubkey, this.createTime, this.groupId, this.message);
}
