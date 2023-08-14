import 'package:nostr_core_dart/nostr.dart';

/// Expiration Timestamp
class Nip40 {
  static int getExpiration(Event event) {
    for (var tag in event.tags) {
      if (tag[0] == 'expiration') {
        return int.parse(tag[1]);
      }
    }
    return 0;
  }

  static bool expired(Event event) {
    int expiredTime = getExpiration(event);
    return expiredTime > 0 && expiredTime < currentUnixTimestampSeconds();
  }
}
