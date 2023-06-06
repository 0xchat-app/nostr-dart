import 'package:bech32/bech32.dart';
import 'package:convert/convert.dart';
import 'package:nostr_core_dart/nostr.dart';

/// bech32-encoded entities
class Nip19 {
  static encodePubkey(String pubkey) {
    return bech32Encode("npub", pubkey);
  }

  static encodePrivkey(String privkey) {
    return bech32Encode("nsec", privkey);
  }

  static encodeNote(String noteid) {
    return bech32Encode("note", noteid);
  }

  static String decodePubkey(String data) {
    Map map = bech32Decode(data);
    if (map["prefix"] == "npub") {
      return map["data"];
    } else {
      return "";
    }
  }

  static String decodePrivkey(String data) {
    Map map = bech32Decode(data);
    if (map["prefix"] == "nsec") {
      return map["data"];
    } else {
      return "";
    }
  }

  static String decodeNote(String data) {
    Map map = bech32Decode(data);
    if (map["prefix"] == "note") {
      return map["data"];
    } else {
      return "";
    }
  }

  static Map<String, dynamic> decodeProfile(String profile) {
    String pubkey = '';
    List<String> relays = [];
    final data =
        hexToBytes(bech32Decode(profile, maxLength: profile.length)['data']!);

    var index = 0;
    while (index < data.length) {
      var type = data[index++];
      var length = data[index++];

      var value = data.sublist(index, index + length);
      index += length;

      if (type == 0) {
        pubkey = bytesToHex(value);
      } else if (type == 1) {
        relays.add(String.fromCharCodes(value));
      }
    }

    return {'pubkey': pubkey, 'relays': relays};
  }

  static String encodeProfile(String pubkey, List<String> relays) {
    String result = '0020$pubkey';
    for (var relay in relays) {
      result = '${result}01';
      String value = relay.codeUnits
          .map((number) => number.toRadixString(16).padLeft(2, '0'))
          .join('');
      result =
          '$result${hexToBytes(value).length.toRadixString(16).padLeft(2, '0')}$value';
    }

    return bech32Encode('nprofile', result, maxLength: result.length);
  }
}

/// help functions

String bech32Encode(String prefix, String hexData, {int? maxLength}) {
  final data = hex.decode(hexData);
  final convertedData = convertBits(data, 8, 5, true);
  final bech32Data = Bech32(prefix, convertedData);
  if (maxLength != null) return bech32.encode(bech32Data, maxLength);
  return bech32.encode(bech32Data);
}

Map<String, String> bech32Decode(String bech32Data, {int? maxLength}) {
  final decodedData = maxLength != null
      ? bech32.decode(bech32Data, maxLength)
      : bech32.decode(bech32Data);
  final convertedData = convertBits(decodedData.data, 5, 8, false);
  final hexData = hex.encode(convertedData);

  return {'prefix': decodedData.hrp, 'data': hexData};
}

List<int> convertBits(List<int> data, int fromBits, int toBits, bool pad) {
  var acc = 0;
  var bits = 0;
  final maxv = (1 << toBits) - 1;
  final result = <int>[];

  for (final value in data) {
    if (value < 0 || value >> fromBits != 0) {
      throw Exception('Invalid value: $value');
    }
    acc = (acc << fromBits) | value;
    bits += fromBits;

    while (bits >= toBits) {
      bits -= toBits;
      result.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((acc << (toBits - bits)) & maxv);
    }
  } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0) {
    throw Exception('Invalid data');
  }

  return result;
}
