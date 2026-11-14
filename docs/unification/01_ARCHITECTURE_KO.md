# Timey Rider 통합 아키텍처 설계

작성: 2026-11-14. **설계만 수행**. `T:`는 `timey_rider/`, `Y:`는 `jy_yamyam/`의 상대 경로다. 행 번호는 조사 당시 작업 트리 기준이다. VERIFIED=코드 직접 확인, PROPOSED=제안, ASSUMED=가정, BLOCKED=외부 증거/결정 필요. 이하 대상 구조·행동은 별도 표시가 없으면 PROPOSED다.

## 1. 결론

**기능 분리 대안 A를 중심으로 기존 경로를 유지하는 조합**을 권고한다. 이는 저장 대안 C(두 저장 기술 혼용)를 뜻하지 않는다. Daily는 Timey의 기존 경로에 유지하고 Mealtime만 `features/mealtime/`으로 이식한다. 타이머 시간 정책, 결과 선택, 기록·보상 서비스는 분리한다. 앱 진입, 프로필/사진, 차량 카탈로그, 구매 컨트롤러, 활성 세션 조정 및 내구성 있는 저장 장치만 공유한다. `MaterialApp` 하나와 기존 imperative `Navigator`를 유지하며 두 앱 전체를 중첩하거나 탭별 Navigator를 추가하지 않는다. 전역 단일 `ActiveSessionCoordinator`가 화면 수명과 별개로 한 세션만 소유한다. 두 보상 서비스에는 namespace가 고정된 저장 facade를 주어 다른 모드에 접근하지 못하게 한다.

**저장 방식은 재평가 후 D(SQLite에 모든 구조화 상태 저장)를 선택한다.** 이유는 과거 데이터 이관이 아니라 통합 앱이 저장 성공을 표시한 새 보상·세션·설정의 crash 복구 요구다. A(기존 SharedPreferences)는 다중 쓰기 경계가 남고 B(스냅샷)는 논리 일관성을 개선하지만 plugin의 disk durability 계약을 강화하지 않는다. C(설정은 preferences, 중요 데이터는 SQLite)는 가능하지만 DB가 이미 필요한 상황에서 두 저장 backend를 유지할 이점이 작다. 사진 bytes는 기존 파일 서비스에 두고 메타데이터만 DB에 넣는다. 상세 비교와 거절 사유는 [07](07_SIMPLIFICATION_REVIEW_KO.md), 최소 schema는 [03](03_DATA_IAP_DESIGN_KO.md)에서 정의한다.

**이관은 전면 제외한다.** 사전 출시 앱의 모든 로컬 테스트 데이터는 읽거나 변환하지 않는다. 새 DB와 새 사진 디렉터리를 처음 한 번 생성하며, 매 실행 삭제나 version 변경 때 초기화는 금지한다. 통합 앱이 생성한 데이터의 재시작·crash·미래 update 보존은 필수다. 이전 6개 테이블 제안은 `app_state`, `session_outcomes` **2개 테이블**로 줄인다. 범용 저장 프레임워크, importer, 앱 레벨 migration journal, 복구 대기열, 과거 데이터 backup은 만들지 않는다. 서버는 필요하지 않으며 통합이 Apple 승인 보장은 아니다.

## 2. 조사 스냅샷 — VERIFIED

| 항목 | Timey | Yamyam |
|---|---|---|
| 로컬 | `/Users/moonkong/dev/timey_rider` | `/Users/moonkong/dev/jy_yamyam` |
| origin | `https://github.com/moonkongv2/timey_rider.git` | `https://github.com/moonkongv2/jy_yamyam.git` |
| HEAD | `8871c5a4887df6ad8e492ef672a2d7e89965fe71` | `254feea3c4e33dea179dc86db838dcff94eafab1` |
| 현재 브랜치 | `fix/road-viewport-sizing` | `fix/road-viewport-sizing` |
| 버전 (`pubspec.yaml:19`) | `1.0.0+2` | `1.0.0+1` |
| Dart 제약 | `^3.9.2` | `^3.9.2` |
| iOS/Android ID | `com.timeyrider.app` | `com.yamyamrider.app` |
| IAP iOS / Android | `com.timeyrider.vehicle_pack` / `vehicle_pack` | `vehicle_pack` / `vehicle_pack` |

