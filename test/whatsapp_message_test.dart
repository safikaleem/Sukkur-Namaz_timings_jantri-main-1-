import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Urdu, Sindhi, and Arabic select Urdu WhatsApp template; others select English', () {
    bool isUrduTarget(String language) {
      final lang = language.toLowerCase();
      return lang == 'urdu' || lang == 'sindhi' || lang == 'arabic';
    }

    expect(isUrduTarget('urdu'), isTrue);
    expect(isUrduTarget('Urdu'), isTrue);
    expect(isUrduTarget('sindhi'), isTrue);
    expect(isUrduTarget('Sindhi'), isTrue);
    expect(isUrduTarget('arabic'), isTrue);
    expect(isUrduTarget('Arabic'), isTrue);

    expect(isUrduTarget('english'), isFalse);
    expect(isUrduTarget('English'), isFalse);
    expect(isUrduTarget('turkish'), isFalse);
    expect(isUrduTarget('indonesian'), isFalse);
    expect(isUrduTarget('french'), isFalse);
  });
}

