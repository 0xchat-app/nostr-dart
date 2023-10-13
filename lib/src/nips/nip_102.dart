/// nip 102 - simple moderated group
/// https://github.com/water783/nips/blob/group-chats/simple-moderated-group.md

import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

class Nip102 {
  static String _toContent(String groupName, String? description, String? image,
      List<String>? pinned) {
    Map map = {"name": groupName};
    if (description != null) map["description"] = description;
    if (image != null) map["image"] = image;
    if (pinned != null) map["pinned"] = pinned;
    return jsonEncode(map);
  }

  static List<List<String>> _toTags(String groupKey, String owner,
      List<String> members, List<String>? relays) {
    List<List<String>> result = [];
    result.add(['g', groupKey]);
    result.add(['m', owner, 'owner']);
    for (var m in members) {
      result.add(["m", m]);
    }
    if (relays != null) {
      var r = ['r'];
      for (var relay in relays) {
        r.add(relay);
      }
      result.add(r);
    }
    return result;
  }

  static Event metadata(String groupKey, String groupName, List<String> members,
      String owner, String privkey,
      {String? description,
      String? image,
      List<String>? pinned,
      List<String>? relays}) {
    return Event.from(
        kind: 480,
        tags: _toTags(groupKey, owner, members, relays),
        content: _toContent(groupName, description, image, pinned),
        privkey: privkey);
  }

  static Event invite(String groupKey, String content, String privkey) {
    return Event.from(
        kind: 481,
        tags: [
          ['g', groupKey],
          ['type', 'invite']
        ],
        content: content,
        privkey: privkey);
  }

  static Event request(String groupKey, String content, String privkey) {
    return Event.from(
        kind: 481,
        tags: [
          ['g', groupKey],
          ['type', 'request']
        ],
        content: content,
        privkey: privkey);
  }

  static Event join(String groupKey, String content, String privkey) {
    return Event.from(
        kind: 481,
        tags: [
          ['g', groupKey],
          ['type', 'join']
        ],
        content: content,
        privkey: privkey);
  }

  static Event add(String groupKey, String content, String privkey) {
    return Event.from(
        kind: 481,
        tags: [
          ['g', groupKey],
          ['type', 'add']
        ],
        content: content,
        privkey: privkey);
  }

  static Event leave(String groupKey, String content, String privkey) {
    return Event.from(
        kind: 481,
        tags: [
          ['g', groupKey],
          ['type', 'leave']
        ],
        content: content,
        privkey: privkey);
  }

  static Event remove(String groupKey, String content, String privkey) {
    return Event.from(
        kind: 481,
        tags: [
          ['g', groupKey],
          ['type', 'remove']
        ],
        content: content,
        privkey: privkey);
  }

  static Event message(
      String groupKey, String content, String replyId, String privkey) {
    List<List<String>> tags = Nip4.toTags(groupKey, replyId);
    return Event.from(kind: 14, tags: tags, content: content, privkey: privkey);
  }

  static GroupMetadata getMetadata(Event event) {
    if (event.kind == 480) {
      try {
        Map map = jsonDecode(event.content);
        String name = map['name'] ?? '';
        String? description = map['description'];
        String? image = map['image'];
        List<String>? pinned =
            (map['pinned'] as List).map((item) => item.toString()).toList();

        String? groupKey, owner;
        List<String> members = [];
        List<String> relays = [];
        for (var tag in event.tags) {
          if (tag[0] == "g") groupKey = tag[1];
          if (tag[0] == "r" && tag.length > 1) {
            for (var i = 1; i < tag.length; ++i) {
              relays.add(tag[i]);
            }
          }
          if (tag[0] == "m") {
            if (tag.length > 2 && tag[2] == 'owner') owner = tag[1];
            members.add(tag[1]);
          }
        }
        return GroupMetadata(groupKey ?? '', owner ?? '', name, event.createdAt,
            members, description, image, pinned, relays);
      } catch (e) {
        throw Exception(e);
      }
    }
    throw Exception("${event.kind} is not nip102 compatible");
  }

  static GroupActionsType _typeToActions(String type) {
    switch (type) {
      case 'invite':
        return GroupActionsType.invite;
      case 'request':
        return GroupActionsType.request;
      case 'join':
        return GroupActionsType.join;
      case 'add':
        return GroupActionsType.add;
      case 'leave':
        return GroupActionsType.leave;
      case 'remove':
        return GroupActionsType.remove;
      default:
        return GroupActionsType.request;
    }
  }

  static GroupActions getActions(Event event) {
    if (event.kind == 481) {
      String? groupKey, type;
      for (var tag in event.tags) {
        if (tag[0] == "g") groupKey = tag[1];
        if (tag[0] == "type") type = tag[1];
      }
      return GroupActions(groupKey ?? '', event.pubkey,
          _typeToActions(type ?? ''), event.createdAt, event.content);
    }
    throw Exception("${event.kind} is not nip102 compatible");
  }

  static EDMessage getMessage(Event event) {
    if (event.kind == 14) {
      String groupKey = '';
      String replyId = "";
      String subContent = event.content;
      for (var tag in event.tags) {
        if (tag[0] == "g") groupKey = tag[1];
        if (tag[0] == "e") replyId = tag[1];
        if (tag[0] == "subContent") subContent = tag[1];
      }
      return EDMessage(
          event.pubkey, groupKey, event.createdAt, subContent, replyId);
    }
    throw Exception("${event.kind} is not nip102 compatible");
  }
}

class GroupMetadata {
  String groupKey;
  String owner;
  String name;
  int updateTime;
  List<String> members;
  String? description;
  String? image;
  List<String>? pinned;
  List<String>? relays;

  GroupMetadata(this.groupKey, this.owner, this.name, this.updateTime,
      this.members, this.description, this.image, this.pinned, this.relays);
}

enum GroupActionsType { invite, request, join, add, leave, remove }

class GroupActions {
  String groupKey;
  String pubkey;
  GroupActionsType state;
  int createAt;
  String content;

  GroupActions(
      this.groupKey, this.pubkey, this.state, this.createAt, this.content);
}
