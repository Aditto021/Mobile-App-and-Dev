import 'package:feriwala/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('names accept Bangla and ordinary punctuation', () {
    expect(Validators.nameValidator('মেহজাবীন রহমান'), isNull);
    expect(Validators.nameValidator("Anne-Marie O’Neill"), isNull);
    expect(Validators.nameValidator('1234'), isNotNull);
  });
  test('email accepts tagged addresses and modern domains', () {
    expect(Validators.emailValidation('aditi+shop@example.technology'), isNull);
    expect(Validators.emailValidation('aditi..shop@example.com'), isNotNull);
    expect(Validators.emailValidation('aditi@example .com'), isNotNull);
    expect(Validators.emailValidation('aditi@@example.com'), isNotNull);
  });
}
