import "dart:math";
import "package:quiver/core.dart";

int calculate() {
  return 6 * 7;
}

Optional<int> randomNumber() {
  final r = Random.secure().nextInt(100);
  if (r < 50) {
    return new Optional.absent();
  }

  return new Optional.of(r);
}


