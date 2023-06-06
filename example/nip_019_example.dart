import 'package:nostr_core_dart/nostr.dart';

void main() {
  // var sender = Keychain.generate();
  // print(sender.public);
  // String pubKeyHex = sender.public;
  // final bech32PubKey = Nip19.encodePubkey("3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d");
  // print('Bech32 encoded public key: $bech32PubKey');
  //
  // final decodedData = Nip19.decodePubkey('npub1sftmass94ce5gx3uyvdzr6lv8cvhs8905ewf6hmjuns7yvea4p0qgd2fuq');
  // print('Decoded data: $decodedData');
  //
  //
  // Map map = bech32Decode('bech32Decode');

  String encodeProfile = Nip19.encodeProfile('3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d', ["wss://r.x.com", "wss://djbas.sadkb.com"]);
  print(encodeProfile);

  Map profile = Nip19.decodeProfile(encodeProfile);
  print(profile);
}
