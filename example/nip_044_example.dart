import 'package:nostr_core_dart/nostr.dart';

Future<void> main() async {
  var sender = Keychain.generate();
  print(sender.private);
  var receiver = Keychain.generate();
  print(receiver.public);
  Event event = await Nip44.encode(receiver.public, "SDKFS", "", sender.private);
  print(event.content);

  EDMessage edMessage = await Nip44.decode(event, receiver.public, receiver.private);
  print(edMessage.content);
}