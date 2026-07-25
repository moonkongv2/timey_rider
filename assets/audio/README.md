# Audio Assets

This folder contains runtime audio assets and license evidence.

## Runtime Flutter Assets

Only these timer audio files are bundled by `pubspec.yaml`:

- `assets/audio/timer_bgm/timer_bgm_01.mp3`
- `assets/audio/marker/marker_01.mp3`

Timer audio paths and default volumes are cataloged in
`lib/catalogs/timer_audio_asset_catalog.dart`.

## License Evidence

Files under `_licenses/` are evidence files only. They may include metadata,
license certificates, downloaded terms, screenshots, PDFs, or original source
files.

Do not register `_licenses/`, metadata files, PDFs, certificates, screenshots,
or original source files as Flutter assets.

Do not create placeholder evidence files or invent source, creator, download,
license, or Content ID facts. Leave unknown non-app facts as `TODO_USER`.
