# Release asset originals

This directory preserves the original images and silent success videos used
before the release asset optimization. It is not registered in `pubspec.yaml`
and must remain outside the app asset bundle.

- `images/`: original PNG images. Runtime images are lossless WebP files under
  `assets/images/`, with unchanged dimensions and identical decoded RGBA pixels.
- `videos/`: original success videos. Runtime MP4 files keep the original paths,
  resolution, frame rate, frame count, duration, and lack of audio tracks.
- `optimization_manifest.json`: original and optimized paths, byte counts,
  SHA-256 hashes, image pixel hashes, and video validation results.

Images were encoded with `cwebp -lossless -exact -metadata all -m 6`.
Videos were encoded with FFmpeg using H.264 (`libx264`), CRF 21, `preset slow`,
`yuv420p`, passthrough frame timing, and `+faststart`. Video encoding is lossy;
SSIM against the original was checked, but physical-device visual review is
still required. Always encode future revisions from these originals or the
upstream source, rather than repeatedly encoding the optimized runtime files.

To restore an image, copy its original back to `assets/images/`, update its Dart
references from `.webp` to `.png`, and remove the corresponding runtime WebP.
The result-screen rider path is also constructed dynamically. To restore a
video, copy its original back to the matching `assets/videos/` path.

Audio, the splash video, deferred media, app icons, and fonts were not changed.
