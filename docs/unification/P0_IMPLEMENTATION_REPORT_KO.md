# Timey Rider 통합 P0 구현 보고서

검증일: 2026-11-14 (KST). 표의 Git 정보는 시작 시점이며 종료 시점 변화는 8절에 별도 기록한다. 범위: 개정 v2 설계의 **P0-a / P0-b만**.
01~07 문서를 모두 읽었다. 저장 대안 D, 두 production 테이블, 사전 출시 데이터 이관 제외,
P1 fake shell 독립 검증이라는 개정 결정을 기준으로 조사했다. production DB는 구현하지 않았다.

표기: **VERIFIED**=직접 확인·실행 성공, **FAILED**=실행 실패,
**NOT RUN**=미실행, **PROPOSED**=권고·다음 단계 판단. 테스트 성공은 아래 명시 환경에 한한다.

## 1. 저장소·환경 스냅샷

| 항목 | Timey | Yamyam |
|---|---|---|
| 원본 경로 | `/Users/moonkong/dev/timey_rider` | `/Users/moonkong/dev/jy_yamyam` |
| branch (VERIFIED) | `main` | `fix/road-viewport-sizing` |
| HEAD (VERIFIED) | `29fd5b26c796d173f4f1893b4036a43806da206c` | `254feea3c4e33dea179dc86db838dcff94eafab1` |
| 로컬 remote tracking 상태 | origin/main 대비 ahead 1 / behind 1 | 로컬 main은 origin/main 대비 behind 1 |
| 앱 version | `1.0.0+2` | `1.0.0+1` |
| pubspec Dart 제약 | `^3.9.2` | `^3.9.2` |
| **현재 lockfile 실제 하한** | Dart `>=3.11.0 <4.0.0`, Flutter `>=3.38.1` | Dart `>=3.12.0 <4.0.0`, Flutter `>=3.44.0` |
| iOS deployment target | 15.0 | 15.0 |
| Android | 양쪽 `flutter.minSdkVersion/compileSdkVersion/targetSdkVersion`, Gradle 8.12, AGP 8.9.1, Kotlin 2.1.0 | 동일 |
| IAP wrapper / Android / StoreKit | 3.2.3 / 0.4.0+10 / 0.4.8+1 | 3.3.0 / 0.5.1 / 0.4.10+1 |
| path_provider_foundation | **2.5.1 고정** | 2.6.0 |

VERIFIED: 현재 Flutter 3.44.1 stable (`924134a44c`), Dart 3.12.1, macOS 27.0.1 arm64,
Xcode 27.2 (`27B52`). Flutter SDK의 Android 기본값은 minSdk 24, compile/target 36,
NDK 28.2.13676358이다. Android SDK platform 35/36/36.1이 설치되어 있다.
일반 `java -version`은 JRE를 찾지 못했지만 Android Studio 내장 JBR 21.0.10이 존재하며
Flutter Android 빌드는 성공했다. 원본 설정을 바꾸지 않았다.

공통 주요 lock 버전: shared_preferences 2.5.5, path_provider 2.1.5, video_player 2.10.1,
audioplayers 6.7.0, image_picker 1.2.2, image 4.8.0, wakelock_plus 1.6.1, flutter_svg 2.3.0.
모든 해결 버전·로컬/remote branch 목록·기존 status는
[p0_evidence/timey_rider-snapshot.json](p0_evidence/timey_rider-snapshot.json),
[p0_evidence/jy_yamyam-snapshot.json](p0_evidence/jy_yamyam-snapshot.json)에 기록했다.
네트워크 fetch는 하지 않았으므로 branch 비교는 로컬에 저장된 remote ref 기준이다.

### 설계의 조사 시점과 달라진 사실

- VERIFIED: 01/06 문서의 Timey HEAD `8871c5a...`, branch `fix/road-viewport-sizing`는 현재와 다르다.
  현재 Timey tracked diff는 없다. 도로 변경을 다시 적용하거나 되돌리지 않았다.
- VERIFIED: 문서의 “양쪽 미커밋 4개”는 현재 Yamyam에만 해당한다.
  문서에 언급된 `docs/unification.zip`도 현재 시작 스냅샷에는 없다.