양쪽 기존 미커밋 파일: `docs/TIMER_END_ALARM_IMPLEMENTATION_PLAN.md`, `lib/widgets/road_view.dart`, `test/road_view_test.dart`, `test/timer_end_alarm_test.dart`. 수정·복원·스테이징하지 않았다. Timey에는 `yamyam` remote도 있다. 현재 로컬 SDK 캐시 `/opt/homebrew/share/flutter/bin/cache/flutter.version.json`: Flutter **3.44.1**, Dart **3.12.1**, stable. 저장소의 SDK 하한과 로컬 설치 버전은 다르며 실제 제출 빌드 SDK는 미확인이다.

`pubspec.lock`에서 공통: shared_preferences 2.5.5, path_provider 2.1.5, video_player 2.10.1, audioplayers 6.7.0. Timey IAP wrapper/android/storekit = 3.2.3 / 0.4.0+10 / 0.4.8+1, Yamyam = 3.3.0 / 0.5.1 / 0.4.10+1. image_picker, image, wakelock_plus, flutter_svg, url_launcher, package_info_plus도 사용한다. Timey의 path_provider_foundation 2.5.1 고정은 privacy manifest 관련 주석이 있다. Yamyam pubspec 전체를 합치지 않는다.

식별자 근거: T:`android/app/build.gradle.kts:45`, `ios/Runner.xcodeproj/project.pbxproj:418`, Y 대응 파일 `:48`, `:416`. 상품 근거 T:`lib/catalogs/vehicle_unlock_catalog.dart:7`, `ios/Runner/StoreKitConfiguration.storekit:48`, Y:`lib/constants/iap_product_ids.dart:2`.

## 3. 실제 구조와 통합 결정

아래 모든 기존 구현 설명은 VERIFIED. 복잡도/위험은 상대 평가다. 각 행의 테스트는 05 문서의 수용 기준으로 이어진다.

| 영역 | Timey 근거 | Yamyam 근거 및 차이 | 공통점 / 목표 / 검증 | 복잡도·위험 |
|---|---|---|---|---|
| 부트스트랩 | `lib/main.dart:14`, `lib/app.dart:47` 설정·구매 cache 후 앱 실행 | `lib/main.dart:16`, `lib/app.dart:53` 별도 startListening·scope | binding/portrait 공통. Timey root 하나, 새 DB 열기, 구매 구독 하나; 중복 구독 0 | 중·높음 |
| 온보딩 | `lib/app.dart:167` onboarding flag 후 이름 | `lib/app.dart:138` 이름 있으면 첫 안내 생략 가능 | 선택 화면 우선, 최초 안내는 선택 후 1회; 통합 앱 재실행 이름 재입력 0 | 중·중 |
| 홈/이동 | `lib/screens/home_screen.dart:98,321,777` RouteAware, push | 동일 경로 `:93,336,949` 식사 퀵스타트·차량 grid | 각각 유지, 헤더 모드 변경 버튼만 공유; 한 번으로 선택 화면 | 중·중 |
| 설정/프리셋 | `lib/services/local_saved_timer_preset_service.dart:12`, `local_recent_timer_service.dart:10` | `lib/catalogs/meal_course_catalog.dart:1`, `lib/config/meal_timer_policy.dart:21` | Daily 저장 5/즐겨찾기 3; Meal 15/25/35분 유지; 최근 저장 최대5 유지·4번째 즐겨찾기 거절 | 중·높음 |
| 실행 | `lib/controllers/activity_timer_controller.dart:9,155` 도착 ticker 취소 | `lib/controllers/meal_timer_controller.dart:11,152` 도착 후 ticker 계속 | wall clock/16ms 공통이나 정책 별도; 소유권만 coordinator로 이동 | 높음·높음 |
| 시간 범위 | `lib/catalogs/timer_duration_catalog.dart:1` custom 1~60 | `lib/config/meal_timer_policy.dart:21` 배포 5~60, nonrelease ALLOW_SHORT_TIMER 1분 | 동일 clamp 강제 금지; 1/4/5/60/61 경계 테스트 | 낮음·높음 |
| 종료 정책 | `lib/screens/timer_screen.dart:1209,1244` 도착 actualDuration=목표 시간, 활동별 timeEnded/needsMoreTime | `lib/controllers/timer_completion_flow_controller.dart:6`, `lib/screens/timer_screen.dart:1041` 완료/미완료·초과 완료 | 결과 정책 유지. 시간 도달 자체와 사용자 완료 확인 구분 | 높음·높음 |
| 복구 | `lib/services/active_activity_timer_session_store.dart:15,41` 별도 pendingActivityResult | `lib/models/active_meal_timer_session.dart:16` pendingCompletion 포함 | 새 envelope로 mode/config/pending 보존; 완료 의도 선저장 | 높음·높음 |
| 결과/스티커 | `lib/screens/result_screen.dart:309,344` 선택 후 기록 및 pending 정리 | `lib/screens/timer_screen.dart:1087,1100` pending 저장 후 recordMealResult | Timey 선택, Meal 완료 자동 1장; 동일 처리로 통합 금지 | 높음·높음 |
| 기록·목표 | `lib/services/local_activity_progress_service.dart:98,287,376,623` | `lib/services/local_meal_progress_service.dart:23,324,447,560` | 각각 2개 활성 목표, 1~20칸, 삭제 tombstone; 별도 service/transaction 유지 | 높음·최고 |
| 도로/마커 | `lib/widgets/road_view.dart:20`, `lib/catalogs/activity_marker_catalog.dart:6` | 동일 도로 경로, `lib/catalogs/meal_ingredient_catalog.dart:6` 식재료 | 렌더링 형태 공통. Meal road 복사·alias로 정책 보호, 공통화 후순위 | 중·높음 |
| 사진/차량 | `lib/services/local_avatar_image_service.dart:12,74`, `lib/catalogs/vehicle_catalog.dart:1` | 같은 책임·파일명, 설정 모델 타입 다름 | 자산 공용, config adapter로 공동 프로필 접근; 한 모드 사진 편집 양쪽 반영 | 중·높음 |
| 음향/화면 | `lib/services/timer_audio_service.dart:329`, `lib/screens/timer_screen.dart:633,661` | `lib/controllers/timer_lifecycle_controller.dart:1`로 일부 분리 | audio/awake/orientation는 visible route lease로 관리; 숨은 화면 무음 | 높음·높음 |
| 구매/보호자 | `lib/services/vehicle_pack_purchase_controller.dart:77`, `lib/widgets/purchase/parent_gate_sheet.dart` | `lib/controllers/vehicle_pack_purchase_controller.dart:85,217`, `lib/widgets/purchases/guardian_gate_sheet.dart` | Timey 구매 UI/단일 owner 채택, Meal caller adapter; 복원 및 pending 합동 테스트 | 높음·높음 |
| 언어/테마 | `lib/l10n/app_texts.dart:74,95`, `lib/theme/` | 동일 경로, TextSet interface 다름 | Dart 번들 유지, Meal 번들 별도 import, shared 문자열 추가 | 중·중 |
| feature flags | `lib/config/app_feature_flags.dart:1` | 동일 ENABLE_MOTIVATION_MEDIA 기본 false | 동영상 선언과 실제 flag 분리; off/on 모두 테스트 | 낮음·중 |

