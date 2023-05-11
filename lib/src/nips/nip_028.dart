import 'dart:convert';
import 'package:nostr/nostr.dart';
import 'package:nostr/src/nips/nip_010.dart';

/// Public Chat & Channel
class Nip28 {
  static List<String> tagsToBadges(List<List<String>> tags) {
    List<String> result = [];
    for (var tag in tags) {
      if (tag[0] == "badges") result.add(tag[1]);
    }
    return result;
  }

  static List<List<String>> badgesToTags(List<String> badges) {
    List<List<String>> result = [];
    for (var badge in badges) {
      result.add(["badges", badge]);
    }
    return result;
  }

  static Channel getChannel(Event event) {
    if (event.kind == 40) {
      var content = jsonDecode(event.content);
      List<String> badges = tagsToBadges(event.tags);
      return Channel(event.id, content["name"], content["about"],
          content["picture"], event.pubkey, badges);
    }
    throw Exception("${event.kind} is not nip40 compatible");
  }

  static ChannelMessage getChannelMessage(Event event) {
    if (event.kind == 42) {
      var content = event.content;
      Thread thread = Nip10.fromTags(event.tags);
      String channelId = thread.root.eventId;
      return ChannelMessage(
          channelId, event.pubkey, content, thread, event.createdAt);
    }
    throw Exception("${event.kind} is not nip42 compatible");
  }

  static Event createChannel(String name, String about, String picture,
      List<String> badges, String privkey) {
    Map<String, dynamic> map = {
      'name': name,
      'about': about,
      'picture': picture,
    };
    String content = jsonEncode(map);
    List<List<String>> tags = badgesToTags(badges);
    Event event =
        Event.from(kind: 40, tags: tags, content: content, privkey: privkey);
    return event;
  }

  static Event setChannelMetaData(String name, String about, String picture,
      List<String> badges, String channelId, String relayURL, String privkey) {
    Map<String, dynamic> map = {
      'name': name,
      'about': about,
      'picture': picture,
    };
    String content = jsonEncode(map);
    List<List<String>> tags = badgesToTags(badges);
    tags.add(["e", channelId, relayURL]);
    Event event =
        Event.from(kind: 41, tags: tags, content: content, privkey: privkey);
    return event;
  }

  static Event sendChannelMessage(
      String channelId, String content, Thread? thread, String privkey) {
    List<List<String>> tags = [];
    if (thread != null) {
      List<ETags> eTags = [thread.root];
      eTags.addAll(thread.replys);
      tags = Nip10.toTags(eTags, thread.ptags);
    }
    Event event =
        Event.from(kind: 42, tags: tags, content: content, privkey: privkey);
    return event;
  }

  static Event hideChannelMessage(
      String messageId, String reason, String privkey) {
    Map<String, dynamic> map = {
      'reason': reason,
    };
    String content = jsonEncode(map);
    List<List<String>> tags = [];
    tags.add(["e", messageId]);
    Event event =
        Event.from(kind: 43, tags: tags, content: content, privkey: privkey);
    return event;
  }

  static Event muteUser(String pubkey, String reason, String privkey) {
    Map<String, dynamic> map = {
      'reason': reason,
    };
    String content = jsonEncode(map);
    List<List<String>> tags = [];
    tags.add(["p", pubkey]);
    Event event =
        Event.from(kind: 44, tags: tags, content: content, privkey: privkey);
    return event;
  }
}

/// channel info
class Channel {
  /// channel create event id
  String channelId;

  String name;

  String about;

  String picture;

  /// kind40 pubkey
  String owner;

  /// only users with badges can send messages, avoid spam
  List<String> badges;

  /// Default constructor
  Channel(this.channelId, this.name, this.about, this.picture, this.owner,
      this.badges);
}

/// messages in channel
class ChannelMessage {
  String channelId;
  String sender;
  String content;
  Thread thread;
  int createTime;

  ChannelMessage(
      this.channelId, this.sender, this.content, this.thread, this.createTime);
}
