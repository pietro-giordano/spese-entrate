import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/features/transactions/presentation/widgets/transaction_tile.dart';

void main() {
  test('nelle liste: al massimo due label, poi "+N"', () {
    expect(compactLabelTags([]), '');
    expect(compactLabelTags(['casa']), '#casa');
    expect(compactLabelTags(['casa', 'auto']), '#casa #auto');
    expect(compactLabelTags(['casa', 'auto', 'viaggi']), '#casa #auto +1');
    expect(compactLabelTags(['a', 'b', 'c', 'd', 'e']), '#a #b +3');
  });
}