## 4. 대안 비교

| 평가 | A 분리 feature | B 공유 core+policy | C 최소 화면 복사 |
|---|---|---|---|
| 개발 노력 | 중~높음 | 매우 높음 | 처음 낮음, 복구 대응 높음 |
| 회귀 | 경계에서 집중 관리 | 종료·보상 전반 높음 | 숨은 전역/키 충돌 매우 높음 |
| 중복 코드 | 일부 유지 | 낮음 | 높음 |
| 테스트 용이성 | 원 테스트 이식 가능 | 정책 계약 새로 정의 | global 의존으로 낮음 |
| 유지보수 | 도메인 명확 | 장기 장점·초기 추상화 비용 | 시간이 갈수록 악화 |
| 데이터 격리 | 별도 service와 고정 scope로 강함 | mode 누락 위험 | raw key 충돌 위험 |
| IAP | 단일 owner adapter | 통합 쉬우나 대규모 변경 | 중복 listener 위험 |
| 향후 기능 | 각 모드 독립 개선 | 공통 정책 맞으면 효율 | 중복 수정 |
| 과설계 | 낮음~중간 | 높음 | 낮으나 무결성 부족 |

A를 선택하되 Daily 전체 MOVE는 하지 않는 C의 최소 변경 원칙을 적용한다. B의 범용 timer/reward engine은 이번 범위에서 기각한다. SQLite는 구조화 상태의 저장 경계 하나이며 보상 서비스는 각각 자기 namespace만 접근한다. 별도 generic transaction capability 계층은 만들지 않고 기존 service에 명시 저장 메서드를 주입한다.

## 5. 목표 디렉터리 및 상태 소유권

