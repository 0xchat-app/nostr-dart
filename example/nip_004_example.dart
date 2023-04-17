import 'package:nostr/nostr.dart';

void main() async {
  var sender = Keychain.generate();
  print(sender.private);
  var receiver = Keychain.generate();
  print(receiver.public);
  Event event =
      Nip4.encode(sender.public, receiver.public, "content", "", sender.private);
  print(event.content);

  EDMessage edMessage = Nip4.decode(event, receiver.public, receiver.private);
  print(edMessage.content);
}
