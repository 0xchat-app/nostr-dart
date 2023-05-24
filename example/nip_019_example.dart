import 'package:nostr_core_dart/nostr.dart';

void main() {
  var sender = Keychain.generate();
  print(sender.public);
  String pubKeyHex = sender.public;
  final bech32PubKey = Nip19.encodePubkey("3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d");
  print('Bech32 encoded public key: $bech32PubKey');

  final decodedData = Nip19.decodePubkey(bech32PubKey);
  print('Decoded data: $decodedData');
}
