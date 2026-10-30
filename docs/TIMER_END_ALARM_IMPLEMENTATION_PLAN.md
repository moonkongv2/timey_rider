# 타이머 종료 반복 알람 구현 계획

## 구현 상태와 검증 (2026-10-30)

- 앱 내 반복 알람 구현과 자동 검증을 완료했다. 아래 설계와 복귀/복원 정책을 적용했다.
- `test/timer_end_alarm_test.dart`에 종료 확인, 저장 지연/실패, 소리 설정, 라이프사이클, 세션 복원, 나가기 및 응원 음성 경계 검증을 모았다.
- `test/timer_end_alarm_service_test.dart`에서 메서드 채널을 모의해 실제 서비스의 반복 모드, 중복 시작, 시작 중 정지/dispose, 빠른 요청 전환 및 재생 오류 처리를 검증했다.
- 구현 후 `flutter test --no-pub`: 전체 637개 통과. `flutter analyze --no-pub`: 이상 없음.
- 실제 기기의 음량·반복 경계 및 아래 수동 확인 흐름은 아직 검증하지 않았다.

## 목적과 확정 동작

- 앱을 열어 둔 상태에서 시간이 0이 되면 제공된 `assets/audio/timer_end.mp3`를 무한 반복한다.
- 기존 종료 확인 UI의 `완료` 또는 `아직이야`를 누르면 즉시 정지한다. 시간 종료형 활동은 기존 결과 확인 버튼으로 정지한다.
- 별도 알람 끄기 버튼, 설정, 문구는 추가하지 않는다. 기존 `soundEnabled` 설정을 따른다.
- 백그라운드에서는 정지하며 같은 화면으로 복귀하면 미확인 알람을 다시 시작한다. 화면을 벗어나거나 완료 처리한 뒤에는 재시작하지 않는다.
- 조기 완료의 주행/도착 효과음, 완료 상태 판정, 결과 저장 및 보상 정책은 유지한다.
- 이번 작업은 앱 내 오디오에 한정한다. 시스템 알림, 잠금 화면 알람, 새 패키지 및 플랫폼 권한은 추가하지 않는다.

## 구현 전 코드 근거

- `ActivityTimerController._updateElapsed()`가 시간이 끝나면 `running → arrived`로 전환한다. 컨트롤러에 오디오 책임을 추가하지 않는다.
- `TimerScreen._handleTimerChanged()`가 BGM을 정지하고 약 900ms 뒤 `_ArrivalActionPanel`을 표시한다. 이 지연은 유지하되 알람은 시간 종료 시점에 시작한다.
- 사용자가 말한 종료 팝업은 현재 화면 안의 도착 확인 패널이다. 두 버튼 모두 `_completeArrivalFromPanel()`로 연결되고 결과 저장 후 결과 화면으로 이동한다. `아직이야` 역시 현재는 `needsMoreTime` 결과로 종료되므로 타이머 연장으로 바꾸지 않는다.
- 조기 완료 확인용 `showDialog`는 별도 경로인 `_confirmComplete()`에 있다. 이 대화상자가 열린 채 시간이 끝나는 경계 상황도 검증한다.
- `TimerAudioService`가 BGM, 시작 및 도착 효과음을 소유하며, 주입한 서비스는 화면에서 `stopAll()`만 호출하고 직접 생성한 서비스만 dispose한다.
- `finish_arrival.mp3`는 조기 완료 도착 연출용이므로 종료 알람과 분리한다.
- 제공 음원은 약 3.408초 / MP3 / 48kHz / 스테레오 / 256kbps / 109,056바이트다. 변환하거나 편집하지 않고 그대로 사용한다. 반복 경계와 체감 음량은 실기기 확인 사항이다.

## 1. 음원 등록

대상:

- `pubspec.yaml`
- `lib/catalogs/timer_audio_asset_catalog.dart`
- `assets/audio/README.md`
- `test/timer_audio_asset_catalog_test.dart`

변경:

