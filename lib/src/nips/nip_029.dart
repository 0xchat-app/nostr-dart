import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';

/// Relay-based Groups
class Nip29 {
  static Group decodeMetadata(Event event, String fromRelay) {
    if (event.kind != 39000) {
      throw Exception("${event.kind} is not nip29 compatible");
    }

    String groupId = '', name = '', picture = '', about = '';
    bool private = false;
    for (var tag in event.tags) {
      if (tag[0] == "d") {
        groupId = tag[1];
      }
      if (tag[0] == "name") {
        name = tag[1];
      }
      if (tag[0] == "picture") {
        picture = tag[1];
      }
      if (tag[0] == "about") {
        about = tag[1];
      }
      if (tag[0] == "public" || tag[0] == "open") {
        private = true;
      }
    }
    String id = '$fromRelay\'$groupId';
    return Group(id, fromRelay, event.pubkey, groupId, private, [], name, about,
        picture, null, [], 0, 0, null);
  }

  static List<GroupAdmin> decodeGroupAdmins(Event event, String groupId) {
    if (event.kind != 39001) {
      throw Exception("${event.kind} is not nip29 compatible");
    }

    List<GroupAdmin> admins = [];
    for (var tag in event.tags) {
      if (tag[0] == "d") {
        if (groupId != tag[1]) throw Exception("wrong groupId ${tag[1]}");
      }
      if (tag[0] == "p") {
        List<GroupActionKind> permissions = [];
        for (int i = 3; i < tag.length - 1; ++i) {
          permissions.add(GroupActionKind.fromString(tag[i]));
        }
        admins.add(GroupAdmin(tag[1], tag[2], permissions));
      }
    }
    return admins;
  }

  static List<String> decodeGroupMembers(Event event, String groupId) {
    if (event.kind != 39002) {
      throw Exception("${event.kind} is not nip29 compatible");
    }

    List<String> members = [];
    for (var tag in event.tags) {
      if (tag[0] == "d") {
        if (groupId != tag[1]) throw Exception("wrong groupId ${tag[1]}");
      }
      if (tag[0] == "p") members.add(tag[1]);
    }
    return members;
  }

  static List<String> getPrevious(List<List<String>> tags) {
    List<String> previous = [];
    for (var tag in tags) {
      if (tag[0] == 'previous') {
        for (int i = 1; i < tag.length - 1; ++i) {
          previous.add(tag[i]);
        }
        break;
      }
    }
    return previous;
  }

  static GroupNote decodeGroupNote(Event event) {
    if (event.kind != 11) {
      throw Exception("${event.kind} is not nip29 compatible");
    }
    Note note = Nip1.decodeNote(event);
    return GroupNote(note.groupId, note.nodeId, note, getPrevious(event.tags));
  }

  static GroupNote decodeGroupNoteReply(Event event) {
    if (event.kind != 12) {
      throw Exception("${event.kind} is not nip29 compatible");
    }
    Note note = Nip1.decodeNote(event);
    return GroupNote(note.groupId, note.nodeId, note, getPrevious(event.tags));
  }

  static GroupMessage decodeGroupMessage(Event event) {
    if (event.kind != 9 || event.kind != 10) {
      throw Exception("${event.kind} is not nip29 compatible");
    }
    var content = event.content;
    String groupId = '';
    for (var tag in event.tags) {
      if (tag[0] == "subContent") content = tag[1];
      if (tag[0] == "h") groupId = tag[1];
    }
    Thread thread = Nip10.fromTags(event.tags);
    List<String> previous = getPrevious(event.tags);
    return GroupMessage(groupId, event.id, event.pubkey, event.createdAt,
        thread, content, previous);
  }

  static GroupMessage decodeGroupMessageReply(Event event) {
    return decodeGroupMessage(event);
  }

