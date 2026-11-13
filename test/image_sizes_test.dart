import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/models/scan_record.dart';
import 'package:growlog/utils/image_sizes.dart';
import 'package:growlog/widgets/scan_widgets.dart';

void main() {
  testWidgets('a scan thumbnail is decoded at thumbnail size, not full size',
      (tester) async {
    final scan = ScanRecord(
      id: 'a',
      imagePath: '/nowhere/scan.jpg',
      createdAt: DateTime(2026, 11, 12),
      commonName: 'Aloe',
    );
    await tester.pumpWidget(MaterialApp(home: ScanThumb(scan: scan)));
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(provider.width, ImageSizes.thumb);
    expect(provider.imageProvider, isA<FileImage>());
    expect((provider.imageProvider as FileImage).file, isA<File>());
  });

  test('decode widths grow with how much of the screen the photo covers', () {
    expect(ImageSizes.thumb, lessThan(ImageSizes.medium));
    expect(ImageSizes.medium, lessThan(ImageSizes.fullWidth));
    expect(ImageSizes.fullWidth, lessThan(ImageSizes.hero));
  });
}
