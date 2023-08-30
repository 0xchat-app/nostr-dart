import 'package:nostr_core_dart/nostr.dart';

Future<void> main() async {
  var sender = Keychain.generate();
  var receiver = Keychain.generate();

  Event dmEvent = await Nip24.encodeSealedGossipDM(receiver.public, 'test content', '', sender.private);

  Event sealEvent = await Nip24.decode(dmEvent, receiver.private);
  EDMessage message = await Nip24.decodeSealedGossipDM(sealEvent, receiver.public, receiver.private);
  print(message.content);

  // Event realEvent = await Nip44.encode(receiver.public, "sljdk", '', sender.private);
  //
  // print(realEvent.toJson());
  //
  // Event wrapEvent = await Nip24.encodeSealedGossip(realEvent, receiver.public, random.private);
  //
  // print(wrapEvent.toJson());
  //
  // Event decodeEvent = await Nip24.decodeSealedGossip(wrapEvent, receiver.private);
  //
  // print('decodeEvent: ${decodeEvent.toJson()}' );
  //
  // EDMessage message = await Nip44.decode(decodeEvent, receiver.public, receiver.private);
  //
  // print(message.content);
}