```text
lib/
  main.dart                         ADAPT 단일 bootstrap
  app.dart                          ADAPT 단일 MaterialApp
  app_mode.dart                     NEW enum AppMode
  navigation/
    app_route_observer.dart         KEEP 하나만 등록
    mode_navigation_controller.dart NEW route 변경 직렬화
  screens/                          KEEP Daily 화면 경로
    mode_selection_screen.dart      NEW
    home_screen.dart                ADAPT 헤더·전역 session 조회
    timer_screen.dart               EXTRACT 시간/완료 소유권, UI 유지
    result_screen.dart              ADAPT 저장 gateway
  controllers/activity_timer_controller.dart ADAPT 외부 owner
  models/                           KEEP Daily 모델
  services/
    local_activity_progress_service.dart ADAPT 저장 adapter
    local_settings_service.dart     ADAPT 공유 profile 분리
    active_activity_timer_session_store.dart REPLACE 내부 저장 경로
    vehicle_pack_purchase_controller.dart ADAPT 유일 구매 owner
    local_avatar_image_service.dart ADAPT durable path
  shared/
    session/active_session_coordinator.dart NEW
    session/session_envelope.dart   NEW
    session/daily_session_adapter.dart NEW
    storage/local_state_database.dart NEW 두 테이블·명시 메서드
    profile/shared_profile_store.dart NEW
    purchases/purchase_scope.dart   NEW Timey state 전달
    widgets/mode_switch_button.dart NEW
  features/mealtime/
    screens/                        MOVE(COPY) Y 화면, main/app 제외
    controllers/                    MOVE(COPY) Meal 정책 controller
    models/                         MOVE(COPY) Meal 전용 모델
    services/                       ADAPT namespace·storage·shared DI
    catalogs/                       MOVE(COPY) meal_course/ingredient
    widgets/                        MOVE(COPY) ingredient/meal/road UI
    l10n/                           MOVE(COPY) Meal 번들·5개 언어
  catalogs/vehicle_catalog.dart     KEEP 공유 catalog
  catalogs/vehicle_unlock_catalog.dart KEEP 기존 상품 ID
  widgets/purchase/                 KEEP 공유 구매 UI
  l10n/                             ADAPT 공용 ModeTextSet 추가
  theme/                            KEEP 공용 테마
```

MOVE(COPY)는 원본 Y 저장소 이동/삭제가 아니라 T의 새 feature 경로로 복사한다는 뜻이다. RETIRE는 통합 바이너리에 Y `main.dart`, `app.dart`, 구매 client/controller, 전역 observer를 포함하지 않는 것; Y 원본은 유지한다. EXTRACT는 필요 메서드만 점진 추출한다.

| 상태 | 유일 owner | 구독/변경 규칙 |
|---|---|---|
| 선택 모드 | ModeNavigationController | 메모리 값, 새 launch 자동 진입용으로 저장 금지 |
| 활성 세션·시간·완료 의도 | ActiveSessionCoordinator | 현재 session handle 하나; start/pause/complete/cancel 직렬화 |
| 시간 정책 | ActivityTimerController / MealTimerController | coordinator 소유, 화면은 borrow; dispose 금지 |
| 이름·사진·아바타 transform·선택 차량 | SharedProfileStore | 실행 중 config snapshot은 고정, 다음 세션에 적용 |
| entitlement | Timey VehiclePackPurchaseController | root 1개, store stream 1개, 두 모드 구독 |
| 모드 설정 | 각각 SettingsStore | shared field를 다시 저장하지 않음 |
| 기록·inventory·goals·statistics | 각각 ProgressService | 생성 시 고정한 namespace; UI mode 문자열로 변경 불가 |
| 화면 음향·orientation·wakelock | root PresentationLease | 현재 route에만 부여, 전환 완료 후 이전 lease 폐기 |

작은 계약 예시(구현 아님):
```dart
enum AppMode { mealtime, daily }
abstract interface class ActiveSessionCoordinator {
  ValueListenable<SessionView?> get active;
  Future<StartDecision> requestStart(SessionDraft draft);
  Future<void> resolveCompletion(SessionKey key, CompletionChoice choice);
  Future<void> cancel(SessionKey key); // 명시 확인 뒤에만
}
// SessionKey = (mode, sessionId), UI route나 timestamp만으로 식별하지 않는다.
```

상세 navigation은 [04](04_UX_NAVIGATION_KO.md), 저장·IAP 계약은 [03](03_DATA_IAP_DESIGN_KO.md), 작은 PR 순서는 [02](02_MIGRATION_PLAN_KO.md)를 따른다.

## 6. 유사성 재검증

