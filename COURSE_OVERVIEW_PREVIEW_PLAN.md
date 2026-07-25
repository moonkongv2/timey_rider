# Course Overview Preview Plan

## Overview

`jy_yamyam`에 구현한 5분 초과 타이머의 코스 전체 보기 기능을 `timey_rider`에 적용한다.

`timey_rider`의 `RoadView`는 이미 `cameraProgress`와 `vehicleProgress`를 분리해서 받을 수 있으므로, 도로 렌더링 레이어는 큰 변경 없이 재사용한다. 주요 작업은 `TimerScreen`에서 초기 자동 프리뷰와 사용자가 실행하는 코스 전체 보기 프리뷰를 구분하고, 각 레이아웃에 버튼을 추가하며, 관련 문구와 테스트를 보강하는 것이다.

현재 `lib/screens/timer_screen.dart`에는 `_confirmExit()`에서 `_clearActiveSession()`을 `await`하도록 바꾼 미커밋 수정이 있으므로, 구현 시 이 변경을 유지하고 덮어쓰지 않는다.

## Commit 1: Split Preview State

### Goal

초기 자동 프리뷰와 사용자가 누르는 코스 전체 보기 프리뷰를 같은 카메라 애니메이션 기반으로 처리하되, 타이머/BGM/차량 진행 상태는 다르게 동작하도록 분리한다.

### Files

- `lib/screens/timer_screen.dart`

### Implementation

- 기존 `_isPreviewing` boolean을 enum 기반 상태로 교체한다.
  - `_CoursePreviewMode.none`
  - `_CoursePreviewMode.startup`
  - `_CoursePreviewMode.overview`
- 파생 getter를 추가한다.
  - `_isStartupPreviewing`
  - `_isCourseOverviewing`
  - `_isCameraPreviewActive`
- 5분 초과 판정은 `duration.inMinutes > 5` 대신 `duration > const Duration(minutes: 5)`로 통일한다.
  - `5분 30초`처럼 5분을 초과하지만 `inMinutes == 5`인 duration도 long course로 처리한다.
- 초기 자동 프리뷰는 기존 동작을 유지한다.
  - 차량 진행률은 0%에 고정
  - BGM은 프리뷰 종료 후 시작
  - 타이머 컨트롤은 비활성
- 코스 전체 보기 프리뷰를 추가한다.
  - 카메라는 0%에서 100%까지 이동
  - 차량은 현재 실제 진행률 유지
  - 타이머는 계속 진행
  - BGM은 계속 재생
- `_previewController`는 startup과 overview가 공유하되, listener 중복과 중간 취소를 피하도록 helper로 제어한다.
  - `_ensurePreviewController(Duration duration)` 또는 기존 controller 재설정 helper를 추가한다.
  - `_cancelCourseOverviewPreview()`는 overview 중인 경우 controller를 `stop()`하고 상태를 `none`으로 되돌린다.
  - `_cancelPreviewDelay()`는 startup delay 취소 용도로 유지하고, overview 취소가 startup sequence를 잘못 완료시키지 않게 mode를 확인한다.
- overview animation이 자연 완료될 때도 `_CoursePreviewMode.none`으로 상태를 되돌린다.
  - 자연 완료, 명시 취소, dispose 모두 같은 reset 경로를 사용해 UI가 overview 상태에 고착되지 않게 한다.
- `cameraDisplayProgress`는 `_isCameraPreviewActive`일 때 `_previewController.value`를 사용한다.
- `vehicleDisplayProgress`는 `_isStartupPreviewing`일 때만 0%로 고정하고, `_isCourseOverviewing`일 때는 실제 `displayProgress`를 유지한다.
- `_timerBgmTarget()`의 preview 차단 조건은 `_isStartupPreviewing` 기준으로 변경한다.
  - overview 중에는 running 상태 BGM이 계속 `playing`으로 유지되어야 한다.
- timer controls 비활성 조건은 `_isStartupPreviewing` 기준으로 변경한다.
  - overview 중 pause/resume과 complete는 누를 수 있어야 하며, 누르면 overview를 먼저 취소한다.
- course marker SFX는 camera overview 중 임의로 울리지 않도록 실제 차량 진행률 기준으로만 동작하게 유지한다.
  - 현재 `markerClearProgress`와 callback은 `vehicleDisplayProgress`를 사용하므로 overview에서 차량 진행률을 유지하면 이 조건을 만족한다.
- pause/resume, complete, arrival, exit, dispose 시 코스 전체 보기 프리뷰를 취소한다.
- `_confirmComplete()`는 초기 프리뷰 중에는 기존처럼 차단하고, 코스 전체 보기 중에는 프리뷰를 취소한 뒤 완료 플로우로 진입하게 한다.
- 기존 `_safeDelay()` / `_cancelPreviewDelay()` 구조는 유지한다.

## Commit 2: Add Controls And Localization

### Goal

