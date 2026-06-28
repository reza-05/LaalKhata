import 'package:flutter_test/flutter_test.dart';
import 'package:laalkhata/features/ledger/domain/source_identity.dart';

void main() {
  test('known source identities ignore case, spacing, and numeric suffixes',
      () {
    expect(sourceIdentityKey('Nagad'), 'nagad');
    expect(sourceIdentityKey('nagad'), 'nagad');
    expect(sourceIdentityKey('NaGaD 2'), 'nagad');
    expect(sourceIdentityKey('bKash1'), 'bkash');
    expect(sourceIdentityKey('AB Bank 02'), 'abbank');
    expect(sourceIdentityKey('Cash Wallet'), 'cash');
  });

  test('custom source identities also ignore formatting and trailing numbers',
      () {
    expect(sourceIdentityKey('My Card'), 'mycard');
    expect(sourceIdentityKey('my-card-2'), 'mycard');
    expect(sourceIdentityKey('MY_CARD 99'), 'mycard');
  });
}
