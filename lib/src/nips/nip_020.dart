import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

class Nip20 {
  static Ok? getOk(String okPayload) {
    var ok = Message.deserialize(okPayload);
    if(ok.type == 'OK'){
      var object = jsonDecode(ok.message);
      return Ok(object[0], object[1], object[2]);
    }
  }
}

class Ok {
  String eventId;
  bool status;
  String message;

  Ok(this.eventId, this.status, this.message);
}