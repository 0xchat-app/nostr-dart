import 'dart:convert';
import 'package:nostr/nostr.dart';

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
      String channelId = "";
      String replyId = "";
      String replyUser = "";
      for (var tag in event.tags) {
        if (tag[0] == "e" && tag[3] == "root") channelId = tag[1];
        if (tag[0] == "e" && tag[3] == "reply") replyId = tag[1];
        if (tag[0] == "p") replyUser = tag[1];
      }
      return ChannelMessage(event.id, channelId, replyId, replyUser, content);
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

  static Event sendChannelMessage(String content, String channelId,
      String replyId, String relayURL, String replayPubkey, String privkey) {
    List<List<String>> tags = [];
    tags.add(["e", channelId, relayURL, "root"]);
    if (replyId.isNotEmpty) tags.add(["e", replyId, relayURL, "reply"]);
    if (replayPubkey.isNotEmpty) tags.add(["p", relayURL, replayPubkey]);
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
  String replyId;
  String replyUser;
  String content;

  ChannelMessage(
      this.sender, this.channelId, this.replyId, this.replyUser, this.content);
}
