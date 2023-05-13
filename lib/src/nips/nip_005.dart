import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';
import 'package:http/http.dart' as http;

/// Mapping Nostr keys to DNS-based internet identifiers
class Nip5 {
  ///```It will make a GET request to https://example.com/.well-known/nostr.json?name=bob and get back a response that will look like
  ///{
  ///   "names": {
  ///     "bob": "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9"
  ///   },
  ///   "relays": {
  ///     "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9": [ "wss://relay.example.com", "wss://relay2.example.com" ]
  ///   }
  /// }
  static Future<DNS?> getDNS(String name, String domain) async {
    final response = await http
        .get(Uri.parse('https://$domain/.well-known/nostr.json?name=$name'));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      String pubkey = jsonResponse["names"][name];
      List<String> relays = jsonResponse["relays"][pubkey];
      return DNS(name, domain, pubkey, relays);
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
  }

  static Event setDNS(String name, String domain, String privkey) {
    assert(isValidName(name) == true);
    String content = generateContent(name, domain);
    return Event.from(kind: 0, tags: [], content: content, privkey: privkey);
  }

  static bool isValidName(String input) {
    RegExp regExp = RegExp(r'^[a-z0-9_]+$');
    return regExp.hasMatch(input);
  }

  static String generateContent(String name, String domain) {
    Map<String, dynamic> map = {
      'name': name,
      'nip5': '$name@$domain',
    };

    return jsonEncode(map);
  }
}

///
class DNS {
  String name;

  String domain;

  String pubkey;

  List<String> relays;

  /// Default constructor
  DNS(this.name, this.domain, this.pubkey, this.relays);
}
