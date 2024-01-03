
class Nip13{
  static int countLeadingZeroes(String hex) {
    int count = 0;
    for (int i = 0; i < hex.length; i++) {
      int nibble = int.parse(hex[i], radix: 16);
      if (nibble == 0) {
        count += 4;
      } else {
        count += (nibble.toUnsigned(32).bitLength - 1).abs();
        break;
      }
    }
    return count;
  }
}


