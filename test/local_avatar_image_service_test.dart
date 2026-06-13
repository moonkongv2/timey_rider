import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';
import 'package:timey_rider/services/local_avatar_image_service.dart';

void main() {
  test('Normalizes a small image into square image bytes', () {
    final sourceImage = image.Image(width: 24, height: 12, numChannels: 4);
    image.fill(sourceImage, color: image.ColorRgba8(255, 120, 40, 255));
    final sourceBytes = image.encodePng(sourceImage);

    final normalizedBytes = LocalAvatarImageService.normalizeAvatarImageBytes(
      sourceBytes,
      size: 32,
    );

    expect(normalizedBytes, isNotNull);
    final normalizedImage = image.decodeImage(normalizedBytes!);
    expect(normalizedImage, isNotNull);
    expect(normalizedImage!.width, 32);
    expect(normalizedImage.height, 32);
  });

  test('Invalid image bytes return null instead of throwing', () {
    final normalizedBytes = LocalAvatarImageService.normalizeAvatarImageBytes(
      Uint8List.fromList([1, 2, 3, 4, 5]),
      size: 32,
    );

    expect(normalizedBytes, isNull);
  });

  test('Saves a picked image as normalized local avatar file', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'avatar_service_test_',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));

    final sourceImage = image.Image(width: 18, height: 36, numChannels: 4);
    image.fill(sourceImage, color: image.ColorRgba8(80, 160, 255, 255));
    final pickedFile = XFile.fromData(
      image.encodePng(sourceImage),
      path: 'picked/avatar_source.png',
    );
    final service = LocalAvatarImageService(
      directoryProvider: () async => temporaryDirectory,
    );

    final savedPath = await service.savePickedAvatarImage(pickedFile);

    expect(savedPath, contains('avatar_images'));
    expect(savedPath, contains('avatar_'));
    expect(savedPath.endsWith('.png'), isTrue);
    expect(await service.exists(savedPath), isTrue);

    final savedImage = image.decodeImage(await File(savedPath).readAsBytes());
    expect(savedImage, isNotNull);
    expect(savedImage!.width, LocalAvatarImageService.avatarImageSize);
    expect(savedImage.height, LocalAvatarImageService.avatarImageSize);

    await service.deleteAvatarImage(savedPath);
    expect(await service.exists(savedPath), isFalse);
  });

  test('Falls back to copying original bytes when decoding fails', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'avatar_service_fallback_test_',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));

    final invalidBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final pickedFile = XFile.fromData(
      invalidBytes,
      path: 'picked/not_an_image.custom',
    );
    final service = LocalAvatarImageService(
      directoryProvider: () async => temporaryDirectory,
    );

    final savedPath = await service.savePickedAvatarImage(pickedFile);

    expect(savedPath.endsWith('.custom'), isTrue);
    expect(await File(savedPath).readAsBytes(), invalidBytes);
  });

  test(
    'Falls back to system temp when app documents directory fails',
    () async {
      final sourceImage = image.Image(width: 12, height: 12, numChannels: 4);
      image.fill(sourceImage, color: image.ColorRgba8(255, 200, 120, 255));
      final pickedFile = XFile.fromData(
        image.encodePng(sourceImage),
        path: 'picked/avatar_source.png',
      );
      final service = LocalAvatarImageService(
        directoryProvider: () async {
          throw StateError('documents directory unavailable');
        },
      );

      final savedPath = await service.savePickedAvatarImage(pickedFile);
      addTearDown(() => service.deleteAvatarImage(savedPath));

      expect(savedPath, contains('avatar_images'));
      expect(savedPath.endsWith('.png'), isTrue);
      expect(await service.exists(savedPath), isTrue);
    },
  );
}