5분 초과 타이머에서 코스 전체 보기 버튼을 노출하고, portrait/landscape/compact landscape 레이아웃에서 동일한 기능을 제공한다.

### Files

- `lib/screens/timer_screen.dart`
- `lib/l10n/text_sets.dart`
- `lib/l10n/ko/timer.dart`
- `lib/l10n/en/timer.dart`
- `lib/l10n/ja/timer.dart`
- `lib/l10n/es/timer.dart`
- `lib/l10n/pt_BR/timer.dart`

### Implementation

- 버튼 노출 조건을 추가한다.
  - 타이머 duration이 `const Duration(minutes: 5)` 초과
  - 타이머가 시작된 상태
  - 종료/도착 완료 상태가 아님
  - 초기 자동 프리뷰 중이 아님
  - finish drive 중이 아님
- portrait AppBar의 motivation 설정 버튼 옆에 코스 보기 버튼을 추가한다.
- landscape 상단 액션 영역에 코스 보기 버튼을 추가한다.
- compact landscape controls에 코스 보기 버튼을 추가한다.
  - 기존 버튼 4개 기준 높이 기대값(`<= 280`)은 버튼 1개 추가 시 그대로 유지하기 어렵다.
  - 버튼 크기/간격을 줄이거나 action slot 기대값을 실제 레이아웃에 맞게 조정해 852x393 compact landscape에서 overflow가 없도록 한다.
  - 버튼 터치 영역이 지나치게 작아지지 않도록 최소 크기와 tooltip/semantics label을 유지한다.
- 코스 보기 버튼은 icon button으로 제공한다.
  - key: `courseOverviewButton`
  - icon: `Icons.map_rounded` 또는 기존 디자인과 더 잘 맞는 Material icon
  - tooltip/semantics label: `texts.timer.viewCourseButton`
- overview가 이미 실행 중일 때 코스 보기 버튼은 비활성화한다.
  - 반복 탭으로 animation restart/cancel 의미가 섞이지 않게 하고, pause/complete/exit 같은 명시 액션에서만 overview를 취소한다.
- 문구를 추가한다.
  - ko: `코스 보기`
  - en: `View course`
  - ja: `コースを見る`
  - es: `Ver ruta`
  - pt_BR: `Ver rota`

## Commit 3: Add Tests

### Goal

코스 전체 보기 기능이 타이머 진행, BGM, 완료/도착 플로우, 레이아웃과 충돌하지 않는지 검증한다.

### Files

- `test/widget_test.dart`

### Test Cases

- 5분 초과 running/restored timer에서 코스 보기 버튼이 보인다.
- `5분 30초` timer에서 코스 보기 버튼이 보인다.
- 5분 이하 timer에서는 코스 보기 버튼이 보이지 않는다.
- 버튼을 누르면 `cameraProgress`는 움직이고 `vehicleProgress`는 현재 진행률에 남는다.
- 코스 보기 중 pause/resume을 누르면 프리뷰가 취소된다.
- 코스 보기 중 complete를 누르면 프리뷰가 취소되고 완료 플로우가 정상 진입한다.
- 코스 보기 중 exit 확인 dialog를 열면 프리뷰가 취소되고 기존 pause/resume-on-cancel 동작이 유지된다.
- exit confirm 시 `_clearActiveSession()` await 동작이 유지된다.
  - delayed fake store로 clear가 끝나기 전 route 제거가 일어나지 않는지 검증해 기존 미커밋 변경을 보호한다.
- 도착 상태로 전환될 때 프리뷰가 취소되고 arrival panel/result 플로우가 유지된다.
- compact landscape에서 버튼 추가 후 action slot 레이아웃이 유지된다.
- BGM은 초기 자동 프리뷰 중에는 억제되고, 코스 전체 보기 중에는 계속 재생된다.
- startup preview 중에는 코스 보기 버튼과 timer controls가 비활성/미노출 상태를 유지한다.

## Verification

```bash
dart format lib/screens/timer_screen.dart lib/l10n/text_sets.dart lib/l10n/*/timer.dart test/widget_test.dart
dart analyze
flutter test test/widget_test.dart --plain-name "course overview"
flutter test test/widget_test.dart --plain-name "TimerScreen starts timer BGM after preview finishes"
flutter test test/widget_test.dart --plain-name "Timer screen places controls inside compact landscape course action slot"
flutter test test/widget_test.dart --plain-name "Timer screen"
```

## Manual Checks

- 5분 초과 activity timer 시작 후 초기 자동 프리뷰 종료
- 실행 중 `코스 보기` 버튼 탭
- 차량은 현재 위치에 있고 카메라만 코스 전체를 훑는지 확인
- 코스 보기 중 BGM이 끊기지 않는지 확인
- 코스 보기 중 pause, complete, exit 동작 확인
- portrait, landscape, compact landscape에서 버튼 위치와 터치 영역 확인
- arrival panel이 뜨는 타이머에서 코스 보기와 도착 플로우가 충돌하지 않는지 확인
