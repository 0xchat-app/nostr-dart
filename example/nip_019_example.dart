import 'package:nostr/nostr.dart';

void main() {
  var sender = Keychain.generate();
  print(sender.public);
  String pubKeyHex = sender.public;
  final bech32PubKey = Nip19.encode('npub', pubKeyHex);
  print('Bech32 encoded public key: $bech32PubKey');

  final decodedData = Nip19.decode(bech32PubKey);
  print('Prefix: ${decodedData['prefix']}');
  print('Decoded data: ${decodedData['data']}');
}
