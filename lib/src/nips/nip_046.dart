import 'dart:convert';
import 'dart:core';
import 'package:nostr_core_dart/nostr.dart';

class Nip46 {
  static RemoteSignerConnection parseBunkerUri(String uri) {
    RemoteSignerConnection remoteSignerConnection = RemoteSignerConnection('', [], null);

    if (!uri.startsWith('bunker://')) {
      throw ArgumentError('Invalid bunker URI format.');
    }

    final parts = uri.substring(9).split('?');
    if (parts.isEmpty || parts[0].isEmpty) {
      throw ArgumentError('Missing remote signer pubkey.');
    }
    remoteSignerConnection.pubkey = parts[0];

    if (parts.length > 1) {
      final queryParams = parts[1].split('&');
      for (var param in queryParams) {
        final keyValue = param.split('=');
        if (keyValue.length == 2) {
          final key = keyValue[0];
          final value = keyValue[1];

          if (key == 'relay') {
            remoteSignerConnection.relays.add(value);
          }
          if (key == 'secret') {
            remoteSignerConnection.secret = value;
          }
        }
      }
    }

    return remoteSignerConnection;
  }

  static String generateNostrConnectUri({
    required String clientPubkey,
    required List<String> relays,
    required Map<String, dynamic> metadata,
    required String secret,
  }) {
    if (clientPubkey.isEmpty) {
      throw ArgumentError('Client public key cannot be empty.');
    }
    if (relays.isEmpty) {
      throw ArgumentError('At least one relay must be provided.');
    }
    if (metadata.isEmpty) {
      throw ArgumentError('Metadata cannot be empty.');
    }
    if (secret.isEmpty) {
      throw ArgumentError('Secret cannot be empty.');
    }

    final encodedMetadata = Uri.encodeComponent(metadataToJson(metadata));

    final relayParams = relays.map((relay) => 'relay=$relay').join('&');

    return 'nostrconnect://$clientPubkey?$relayParams&metadata=$encodedMetadata&secret=$secret';
  }

  static String metadataToJson(Map<String, dynamic> metadata) {
    try {
      return const JsonEncoder().convert(metadata);
    } catch (e) {
      throw ArgumentError('Invalid metadata format: $e');
    }
  }

  static Future<Event> encode(
      String remoteSigner, String id, NIP46Command command, String pubkey, String privkey) async {
    var content = {'id': id, 'method': command.type.toString(), 'params': command.params};
    var encryptedContent =
        await Nip4.encryptContent(jsonEncode(content), remoteSigner, pubkey, privkey);
    return Event.from(
        kind: 24133,
        tags: [
          ["p", remoteSigner]
        ],
        content: encryptedContent,
        pubkey: pubkey,
        privkey: privkey);
  }

  static Future<NIP46CommandResult> decode(Event event, String myPubkey, String privkey) async {
    if (event.kind == 24133) {
      String encryptedContent = event.content;
      String content = await Nip4.decryptContent(encryptedContent, event.pubkey, myPubkey, privkey);
      return NIP46CommandResult.fromJson(jsonDecode(content));
    }
    throw Exception("${event.kind} is not nip46 compatible");
  }
}

class RemoteSignerConnection {
  String pubkey;
  List<String> relays;
  String? secret;
  String? clientPubkey;
  String? clientPrivkey;

  RemoteSignerConnection(this.pubkey, this.relays, this.secret);
}

enum CommandType {
  connect,
  signEvent,
  ping,
  getRelays,
  getPublicKey,
  nip04Encrypt,
  nip04Decrypt,
  nip44Encrypt,
  nip44Decrypt,
}

class NIP46Command {
  final CommandType type;
  final List<dynamic> params;

  NIP46Command({
    required this.type,
    required this.params,
  });