  static Future<Event> encodeGroupNote(String groupId, String content,
      String pubkey, String privkey, List<String> previous,
      {List<String>? hashTags}) async {
    List<List<String>> tags = [];
    tags.add(['h', groupId]);
    if (previous.isNotEmpty) tags.add(['previous', ...previous]);
    if (hashTags != null) {
      for (var t in hashTags) {
        tags.add(['t', t]);
      }
    }
    return await Event.from(
        kind: 11,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
  }

  static Future<Event> encodeGroupNoteReply(String groupId, String content,
      String pubkey, String privkey, List<String> previous,
      {String? rootEvent,
      String? replyEvent,
      List<String>? replyUsers,
      List<String>? hashTags}) async {
    List<List<String>> tags = [];
    if (rootEvent != null) {
      ETag root = Nip10.rootTag(rootEvent, '');
      ETag? reply = replyEvent == null ? null : Nip10.replyTag(replyEvent, '');
      List<PTag> pTags = Nip10.pTags(replyUsers ?? [], []);
      Thread thread = Thread(root, reply, null, pTags);
      tags = Nip10.toTags(thread);
    }
    tags.add(['h', groupId]);
    if (previous.isNotEmpty) tags.add(['previous', ...previous]);
    if (hashTags != null) {
      for (var t in hashTags) {
        tags.add(['t', t]);
      }
    }

    return await Event.from(
        kind: 12,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
  }

  static Future<Event> encodeGroupMessage(String groupId, String content,
      List<String> previous, String pubkey, String privkey,
      {String? subContent}) async {
    List<List<String>> tags = [];
    tags.add(['h', groupId]);
    if (previous.isNotEmpty) tags.add(['previous', ...previous]);
    if (subContent != null && subContent.isNotEmpty) {
      tags.add(['subContent', subContent]);
    }
    Event event = await Event.from(
        kind: 9,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
    return event;
  }

  static Future<Event> encodeGroupMessageReply(String groupId, String content,
      List<String> previous, String pubkey, String privkey,
      {String? rootEvent,
      String? replyEvent,
      List<String>? replyUsers,
      String? subContent}) async {
    List<List<String>> tags = [];
    if (rootEvent != null) {
      ETag root = Nip10.rootTag(rootEvent, '');
      ETag? reply = replyEvent == null ? null : Nip10.replyTag(replyEvent, '');
      List<PTag> pTags = Nip10.pTags(replyUsers ?? [], []);
      Thread thread = Thread(root, reply, null, pTags);
      tags = Nip10.toTags(thread);
    }
    tags.add(['h', groupId]);
    if (previous.isNotEmpty) tags.add(['previous', ...previous]);

    if (subContent != null && subContent.isNotEmpty) {
      tags.add(['subContent', subContent]);
    }
    Event event = await Event.from(
        kind: 10,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
    return event;
  }

  static Future<Event> encodeGroupRequest(
      String groupId, String content, String pubkey, String privkey) async {
    List<List<String>> tags = [];
    tags.add(['h', groupId]);
    Event event = await Event.from(
        kind: 9021,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
    return event;
  }

  static Future<Event> encodeGroupAction(
      String groupId,
      GroupActionKind actionKind,
      String content,
      List<String> previous,
      String pubkey,
      String privkey) async {
    List<List<String>> tags = [];
    tags.add(['h', groupId]);
    if (previous.isNotEmpty) tags.add(['previous', ...previous]);
    Event event = await Event.from(
        kind: actionKind.kind,
        tags: tags,
        content: content,
        pubkey: pubkey,
        privkey: privkey);
    return event;
  }
}

enum GroupActionKind {
  addUser(9000, 'add-user'),
  removeUser(9001, 'remove-user'),
  editMetadata(9002, 'edit-metadata'),
  addPermission(9003, 'add-permission'),
  removePermission(9004, 'remove-permission'),
  deleteEvent(9005, 'delete-event'),
  editGroupStatus(9006, 'edit-group-status');

  final int kind;
  final String name;

  const GroupActionKind(this.kind, this.name);

  static GroupActionKind fromString(String name) {
    return GroupActionKind.values.firstWhere((element) => element.name == name,
        orElse: () => throw ArgumentError('Invalid permission name: $name'));
  }
}

class GroupAdmin {
  String pubkey;
  String role;
  List<GroupActionKind> permissions;

  GroupAdmin(this.pubkey, this.role, this.permissions);
}

/// groups info
class Group {
  String id; //<host>'<group-id>
  String relay;
  String relayPubkey;
  String groupId;
  bool private;
  List<GroupAdmin> mods;
  String name;
  String about;
  String picture;
  String? pinned;
  List<String> members;
  int level; // group level
  int point; // group point
  /// Clients MAY add additional metadata fields.
  Map<String, dynamic>? additional;

  /// Default constructor
  Group(
      this.id,
      this.relay,
      this.relayPubkey,
      this.groupId,
      this.private,
      this.mods,
      this.name,
      this.about,
      this.picture,
      this.pinned,
      this.members,
      this.level,
      this.point,
      this.additional);
}

class GroupNote {
  String groupId;
  String nodeId;
  Note note;
  List<String>? previous;

  GroupNote(this.groupId, this.nodeId, this.note, this.previous);
}

class GroupMessage {
  String groupId;
  String messageId;
  String pubkey;
  int createAt;
  Thread thread;
  String content;
  List<String>? previous;

  GroupMessage(this.groupId, this.messageId, this.pubkey, this.createAt,
      this.thread, this.content, this.previous);
}

class GroupJoinRequest {
  String requestId;
  String groupId;
  String pubkey;
  int createAt;
  String content;

  GroupJoinRequest(
      this.requestId, this.groupId, this.pubkey, this.createAt, this.content);
}