- VERIFIED: Dart `^3.9.2` 선언만으로 현재 앱이 Dart 3.9.2에서 빌드 가능하다고 볼 수 없다.
  예를 들어 기존 synchronized 3.4.0+1은 Dart ^3.11.0, package_info_plus 10.1.0은 >=3.10.0을 요구한다.
  **NOT RUN:** Dart 3.9.2 또는 최소 지원 Flutter에서의 실행. P0에서 기존 의존성을 낮추지 않았다.

## 2. 기존 작업 트리와 보존 방식

VERIFIED: Timey에는 시작부터 `docs/unification/01~07` 일곱 문서가 untracked로 있었다.
Yamyam의 다음 tracked 수정 4개는 모두 시작 시 존재했다.

| Yamyam 경로 | 기존 diff (+ / -) |
|---|---|
| `docs/TIMER_END_ALARM_IMPLEMENTATION_PLAN.md` | 8 / 0 |
| `lib/widgets/road_view.dart` | 16 / 2 |
| `test/road_view_test.dart` | 74 / 0 |
| `test/timer_end_alarm_test.dart` | 64 / 4 |

원본 저장소에서는 Flutter 명령을 실행하지 않았다. 두 현재 작업 트리를
`/private/tmp/timey-p0-20261114/{timey_rider,jy_yamyam}`에 복사했다.
`.git`, `.dart_tool`, build, Pods, .symlinks, ephemeral은 복사에서 제외했으며,
현재 미커밋 소스·테스트·문서는 포함했다. 따라서 결과는 **현재 작업 트리 기준**이며 Yamyam HEAD 단독 결과가 아니다.
원본 `.git` 제외 전체 파일의 경로·SHA-256을 시작/종료 대조한다. 보존 결과는 8절 참조.
reset/clean/stash/restore/add/commit/push 또는 branch 전환을 하지 않았다.

## 3. Flutter analyze / test 기준선

각 복사본에서 다음 순서로 실행했다. SQLite 추가 전의 기존 lockfile을 사용했다.