- `assets/audio/timer_end.mp3`만 pubspec에 정확한 파일 경로로 등록한다.
- 카탈로그에 `timerEndAlarmPath`, `timerEndAlarmVolume`을 추가하고 `runtimeAssetPaths`에 포함한다.
- 초기 볼륨은 `0.24`로 시작한다. 기존 도착 효과음과 같은 앱 내부 배율이며, 실제 체감 크기가 같다는 의미는 아니다. 실기기에서 종료 인지성과 피로도를 확인해 이 상수만 조정한다.
- 기존 에셋 테스트의 정확한 목록과 top-level 음원 필터를 함께 갱신한다. 파일 존재와 pubspec 등록을 확인한다.
- README에 런타임 음원 목록을 갱신한다. 출처 및 라이선스 사실을 추정해 작성하지 않는다.

## 2. 전용 반복 플레이어

대상: `lib/services/timer_audio_service.dart`

- 인터페이스에 `startTimerEndAlarm()` / `stopTimerEndAlarm()` 추가. Noop 구현과 테스트 Fake에도 동일하게 반영한다.
- 프로덕션 서비스에 전용 `_timerEndAlarmPlayer`를 추가한다. BGM이나 기존 효과음 플레이어를 재사용하지 않는다.
- `ReleaseMode.loop`, `PlayerMode.mediaPlayer`, 기존 `_audioContext`로 재생한다. 반복을 Dart 타이머나 매번 완료 콜백으로 구현하지 않는다.
- 알람 전용 직렬 작업 큐와 원하는 재생 상태를 둔다. 중복 시작은 진행 중인 파일을 처음부터 재시작하지 않는다.
- 시작/정지 요청은 원하는 상태를 동기적으로 바꾸고 큐에 작업을 넣는다. 시작 준비 중 정지·dispose가 요청되면 각 await 뒤 최신 상태를 확인해 불필요한 play를 건너뛴다. 이미 발행한 play 뒤에는 정지가 직렬로 실행되어 최종 상태를 보장한다.
- `stopAll()`에 알람 정지를 포함한다. dispose는 신규 시작을 차단하고 대기 중 작업과 정지를 정리한 뒤 전용 플레이어를 해제한다. 알람 정지가 disposed 가드로 생략되지 않게 순서를 정한다.
- 재생/정지 실패는 기존처럼 catch 및 debugPrint로 처리한다. 오류로 큐를 끊거나 완료·화면 이동을 막지 않는다. 매 프레임 재시도하지 않는다.

## 3. 화면의 알람 상태와 시작 조건

대상: `lib/screens/timer_screen.dart`

- `_arrivalPromptShown`은 패널 표시 중복 방지용으로만 유지한다. 알람 조건과 결합하면 백그라운드 복귀 시 재생이 누락되므로 별도로 관리한다.
- 이 화면 인스턴스에서 종료를 관찰했는지와 명시적으로 확인했는지를 추적한다. 새 영속 저장 필드나 세션 JSON 변경은 없다.
- `_syncTimerEndAlarm()`을 두어 다음 조건을 모두 만족할 때만 시작한다.
  - 이 화면에서 실행 중 타이머의 만료를 관찰했다.
  - 현재 `arrived`이고 아직 확인하지 않았다.
  - 소리 켜짐, 앱 resumed, dispose/화면 종료/조기 완료 연출 중이 아님.
  - 종료를 묻는 별도 나가기 확인창이 열려 있지 않다.
- `_isAppResumed`의 초기값은 실제 binding lifecycle을 확인해 설정한다. null은 기존 실행 환경에 맞춰 resumed로 취급한다. 초기 background 상태에서 알람을 시작하지 않는다.
- `_handleTimerChanged()`는 도착 처리를 응원 스케줄보다 먼저 처리한다. 도착 시 예약된 응원 음성을 취소하고 재생 중 음성을 정지하며 활성 응원 영상 상태를 해제한다. 종료 후 응원 영상/음성을 다시 시작하지 않도록 관련 스케줄 및 지연 콜백도 조건으로 차단한다.
- BGM/응원 정지 요청을 먼저 발행하고 알람 시작을 요청한다. 알람 서비스는 BGM 정지 큐 완료를 기다린 뒤 시작한다. 응원 정지의 비동기 완료를 기다릴 경우 화면 요청 토큰을 확인하여 확인·음소거·백그라운드 전환 후 오래된 시작 요청이 살아나지 않게 한다.
- 알람 동기화는 패널 표시용 early return 전에 수행한다. 900ms 패널 표시 타이머 자체는 변경하지 않는다.

