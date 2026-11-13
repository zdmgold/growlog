import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/storage_check.dart';

void main() {
  const model = 309 * 1000 * 1000;

  test('enough room passes, too little fails', () {
    expect(StorageCheck.enough(needBytes: model, freeMb: 2000), isTrue);
    expect(StorageCheck.enough(needBytes: model, freeMb: 400), isFalse);
  });

  test('the margin is kept on top of the download', () {
    final justShort = (model + StorageCheck.marginBytes) / (1024 * 1024) - 1;
    final justEnough = (model + StorageCheck.marginBytes) / (1024 * 1024) + 1;
    expect(StorageCheck.enough(needBytes: model, freeMb: justShort), isFalse);
    expect(StorageCheck.enough(needBytes: model, freeMb: justEnough), isTrue);
  });

  test('if free space cannot be read, the download is not blocked', () {
    expect(StorageCheck.enough(needBytes: model, freeMb: null), isTrue);
  });
}
