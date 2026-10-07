import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'optimized assets load while preserved originals stay outside bundle',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final bundledPaths = manifest.listAssets().toSet();
      final optimizedAssets =
          jsonDecode(
                File(
                  'asset_sources/optimization_manifest.json',
                ).readAsStringSync(),
              )
              as List;

      expect(
        bundledPaths.where((path) => path.startsWith('asset_sources/')),
        isEmpty,
      );
      for (final asset in optimizedAssets) {
        final path = asset['runtime'] as String;
        expect(bundledPaths, contains(path), reason: path);
        if (asset['kind'] != 'image') continue;
        expect(bundledPaths, isNot(contains(asset['original'])), reason: path);

        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        final original = File(asset['source'] as String).readAsBytesSync();
        final header = ByteData.sublistView(original);
        expect(frame.image.width, header.getUint32(16), reason: path);
        expect(frame.image.height, header.getUint32(20), reason: path);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
}