### 복귀 및 복원 정책

| 상황 | 동작 |
| --- | --- |
| 현재 화면에서 0 도달 | 소리 켜짐이면 즉시 반복 |
| 백그라운드에서 0 도달 | 소리 재생 안 함. 복귀 시 `refreshFromClock()` 후 미확인 알람 시작 |
| 울리는 중 background/inactive/hidden/detached | 정지, 같은 화면 resumed 시 처음부터 반복 |
| 울리는 중 음소거 | 정지, 미확인 상태에서 소리 다시 켜면 반복 |
| 완료/아직이야/결과 확인 선택 | 확인 상태를 먼저 기록하고 정지, 이후 재시작 금지 |
| 앱 재실행 시 이미 만료한 세션 복원 | 기존 도착 패널만 표시, 과거 알람 재생 안 함 |
| 남은 시간이 있는 running 세션 복원 후 만료 | 정상 알람 시작 |
| paused 세션 복원 | 재생 안 함. 재개 후 이 화면에서 만료하면 정상 시작 |

## 4. 정지 경로와 기존 결과 흐름 보존

- `_completeArrivalFromPanel()` 진입 가드 통과 직후 확인 상태를 동기적으로 기록하고 알람 정지를 요청한다. 결과 저장이나 화면 이동을 기다리지 않는다.
- `완료`, `아직이야`, 시간 종료형 결과 버튼 모두 같은 정지 경로를 이용한다. 저장 실패·재시도·중복 탭에도 알람을 되살리지 않는다.
- `_confirmComplete()`의 조기 완료 확인창이 열린 채 만료했을 때: 명시적으로 `완료` 또는 `아직이야`를 선택하면 알람만 확인 처리하고 기존 결과/취소 의미는 유지한다. `아직이야` 취소 후 도착 패널이 남아 있어도 복귀/소리 토글로 알람이 다시 켜지지 않는다. barrier/back으로 창을 닫은 것은 명시적 확인으로 취급하지 않는다. 시간 만료 전 선택에는 종료 알람 상태를 만들지 않는다.
- `_toggleTimerSound()`와 부모 config 변경인 `didUpdateWidget()` 모두 알람 동기화를 호출한다.
- `didChangeAppLifecycleState()`에서 모든 비활성 상태는 정지, resumed는 시간 보정 후 동기화한다.
- `_confirmExit()`는 기존처럼 타이머를 일시정지한다. 알람도 정지하고, 나가기 취소 후 arrived로 돌아오면 미확인 알람을 다시 시작한다. 나가기 확정은 세션 삭제 await 전에 재시작 금지 상태와 정지를 적용한다.
- 종료 응답 시 정지 요청을 먼저 발행하고, 알람 정지가 완료된 후 결과를 저장하고 이동한다. 정지 완료를 지연시키는 Fake로 이 순서를 검증한다.
- `_openResult()` 직전에 정지를 보장한다. dispose에서도 신규 시작을 차단하고 기존 소유권 규칙에 따라 stopAll/dispose로 정리한다. 화면 전환 애니메이션 동안 알람이 남아 결과 효과음과 겹치지 않게 한다.
- 종료 알람 정지만 추가하며 조기 완료 연출의 지연, `finish_arrival` 및 결과 화면의 환호/스티커 효과음은 변경하지 않는다.

## 5. 자동 검증

새 테스트는 기존 테스트 파일의 역할을 유지하면서 아래 두 파일에 모았다.
실제 소리 품질은 위젯 Fake나 메서드 채널 모의로 검증할 수 없으므로 실기기로 확인한다.

