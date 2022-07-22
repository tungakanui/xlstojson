import 'dart:math';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

int getRandomInt() {
  return _rnd.nextInt(1000);
}

double getRandomDouble() {
  return _rnd.nextDouble() * 1000;
}

bool getRandomBool() {
  return _rnd.nextBool();
}

DateTime getRandomDate() {
  return DateTime.now().subtract(Duration(days: _rnd.nextInt(5000)));
}

String getHtml() {
  return """
  <!DOCTYPE html>
<html>
<body>

<h1>My First Heading</h1>
<p>My first paragraph.</p>

</body>
</html>
  """;
}
