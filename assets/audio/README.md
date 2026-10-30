# Audio Assets

This folder contains runtime audio assets and license evidence.

## Runtime Flutter Assets

These audio files are bundled by `pubspec.yaml`:

- `assets/audio/timer_bgm/timer_bgm_short.mp3`
- `assets/audio/marker/marker_01.mp3`
- `assets/audio/course_loading.mp3`
- `assets/audio/ready_start_beep_02.mp3`
- `assets/audio/final_drive_short.mp3`
- `assets/audio/final_drive_long.mp3`
- `assets/audio/finish_arrival.mp3`
- `assets/audio/timer_end.mp3` (loops until the arrival response while the app is active)
- `assets/audio/crowd_cheering.mp3`
- `assets/audio/sticker_collect.mp3`
- `assets/audio/sticker_popup.mp3`

Timer audio paths and default volumes are cataloged in
`lib/catalogs/timer_audio_asset_catalog.dart`.

Result screen playback paths and default volumes are cataloged in
`lib/catalogs/result_audio_asset_catalog.dart`.

## Timer End Alarm

`timer_end.mp3` is the repeating timer-expiration sound, separate from the
one-shot `finish_arrival.mp3` used for early-completion arrival animation.
It uses `ReleaseMode.loop` with `PlayerMode.mediaPlayer`; the default volume is
`0.24` in `TimerAudioAssetCatalog`.

With sound enabled, it loops while the app is resumed until the user responds
to the existing arrival panel. It stops on an arrival response, mute, app
inactivity, or timer exit. Returning to the same unconfirmed timer or enabling
sound again restarts it. Restoring an already expired session after an app
relaunch does not replay it. Background and lock-screen alarms are not provided.

The supplied MP3 is approximately 3.408 seconds, 48 kHz stereo, 256 kbps
(109,056 bytes). It is bundled unchanged. Check perceived volume and the loop
boundary on Android and iOS devices; automated tests do not verify sound quality.

## License Evidence

Files under `_licenses/` are evidence files only. They may include metadata,
license certificates, downloaded terms, screenshots, PDFs, or original source
files.

Do not register `_licenses/`, metadata files, PDFs, certificates, screenshots,
or original source files as Flutter assets.

Do not create placeholder evidence files or invent source, creator, download,
license, or Content ID facts. Leave unknown non-app facts as `TODO_USER`.
