import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class LocalAvatarImageService {
  const LocalAvatarImageService({this.directoryProvider});

  static const avatarImageSize = 1024;
  static const _avatarDirectoryName = 'avatar_images';
  static const _avatarFilePrefix = 'avatar_';

  final Future<Directory> Function()? directoryProvider;

  Future<String> savePickedAvatarImage(XFile pickedFile) async {
    final bytes = await pickedFile.readAsBytes();
    final normalizedBytes = normalizeAvatarImageBytes(bytes);
    final directory = await _avatarDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    if (normalizedBytes != null) {
      final file = File(
        _joinPath(directory.path, '$_avatarFilePrefix$timestamp.png'),
      );
      await file.writeAsBytes(normalizedBytes, flush: true);
      return file.path;
    }

    final extension = _safeExtension(pickedFile.path);
    final fallbackFile = File(
      _joinPath(directory.path, '$_avatarFilePrefix$timestamp$extension'),
    );
    await fallbackFile.writeAsBytes(bytes, flush: true);
    return fallbackFile.path;
  }

  Future<void> deleteAvatarImage(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }

    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> exists(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return false;
    }
    return File(imagePath).exists();
  }

  static Uint8List? normalizeAvatarImageBytes(
    List<int> bytes, {
    int size = avatarImageSize,
  }) {
    try {
      final decodedImage = image.decodeImage(Uint8List.fromList(bytes));
      if (decodedImage == null) {
        return null;
      }

      final squareImage = image.copyResizeCropSquare(decodedImage, size: size);
      return image.encodePng(squareImage);
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _avatarDirectory() async {
    final baseDirectory = await _baseDirectory();
    final directory = Directory(
      _joinPath(baseDirectory.path, _avatarDirectoryName),
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _baseDirectory() async {
    try {
      return directoryProvider == null
          ? await getApplicationDocumentsDirectory()
          : await directoryProvider!();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  String _safeExtension(String filePath) {
    final separatorIndex = filePath.lastIndexOf(Platform.pathSeparator);
    final fileName = separatorIndex == -1
        ? filePath
        : filePath.substring(separatorIndex + 1);
    final extensionIndex = fileName.lastIndexOf('.');
    final extension = extensionIndex == -1
        ? ''
        : fileName.substring(extensionIndex).toLowerCase();
    if (RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension)) {
      return extension;
    }
    return '.image';
  }

  String _joinPath(String directoryPath, String childName) {
    if (directoryPath.endsWith(Platform.pathSeparator)) {
      return '$directoryPath$childName';
    }
    return '$directoryPath${Platform.pathSeparator}$childName';
  }
}