  // Factory constructors for each command type for better usability
  factory NIP46Command.connect(
    String remoteSignerPubkey, [
    String? optionalSecret,
    List<String>? optionalRequestedPermissions,
  ]) {
    return NIP46Command(
      type: CommandType.connect,
      params: [
        remoteSignerPubkey,
        optionalSecret,
        optionalRequestedPermissions,
      ],
    );
  }

  factory NIP46Command.signEvent(Map<String, dynamic> event) {
    return NIP46Command(
      type: CommandType.signEvent,
      params: [event],
    );
  }

  factory NIP46Command.ping() {
    return NIP46Command(
      type: CommandType.ping,
      params: [],
    );
  }

  factory NIP46Command.getRelays() {
    return NIP46Command(
      type: CommandType.getRelays,
      params: [],
    );
  }

  factory NIP46Command.getPublicKey() {
    return NIP46Command(
      type: CommandType.getPublicKey,
      params: [],
    );
  }

  factory NIP46Command.nip04Encrypt(String thirdPartyPubkey, String plaintext) {
    return NIP46Command(
      type: CommandType.nip04Encrypt,
      params: [thirdPartyPubkey, plaintext],
    );
  }

  factory NIP46Command.nip04Decrypt(String thirdPartyPubkey, String ciphertext) {
    return NIP46Command(
      type: CommandType.nip04Decrypt,
      params: [thirdPartyPubkey, ciphertext],
    );
  }

  factory NIP46Command.nip44Encrypt(String thirdPartyPubkey, String plaintext) {
    return NIP46Command(
      type: CommandType.nip44Encrypt,
      params: [thirdPartyPubkey, plaintext],
    );
  }

  factory NIP46Command.nip44Decrypt(String thirdPartyPubkey, String ciphertext) {
    return NIP46Command(
      type: CommandType.nip44Decrypt,
      params: [thirdPartyPubkey, ciphertext],
    );
  }
}

class NIP46CommandResult {
  final String id;
  final CommandType command;
  final dynamic result;
  final String? error;

  NIP46CommandResult({
    required this.id,
    required this.command,
    this.result,
    this.error,
  });

  static NIP46CommandResult fromResponse(
    String id,
    CommandType command,
    dynamic response, [
    String? error,
  ]) {
    if (error != null) {
      return NIP46CommandResult(id: id, command: command, error: error);
    }

    switch (command) {
      case CommandType.connect:
        if (response is String && (response == "ack" || response.isNotEmpty)) {
          return NIP46CommandResult(id: id, command: command, result: response);
        }
        break;

      case CommandType.signEvent:
        if (response is String) {
          return NIP46CommandResult(
              id: id, command: command, result: response); // JSON Stringified event
        }
        break;

      case CommandType.ping:
        if (response == "pong") {
          return NIP46CommandResult(id: id, command: command, result: response);
        }
        break;

      case CommandType.getRelays:
        if (response is Map<String, Map<String, bool>>) {
          return NIP46CommandResult(id: id, command: command, result: response);
        }
        break;

      case CommandType.getPublicKey:
        if (response is String) {
          return NIP46CommandResult(id: id, command: command, result: response);
        }
        break;

      case CommandType.nip04Encrypt:
      case CommandType.nip44Encrypt:
        if (response is String) {
          return NIP46CommandResult(id: id, command: command, result: response); // Ciphertext
        }
        break;

      case CommandType.nip04Decrypt:
      case CommandType.nip44Decrypt:
        if (response is String) {
          return NIP46CommandResult(id: id, command: command, result: response); // Plaintext
        }
        break;
    }

    throw Exception("Invalid response for command $command: $response");
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "command": command.toString().split('.').last,
      "result": result,
      "error": error,
    };
  }

  factory NIP46CommandResult.fromJson(Map<String, dynamic> json) {
    return NIP46CommandResult(
      id: json['id'],
      command:
          CommandType.values.firstWhere((e) => e.toString().split('.').last == json['command']),
      result: json['result'],
      error: json['error'],
    );
  }

  @override
  String toString() {
    return toJson().toString();
  }
}