- `test/support/timer_test_harness.dart`: FakeTimerAudioService에 시작/정지 기록 추가.
- `test/timer_end_alarm_test.dart`:
  - 시간 만료 시 패널보다 먼저 알람 시작, 패널 표시 지연 유지 및 중복 시작 방지.
  - 완료/아직이야/시간 종료형 결과 버튼 정지, 정지 완료 후 저장 진행.
  - 저장 지연·실패 및 재시도 시 알람 재시작 방지.
  - 소리 토글과 부모 config 변경에 따른 정지/재시작.
  - 비활성 상태 정지/복귀 재생, 백그라운드 만료와 초기 inactive 상태 억제.
  - 이미 만료한 세션 복원은 무음, 남은 시간이 있는 running 세션 복원 후 만료는 재생.
  - 나가기 취소 시 재생/나가기 확정 시 정지, 주입 서비스의 stopAll 정리.
  - 만료 시 응원 영상 해제와 예약 음성 취소, 음성 로딩 중 종료 확인 시 늦은 알람 시작 방지.
  - 조기 완료 확인창이 열린 채 만료한 뒤 완료/아직이야 선택 시 정지.
- `test/timer_end_alarm_service_test.dart`: loop/mediaPlayer 설정, 중복 시작 억제, 시작 중 stop/dispose, 빠른 start-stop-start의 최종 상태, BGM 정지 순서, 재생 실패 후 정리 및 stopAll 검증.
- `test/timer_audio_asset_catalog_test.dart`: 파일 존재, 정확한 런타임 목록과 pubspec 등록 검증.
- `test/timer_session_audio_test.dart`: 만료 시 BGM 정지와 알람 시작 호출을 반영.
- `test/timer_completion_lifecycle_test.dart`: 방향 전환 검증에 FakeTimerAudioService를 주입해 네이티브 오디오 초기화와 분리. 기존 조기 완료 및 결과 전환 검증 유지.
- 기존 `test/activity_timer_controller_test.dart`, `test/timer_motivation_test.dart`도 회귀 검증에 포함.

관련 테스트만 실행할 때:

```sh
flutter test --no-pub test/activity_timer_controller_test.dart test/timer_session_audio_test.dart test/timer_completion_lifecycle_test.dart test/timer_motivation_test.dart test/timer_audio_asset_catalog_test.dart test/timer_end_alarm_test.dart test/timer_end_alarm_service_test.dart
```

최종 검증에 사용한 명령:

```sh
flutter test --no-pub
flutter analyze --no-pub
```

기존 테스트의 정확한 호출 목록에는 새 알람 호출을 반영했다. 관련 없는 기존 변경은 수정하지 않았다.

## 6. 구현 순서 및 완료 기준

1. 음원 등록, 카탈로그/README와 에셋 검증 갱신.
2. 전용 플레이어와 Noop/Fake 확장, 비동기 시작/정지 검증.
3. TimerScreen 만료/확인/소리/라이프사이클/화면 이탈 경로 연결, 응원과의 겹침 방지.
4. 관련 테스트와 analyze 실행, 실기기 확인 결과 보고.

완료 기준: 앱 foreground에서 확인할 때까지 반복되고 두 종료 선택 모두 정지한다. background에서는 울리지 않고 미확인 복귀 정책을 지킨다. 저장 지연·실패, 빠른 조작 및 화면 이탈로 알람이 남거나 다시 켜지지 않는다. 기존 결과/보상과 조기 완료 연출에 회귀가 없다.

## 수동 확인할 앱 영역/흐름

- Android/iOS 실제 기기에서 정상 만료 후 최소 30초 반복, 음량과 반복 경계.
- 완료/아직이야 및 시간 종료형 결과 버튼 선택 직후 정지.
- 소리 끄기/켜기, 잠금/홈 이동/복귀, 미확인 세션 앱 재실행.
- 종료 직전 응원 영상·음성, 세로/가로 회전, 나가기 취소/확정.
- 저장 지연 또는 실패 후 재시도, 결과 영상·환호와의 겹침 여부.
- 조기 완료의 주행·도착 효과음 및 기존 결과/스티커 흐름.
