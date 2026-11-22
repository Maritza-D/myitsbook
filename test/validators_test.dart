import 'package:flutter_test/flutter_test.dart';
import 'package:myitsbook/core/utils/formatters.dart';

void main() {
  group('Formatters & Business Rules', () {
    test('formatRupiah formats positive values and Gratis for 0', () {
      expect(formatRupiah(0), 'Gratis');
      expect(formatRupiah(-500), 'Gratis');
      expect(formatRupiah(7500), 'Rp 7.500');
      expect(formatRupiah(75000), 'Rp 75.000');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('BR-04 validateBookDescription enforces required & max 15 words', () {
      expect(validateBookDescription(''), isNotNull);
      expect(
        validateBookDescription(
          'satu dua tiga empat lima enam tujuh delapan sembilan sepuluh sebelas dua belas tiga belas empat belas lima belas',
        ),
        isNotNull, // 18 words
      );
      expect(
        validateBookDescription(
          'satu dua tiga empat lima enam tujuh delapan sembilan sepuluh sebelas duabelas tigabelas empatbelas limabelas',
        ),
        isNull, // exactly 15 words
      );
    });

    test('BR-02 validateBookPrice requires > 0 only when isSale is true', () {
      expect(validateBookPrice('', isSale: false), isNull);
      expect(validateBookPrice('0', isSale: false), isNull);
      expect(validateBookPrice('', isSale: true), isNotNull);
      expect(validateBookPrice('0', isSale: true), isNotNull);
      expect(validateBookPrice('45000', isSale: true), isNull);
    });

    test('BR-03 validateCoverImageMeta checks JPG/PNG and <= 5 MB', () {
      expect(
        validateCoverImageMeta(
          fileName: 'sampul.jpg',
          fileSizeBytes: 5 * 1024 * 1024,
        ),
        isNull,
      );
      expect(
        validateCoverImageMeta(fileName: 'sampul.PNG', fileSizeBytes: 1024),
        isNull,
      );
      expect(
        validateCoverImageMeta(fileName: 'sampul.webp', fileSizeBytes: 1024),
        isNotNull,
      );
      expect(
        validateCoverImageMeta(
          fileName: 'sampul.jpg',
          fileSizeBytes: (5 * 1024 * 1024) + 1,
        ),
        isNotNull,
      );
    });

    test('NRP, email, phone, and password validators catch invalid input', () {
      expect(validateNrp('5026241196'), isNull);
      expect(validateNrp('123'), isNotNull);
      expect(validateNrp('502624abc'), isNotNull);

      expect(validateEmail('mhs@student.its.ac.id'), isNull);
      expect(validateEmail('bukan-email'), isNotNull);

      expect(validatePhone('081234567890'), isNull);
      expect(validatePhone('1234'), isNotNull);

      expect(validatePassword('rahasia123'), isNull);
      expect(validatePassword('123'), isNotNull);
    });
  });
}