```sh
flutter pub get --offline
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

| 검증 | Timey | Yamyam |
|---|---|---|
| pub get --offline | VERIFIED, 성공 | VERIFIED, 성공 |
| analyze | VERIFIED, No issues found, 3.1초 | VERIFIED, No issues found, 2.0초 |
| 전체 test | VERIFIED, **663 passed / 0 failed**, 약31초 | VERIFIED, **659 passed / 0 failed**, 약39초 |
| 최상위 `_test.dart` 파일 | 63 | 71 |
| 기존 테스트 수정 | 없음 | 없음 |

전체 로그: [Timey analyze](p0_evidence/timey-analyze.log), [Timey test](p0_evidence/timey-test.log),
[Yamyam analyze](p0_evidence/yamyam-analyze.log), [Yamyam test](p0_evidence/yamyam-test.log).
의존성 안내도 [Timey pub get](p0_evidence/timey-pub-get.log), [Yamyam pub get](p0_evidence/yamyam-pub-get.log)에 남겼다.

기존 실패: 이번 기준선의 실패 테스트·analyzer warning은 **0**이다.
양 test 로그의 `Timer end alarm playback failed: PlatformException(test-playback-failure, ...)`는
각 `timer_end_alarm_service_test.dart:56`의 의도적인 예외 주입이다. 테스트 실패와 구분한다.
업데이트 가능한 패키지 안내는 실패가 아니며 P0에서 upgrade하지 않았다.
실기기 구매, release 빌드, crash/kill, 성능·iPad UI 시험은 이 기준선에 포함되지 않는다.

## 4. 핵심 회귀 coverage 및 fixture 판단

아래 파일은 전체 suite에 포함되어 통과했다. 기존 테스트는 mock preferences/fake purchase/clock 및
현재 앱의 fixture를 사용하므로 실제 disk durability·실제 store 권한을 증명하지 않는다.

| 영역 | Timey 기준선 | Yamyam 기준선 | 보존할 핵심 의미 |
|---|---|---|---|
| 시간·완료 | `activity_timer_controller_test`, `timer_completion_lifecycle_test`, `pending_activity_result_test`, `result_screen_test` | `meal_timer_controller_test`, `timer_completion_flow_controller_test`, `timer_screen_completion_test`, `result_screen_test` | Daily 도착/명시 sticker 선택과 Meal 초과·완료 후 자동 1장 정책 차이 |
| 보상·목표·중복/삭제 | `local_activity_progress_service_test`, `activity_history_linked_delete_test` | `local_meal_progress_service_test`, `meal_history_linked_delete_test` | 완료/미완료 지급, 목표 2개, earned→used, linked delete, 실패 재시도·삭제 부활 방지 |
| 저장·설정·프리셋 | `local_settings_service_test`, `local_saved_timer_preset_service_test`, `local_recent_timer_service_test`, `activity_progress_snapshot_test` | `local_settings_service_test`, `meal_progress_snapshot_test`, progress service suite | round-trip, Daily 최근 최대5·favorite3, 현재 reward 계산 |
| 활성·pending 복구 | `active_activity_timer_session_store_test`, `pending_activity_result_storage_test`, `home_active_session_test` | `active_meal_timer_session_store_test`, `timer_active_session_controller_test`, `home_active_session_test` | running/paused/arrived 상태, ID별 cleanup, pending 보존·재시도 |
| IAP | `vehicle_pack_purchase_controller_test`, `iap_purchase_client_test`, `app_purchase_recovery_test`, `local_purchase_entitlement_store_test` | `vehicle_pack_purchase_controller_test`, `android_purchase_state_test`, `app_purchase_wiring_test`, `local_purchase_entitlement_store_test` | pending 잠금 유지, restored/purchased, 중복 event·오프라인 cache, 복원 및 쓰기 실패 |
| 알람·화면 수명 | `timer_end_alarm_test`, `timer_session_audio_test`, `road_view_test` | `timer_end_alarm_test`, `timer_audio_lifecycle_test`, `road_view_test` | 알람·정지/재개·도로 레이아웃, 현재 dirty test 결과 포함 |

파일명은 각 repo의 `test/` 아래이며 표의 이름 뒤에 `.dart`를 붙인다.
VERIFIED: Timey는 timeEnded 기본 무보상이지만 부모 명시 선택으로 지급 가능한 테스트가 있다.
Yamyam에는 `failed completion retains result and retry awards only once`가 있다.
기존 home의 오래된 session 자동 정리 테스트도 통과했으나, **미래 unified의 24h 보존 계약 검증으로 취급하지 않는다.**
PROPOSED: 저장 IO 교체 시 정상 도메인 입력/기대값만 재사용하고 기존 legacy journal/decoder fixture를
통합 앱의 이관 요구로 승계하지 않는다. 필요한 현재 정책 coverage가 이미 있으므로 **새 baseline fixture 0개**.
새롭게 추가한 실험 테스트는 SQLite 기능 검증용 하나뿐이다.

## 5. SQLite 후보·버전·플랫폼 권고

PROPOSED: runtime은 **sqflite 2.4.2** exact pin을 권고한다. 운영 pubspec에는 아직 추가하지 않았다.
공식 배포 metadata와 다운로드한 plugin source를 확인했다.

| 후보 | 조사·판단 |
|---|---|
| sqflite 2.4.2 | VERIFIED: Dart ^3.7.0. OS SQLite 기반 async plugin, 명시 SQL/transaction 사용 가능. 두 테이블·JSON snapshot 설계에 적합 |
| sqflite 2.4.2+1 | VERIFIED: Dart ^3.10.0. 선언 하한 ^3.9.2를 유지하려는 목적에는 부적합 |
| sqflite 2.4.6 (조사 시 최신) | VERIFIED: Dart ^3.12.0 / Flutter >=3.44.0. 현 SDK에는 맞지만 기존 하한을 높이므로 선택하지 않음 |
| drift 2.35.4 | 공식 문서상 reactive/type-safe SQL 및 생성 코드 지원. PROPOSED: 현재 최소 설계에는 도입 이점 대비 추가 계층이 큼. 의존성 설치·빌드 NOT RUN |
| sqlite3 3.9.1 | 공식 문서상 FFI·동기 API와 bundled SQLite 제공. PROPOSED: isolate/lifecycle 책임을 더 가져오므로 이번 runtime은 sqflite 선호. 설치·빌드 NOT RUN |
| sqflite_common_ffi | 호스트 unit test용 후보. 모바일 native plugin 결과와 혼동하지 않도록 이번에는 추가하지 않고 실제 native plugin으로 smoke 수행 |

VERIFIED 조합:

```yaml
sqflite: 2.4.2
sqflite_android: 2.4.2+2
sqflite_darwin: 2.4.2
sqflite_platform_interface: 2.4.0
sqflite_common: 2.5.6
```

wrapper의 하위 범위가 `<4.0.0`까지 열려 있으므로 wrapper 하나만 pin하면 최신 SDK를 요구하는
plugin으로 해결될 수 있다. 위 exact 조합과 lockfile을 함께 관리하도록 권고한다.
선택한 SQLite 계열 자체의 최대 Dart 하한은 3.9.0이며, interface의 Flutter 하한은 3.24.0이다.
다만 **기존 전체 앱 lock 그래프의 Dart 3.11 하한을 낮추지 않으며 3.9.2에서 전체 앱 검증은 하지 않았다.**
실험에는 기존 synchronized 3.4.0+1도 고정했다.

VERIFIED: 테스트 완료한 Timey 임시 복사본에 위 다섯 패키지만 추가하여 `flutter pub get` 성공.
기존 해결 패키지 버전 변경 **0**, 새 패키지 **5**. IAP·path_provider_foundation pin 유지.
추가 후 `flutter analyze --no-pub` 통과(2.9초), 기존 Android 설정에서
`flutter build apk --debug --no-pub` 성공(Gradle 약62.7초).
근거: [resolution](p0_evidence/timey-sqlite-pub-get.log), [analyze](p0_evidence/timey-sqlite-analyze.log),
[Android build](p0_evidence/timey-sqlite-android-build.log).

플랫폼: sqflite_darwin 2.4.2는 CocoaPods/SPM iOS 12.0, macOS 10.14 이상;
앱 iOS 15.0이 더 높다. sqflite_android 2.4.2+2는 minSdk19, compileSdk36, Java17,
plugin AGP8.11.1을 선언한다. 앱은 현 Flutter에서 min24/compile36이며 기존 app AGP8.9.1과
함께 debug 빌드가 실제 통과했다. OS별 SQLite 버전 차이와 최소 OS에서의 동작은 남은 검증이다.
웹/Windows/Linux runtime 지원은 이번 모바일 범위 밖이다.

공식 근거: [sqflite 버전 목록](https://pub.dev/packages/sqflite/versions),
[sqflite 2.4.2 metadata](https://pub.dev/api/packages/sqflite/versions/2.4.2),
[Android metadata](https://pub.dev/api/packages/sqflite_android/versions/2.4.2%2B2),
[Darwin metadata](https://pub.dev/api/packages/sqflite_darwin/versions/2.4.2),
[interface metadata](https://pub.dev/api/packages/sqflite_platform_interface/versions/2.4.0),
[common metadata](https://pub.dev/api/packages/sqflite_common/versions/2.5.6),
[drift](https://pub.dev/packages/drift), [sqlite3](https://pub.dev/packages/sqlite3).

## 6. DB smoke test

재현 자료: [격리 실험 README](p0_sqlite_smoke/README.md),
[test source](p0_sqlite_smoke/integration_test/sqlite_smoke_test.dart),
[pubspec](p0_sqlite_smoke/pubspec.yaml), [lockfile](p0_sqlite_smoke/pubspec.lock).
[결과 요약 JSON](p0_evidence/results.json)에도 판정을 기록했다.
실제 native runner는 `/private/tmp/timey-p0-20261114/sqlite_smoke`에 Flutter create로 생성했다.
운영 테이블명·namespace·adapter·앱 데이터를 사용하지 않고 `probe` 테이블 하나만 만들었다.

| 검증 | 결과 |
|---|---|
| iOS 18.6 / iPhone16 Pro simulator | VERIFIED, native plugin 테스트 1개 통과, SQLite 3.43.2 |
| 최초 open | VERIFIED, onCreate 1회 / user_version1 / seed |
| transaction commit | VERIFIED, update+insert 2행 보존 |
| 예외 rollback | VERIFIED, update+insert 후 의도적 throw; 변경·3번 행 모두 남지 않음 |
| close/reopen | VERIFIED, 같은 파일 유지 / seed 재삽입0 / committed 2행 동일 |
| journal / synchronous | VERIFIED, DELETE / FULL(2) 값을 조회해 확인 |
| integrity_check | VERIFIED, ok |
| 실험 test analyze | VERIFIED, No issues found |
| Android17(API37) / Pixel10dks emulator | VERIFIED, native plugin 테스트 1개 통과, SQLite 3.50.6; 동일 assertions |
| 실제 iOS/Android 물리 기기 | NOT RUN |
| process kill·power loss·disk full·미래 schema update | NOT RUN; P2/P5/P7 계약 검증은 별도 |

FAILED: 첫 iOS 실험 빌드는 Flutter create가 생성한 deployment target13.0을
Xcode27.2가 지원하지 않아 runner 로딩 실패(테스트 assertion 이전)했다.
앱과 같은 target15.0을 **임시 runner에만** 적용한 재시도는 통과했다.
초기 실험 pubspec version 미지정 경고도 실험 전용 0.0.1+1로 해소했다.
Android 첫 runner는 새 template의 Gradle9.1 다운로드 대기에서 중단했다(검증 assertion 미실행).
임시 runner만 기존 앱과 같은 Gradle8.12/AGP8.9.1/Kotlin2.1.0으로 맞추고 Kotlin plugin을
명시한 재시도는 빌드34.8초 및 test1개 통과했다. 운영 앱 파일은 수정하지 않았다.
[Android 재시도 로그](p0_evidence/sqlite-android-smoke-retry.log)에 기록했다.
이것은 기존 앱의 실패가 아니다. [첫 로그](p0_evidence/sqlite-ios-smoke.log),
[재시도 로그](p0_evidence/sqlite-ios-smoke-retry.log), [분석](p0_evidence/sqlite-analyze.log).

## 7. 기존 문제·미해결 위험

- VERIFIED: 기준선 analyzer/test 실패0. 기존 manifest와 lock SDK 하한 차이는 남는다.
  PROPOSED: P2 전에 실제 지원 SDK 정책을 정하고 그 SDK에서 CI 확인. P0에서 버전 변경하지 않음.
- VERIFIED: Android build에 Gradle8.12→8.14, AGP8.9.1→8.11.1,
  Kotlin2.1.0→2.2.20 향후 지원 경고, app 및 기존 plugins의 KGP 향후 호환성 경고가 있다.
  원인 설정은 기존 파일에 존재하며 SQLite 때문에 바뀐 설정은 없다.
- NOT RUN: 실제 Timey 전체 iOS dependency graph + SQLite native 빌드,
  최소 지원 iOS/Android OS, release signing/binary, 실제 store restore.
  독립 iOS smoke 성공을 이 항목들의 통과로 확대하지 않는다.
- VERIFIED(source): 원래 preferences 여러 키 및 result→active cleanup은 DB transaction이 아니다.
  기존 24h session 자동 정리도 남아 있다. P0는 이를 수정하지 않는다.
- NOT RUN: unified mode 격리·완료 멱등성·손상 payload·사진 파일/DB 경계·강제 종료 후 복구.
  정상 reopen은 crash durability 증거가 아니다. production schema 없는 P0에서는 이후 게이트로 남긴다.
- 환경: 기본 sandbox에서 Flutter SDK 캐시 쓰기와 simctl 접근이 차단되어 승인된 실행으로 재시도했다.
  flutter devices는 유선 iPhone/macOS/Chrome을 찾았지만 별도 무선 iPhone 탐색 code-27을 반환했다.
  실기기에는 설치·구매 작업을 하지 않았다. 개발 SDK를 upgrade하지 않았다.

## 8. P0에서 만든 변경·생성물

의도한 원본 저장소 추가는 이 보고서, `p0_evidence/`의 로그·스냅샷·보존 검증,
`p0_sqlite_smoke/`의 격리 test/pubspec/lock/README뿐이다.
기존 앱 lib/test/assets/pubspec/native config, 기존 설계 문서7개와 Yamyam 원본은 수정하지 않았다.
앱 식별자·IAP ID·App Store 설정·앱 버전/빌드 번호를 바꾸지 않았다.

생성물: 임시 복사본의 .dart_tool/build/plugin registrant/Flutter 설정,
실험의 native ios/android runner·SPM/Gradle 산출물·시뮬레이터 DB,
임시 Timey의 debug APK 및 임시 SQLite 의존성 변경은 의도된 production 소스 변경이 아니다.
SDK/pub/Gradle cache와 에뮬레이터 상태도 원본 저장소 밖의 검증 부산물이다.
이번에 부팅한 simulator/emulator는 검증 후 종료했다.
Android 실험 앱 제거 시도는 DELETE_FAILED_INTERNAL_ERROR를 반환했다. Flutter test 종료 후
설치 잔존 여부는 확인하지 않았으며 AVD 전체 초기화는 하지 않았다. 테스트 판정에는 영향이 없다.
재현에 필요한 smoke lockfile만 실험 자료로 의도적으로 보관한다.

VERIFIED: 시작 시 Timey 파일 **3,822개**와 Yamyam 파일 **7,540개**의 SHA-256 대조 결과,
기존 파일 변경·삭제 **0개**. Yamyam 추가 파일 **0개**. 양쪽 branch/tracked diff 및 Yamyam HEAD는 동일하다.
Timey HEAD는 마지막 확인 시 `c74b85c73910b8a22623f9d0849a792949439940`으로 변경되어 있었다.
이번 작업에서는 Git 이력을 변경하는 명령을 실행하지 않았다. 기준선은 시작 HEAD의 작업 트리 복사본이다.
종료 HEAD를 검증 대상으로 바꾸거나 기존 파일을 복원하지 않았다.
이번 작업에서 만든 Timey 추가 파일은 이 P0 문서·실험·증거 경로에만 있다.
별도로 마지막 스냅샷에는 `assets/fonts/OFL.txt`가 추가되어 있었다. 시작/종료 commit 간 diff도
이 라이선스 파일 추가뿐이며 lib/test/pubspec/native config의 diff는 없다. 이 추가를 P0 변경으로 귀속하지 않는다.
근거: [preservation.json](p0_evidence/preservation.json).

## 9. P0 acceptance checklist

- [x] VERIFIED — 설계01~07 및 revised v2 확인, source 차이 별도 기록
- [x] VERIFIED — 양쪽 branch/HEAD/dependencies/dirty snapshot 확보
- [x] VERIFIED — 원본 보존, Yamyam 쓰기 없이 복사본 실행
- [x] VERIFIED — 양 앱 analyze/test 및 기존 실패·경고 구분
- [x] VERIFIED — 완료·보상·저장·IAP·복구 suite와 fixture 필요성 판단
- [x] VERIFIED — SDK/OS 제약·대안·SQLite exact 조합 조사 및 기존 graph 해결
- [x] VERIFIED — 실제 native SQLite 초기화·commit/rollback·재열기 smoke
- [x] VERIFIED — 기존 Android graph에 SQLite 추가 debug 빌드
- [x] VERIFIED — 생산 DB/schema/이관/P1 이후/Meal 병합 미구현, commit/push 없음
- [ ] NOT RUN — 최소 SDK/OS·물리 기기·kill/restore·release 검증 (이후 단계 게이트)

## 10. P1 준비도와 중단 지점

**PROPOSED 판정: P0 완료. P1의 fake DI 개발용 selector/navigation shell은 시작 가능하다.**
기존 정책 기준선은 모두 통과했고 native DB 기본 동작 및 Android dependency build 근거를 확보했다.
P1은 W01/W02/W09를 fake로 검증하며 DB production 연결을 선행하지 않는다.
위 미검증 항목을 production 데이터 보존·공개 두 모드 실행의 승인으로 해석하지 않는다.
P2 연결 전에 실제 지원 SDK 정책·최소 OS·전체 iOS graph를 확인하고,
P5/P7에서 mode 격리·kill/recovery 및 실제 Timey store restore 게이트를 통과해야 한다.
**이번 작업은 P0에서 중단하며 P1은 구현하지 않는다.**

수동 확인 권장 영역: Daily 시작→pause/resume→완료→스티커 받기/건너뛰기→기록/목표,
Yamyam의 조기/도착/초과 완료와 미완료(참조 앱에서만), 양 앱 재시작 후 진행/결과 복구,
Vehicle Pack pending/구매 복원·오프라인 재실행, 도로/알람 및 세로·가로 화면.
이번 P0에서 이 사용자 흐름을 직접 조작했다고 주장하지 않는다.
