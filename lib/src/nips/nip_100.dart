import 'package:nostr_core_dart/nostr.dart';
import 'package:bip340/bip340.dart' as bip340;

/// This NIP defines how to do WebRTC communication over nostr.
/// https://github.com/jacany/nips/blob/webrtc/100.md
///
enum SignalingState {
  disconnect,
  offer,
  answer,
  candidate,
}

class Signaling {
  String sender;
  String receiver;
  String content;
  SignalingState state;

  Signaling(this.sender, this.receiver, this.content, this.state);
}

class Nip100 {
  static Event close(String friend, String content, String privkey) {
    List<List<String>> tags = [];
    tags.add(['type', 'disconnect']);
    tags.add(['p', friend]);
    return Event.from(
        kind: 25050,
        tags: tags,
        content: Nip4.encryptContent(content, privkey, friend),
        privkey: privkey);
  }

  static Event offer(String friend, String content, String privkey) {
    List<List<String>> tags = [];
    tags.add(['type', 'offer']);
    tags.add(['p', friend]);
    return Event.from(
        kind: 25050,
        tags: tags,
        content: Nip4.encryptContent(content, privkey, friend),
        privkey: privkey);
  }

  static Event answer(String friend, String content, String privkey) {
    List<List<String>> tags = [];
    tags.add(['type', 'answer']);
    tags.add(['p', friend]);
    return Event.from(
        kind: 25050,
        tags: tags,
        content: Nip4.encryptContent(content, privkey, friend),
        privkey: privkey);
  }

  static Event candidate(String friend, String content, String privkey) {
    List<List<String>> tags = [];
    tags.add(['type', 'candidate']);
    tags.add(['p', friend]);
    return Event.from(
        kind: 25050,
        tags: tags,
        content: Nip4.encryptContent(content, privkey, friend),
        privkey: privkey);
  }

  static Signaling decode(Event event, String privkey) {
    if (event.kind == 25050) {
      String? type, friend;
      for (var tag in event.tags) {
        if (tag[0] == "p") friend = tag[1];
        if (tag[0] == "type") type = tag[1];
      }
      if (friend != null && friend == bip340.getPublicKey(privkey)) {
        try {
          return Signaling(
              event.pubkey,
              friend,
              Nip4.decryptContent(event.content, privkey, event.pubkey),
              typeToState(type!));
        } catch (e) {
          throw Exception(e);
        }
      } else {
        throw Exception("${event.kind} is not valid p2p calling event");
      }
    }
    throw Exception("${event.kind} is not nip100 compatible");
  }

  static SignalingState typeToState(String type) {
    switch (type) {
      case 'disconnect':
        return SignalingState.disconnect;
      case 'offer':
        return SignalingState.offer;
      case 'answer':
        return SignalingState.answer;
      case 'candidate':
        return SignalingState.candidate;
      default:
        throw Exception('not valid type');
    }
  }
}
