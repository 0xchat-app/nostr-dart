import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

// Used to deserialize any kind of message that a nostr client or relay can transmit.
class Message {
  late String type;
  late dynamic message;

// nostr message deserializer
  static Future<Message> deserialize(String payload) async {
    Message m = Message();
    dynamic data = jsonDecode(payload);
    var messages = ["EVENT", "REQ", "CLOSE", "CLOSED", "NOTICE", "EOSE", "OK", "AUTH"];
    assert(messages.contains(data[0]), "Unsupported payload (or NIP) : $data");

    m.type = data[0];
    switch (m.type) {
      case "EVENT":
        m.message = await Event.deserialize(data);
        break;
      case "REQ":
        m.message = Request.deserialize(data);
        break;
      case "CLOSE":
      case "CLOSED":
        m.message = Close.deserialize(data);
        break;
      case "AUTH":
        m.message = Auth.deserialize(data);
        break;
      default:
        m.message = jsonEncode(data.sublist(1));
        break;
    }
    return m;
  }
}