기존 `/Users/moonkong/dev/APP_REVIEW_SIMILARITY_AUDIT_KO.md`를 참고했고 소스는 새로 읽었다. HEAD 비번역 Dart 수 T 91/Y 97을 재확인했다. 양 repo의 `rev-list --all` 교집합은 167개로 공통 이력이 있다. 현재 디스크 전체 assets의 같은 경로 파일 중 150개가 byte 동일하다(미선언 자료 포함; 기존 감사의 선언 자산 74/77 같은 지표와 비교 금지). `assets/videos/splash_animation.mp4`는 서로 다르므로 Timey 것을 유지한다. `meal` 활동, 공통 도로/구매/테마 구조, 상이한 완료·저장 정책은 코드로 재확인했다. 제출 IPA 동일성이나 실제 업로드 메타데이터는 확인하지 못했다.

## 7. 종료·스티커 세부 기준 — VERIFIED

근거: T `lib/models/activity_completion_status.dart:1`, `lib/screens/result_screen.dart:186`, `lib/services/local_activity_progress_service.dart:623`; Y `lib/models/meal_completion_status.dart:1`, `lib/controllers/timer_completion_flow_controller.dart:6`, `lib/services/local_meal_progress_service.dart:560`.

| 경우 | 현재 결과/지급 | 통합 보존 기준 |
|---|---|---|
| Daily completedBeforeEnd/AtEnd/AfterEnd | 완료이며 result에서 receiveSticker 미정이면 선택 | 선택 전 pending, 받기1장·건너뛰기0장 |
| Daily timeEnded | 완료로 분류, 기본 sticker eligibility false지만 result의 명시 true 선택은 service에서 우선 | 자동 무조건 지급/무조건 거절 모두 금지 |
| Daily needsMoreTime/canceled | 미완료, service는 지급하지 않음 | 기록과 보상 자격 별도 보존 |
| Meal 도착 전 완료 | completedBeforeArrival, 완료 차량 스티커1 | 조기 finish-drive 연출 유지 |
| Meal 도착 prompt 완료 | completedAtArrival | 확인 시 실제 elapsed, T처럼 무조건 target duration으로 덮지 않음 |
| Meal 일반 완료가 도착 뒤 | completedAfterArrival | 초과 완료 의미 보존 |
| Meal 도착 prompt 아직 안 끝남 | notCompleted, 스티커0 | 일반 조기 완료 prompt 거절은 timer 복귀이며 동일 처리 아님 |

T ActivityCatalog: brushing/reading/cleanup은 confirmDone·reward 기본 true, play는 timeEndsAutomatically·기본 false, meal/custom은 parentCheck·기본 false다. 이 기본값과 결과에서 명시한 receiveSticker는 서로 다른 단계다. 시간 정책 모델의 이름만 보고 최종 UI 지급 규칙을 추론하지 않는다.


추가 VERIFIED: 양쪽 `lib/models/*_progress_snapshot.dart:1`은 history/inventory/active/earned/used 목표를 담고, RecordedSession의 collectedStickerTypeCount는 count>0인 스티커 종류 수를 계산한다. 동일한 catalog를 공유해도 이 분자는 반드시 해당 mode inventory에서만 계산한다. `lib/services/orientation_service.dart:6`은 T `allowTimerOrientations`, Y `allowMealFlowOrientations`로 API 이름이 다르지만 portraitUp/landscapeLeft/landscapeRight 목록은 같다. 작은 adapter로 연결하며 화면별 dispose가 직접 전역 orientation을 되돌리지 않게 한다. 설정 보호자 gate 근거는 T `lib/screens/settings_screen.dart:198,230,252`, Y 동일 파일 `:173,184,200`이다.

## 8. 이번 개정의 범위

2026-11-14 개정. 사전 출시 데이터 이관 불필요는 확정 결정이다. 모든 이전 보존/변환/테스트 설치 호환 권고를 대체한다. 현재 source에 남은 fallback/옛 키 설명은 조사 근거일 뿐 구현 요구가 아니다. Daily의 `meal` 선택·실행은 제거하고 역사 표시·프리셋 변환·옛 세션 복구도 만들지 않는다. 단일 coordinator·각 mode 정책·공유 구매·5언어·origin home 복귀는 유지한다.

현재 source를 재확인한 결과 T `lib/services/local_saved_timer_preset_service.dart:80`은 6번째 저장을 일괄 거절하지 않고 최근 항목부터 `take(5)`한다. 이전 문서의 거절 서술을 수정했다. favorite는 3개 초과를 거절한다. 기존 기능 보존 테스트도 이 실제 동작을 따른다.
