# 검증·출시 준비 계획

이번 작업은 설계 문서 개정만 했다. **Flutter test/analyze/build, 앱 실행, StoreKit/Play Billing 구매, 실기기 테스트는 실행하지 않았다.** 테스트 통과를 주장하지 않는다. SDK/생성 파일·cache 쓰기를 유발하는 baseline 실행은 향후 P0 구현 작업으로 남겼다. 이번 검증은 source 조사, 문서 경로/구조 확인, 기존 tracked 변경 목록·diff 통계·HEAD 비교, agy 설계 리뷰다.

## 1. 기존 테스트 회귀 목록 — VERIFIED 파일 존재, 통과 미확인

T `_test.dart` 63개, Y 71개. 중복 테스트 이름은 Meal feature 아래 별도 유지한다.

| 영역 | Timey 기존 test/ | Yamyam 기존 test/ |
|---|---|---|
| 실행/설정 | activity_timer_controller_test.dart, activity_timer_config_test.dart, activity_domain_test.dart | meal_timer_controller_test.dart, meal_timer_policy_test.dart, meal_timer_config_test.dart |
| 저장/복구 | active_activity_timer_session_store_test.dart, pending_activity_result_storage_test.dart, home_active_session_test.dart | active_meal_timer_session_store_test.dart, timer_active_session_controller_test.dart, home_active_session_test.dart |
| 완료 | timer_completion_lifecycle_test.dart, pending_activity_result_test.dart, result_screen_test.dart | timer_screen_completion_test.dart, timer_completion_flow_controller_test.dart, result_screen_test.dart |
| 기록/목표 | local_activity_progress_service_test.dart, activity_history_linked_delete_test.dart, reward_history_screen_test.dart | local_meal_progress_service_test.dart, meal_history_linked_delete_test.dart, reward_goal_screen_test.dart |
| 홈/프리셋 | timer_builder_test.dart, timer_builder_preset_test.dart, local_saved_timer_preset_service_test.dart, local_recent_timer_service_test.dart | home_course_start_test.dart, home_rewards_test.dart, meal_ingredient_catalog_test.dart |
| 구매 | vehicle_pack_purchase_controller_test.dart, app_purchase_recovery_test.dart, iap_purchase_client_test.dart | vehicle_pack_purchase_controller_test.dart, android_purchase_state_test.dart, app_purchase_wiring_test.dart |
| 미디어·회전 | timer_end_alarm_test.dart, timer_session_audio_test.dart, timer_layout_lifecycle_test.dart, road_view_test.dart | timer_end_alarm_test.dart, timer_audio_lifecycle_test.dart, timer_screen_lifecycle_test.dart, road_view_test.dart |
| 아바타/보호자 | local_avatar_image_service_test.dart, avatar_setup_purchase_test.dart, parent_gate_sheet_test.dart | local_avatar_image_service_test.dart, avatar_setup_vehicle_lock_test.dart, guardian_gate_sheet_test.dart |
| 번역/자산 | localization_support_test.dart, locale_smoke_test.dart, release_asset_bundle_test.dart | purchase_localization_test.dart, release_asset_bundle_test.dart |

P0에서 각 앱의 `flutter test`, `flutter analyze` 결과를 분리 보관한다. 수정된 road/alarm test는 현재 작업 트리 결과로 표시하고 HEAD 결과로 주장하지 않는다. 기존 실패가 있으면 명령·실패 test·원인·통합 변경과 관련 여부를 기록한다.

## 2. 새 데이터 unit 테스트 계약

과거 테스트 설치를 보존하는 fixture는 제거 대상이다. 기존 정상 정책 회귀 fixture는 유지한다. 아래는 **예정 테스트이며 실행 결과가 아니다**.

| ID | 입력/실패 주입 | 측정 가능한 기대 |
|---|---|---|
| U01 | Daily custom1/60 경계, Meal release1/4/5/60/61, ALLOW_SHORT_TIMER | 원본 duration 정책 유지, release Meal 최소5 |
| U02 | Daily 활동별 조기/도착/초과/미완료, Meal 조기/도착 prompt 거절 | 원본 status/actualDuration/sticker 정책 유지; Daily meal 입력은 거절 |
| U03 | Daily 5장, Meal 완료 | Meal만 +1, Daily history/inventory/goals/revision 불변 |
| U04 | Meal 5장, Daily 받기/skip | Daily +1/0, Meal 전 필드 불변 |
| U05 | 동일 mode sessionId completion100회, 양 mode 같은 raw ID | 각 outcome 최대1, 타 mode 접근0, 중복 지급0 |
| U06 | 완료와 기록삭제의 반복/경합 | deleted outcome 승리, 부활/이중 차감0 |
| U07 | goal2개, earned→used, 연결 history 삭제 | 기존 배분/used 보존, 원자적 state 변화 |
| U08 | 새 DB 최초 생성 후 반복 open100회, 옛 preferences 오염 fixture 존재 | defaults 최초1회, 옛 값 미참조, 신규 데이터 reset0 |
| U09 | DB open/write/disk-full 예외, unified payload 손상 | 기존 정상 committed 데이터 유지, 자동 빈 초기화0, 오류 전달 |
| U10 | running/paused/arrived 복구·clock ±1h·24h/48h 경과 | pause 시간 증가0, 자동 clear0, 확인 전 지급0 |
| U11 | concurrent start20회·stale revision pause/clear | active1개, 오래된 command가 새 session 수정0 |
| U12 | entitlement save 실패/ack 실패/unknown product/반복 event | save 전 ack0, 양 mode 권한 동일, reward mutation0 |
| U13 | restore Future 선완료/늦은 event/empty/timeout 후 성공 | 무한 loading0, 늦은 성공 반영, 기존 cache 박탈0 |
| U14 | photo flush 실패·DB 저장 실패·참조 중 photo 변경 | 기존 profile 유지, active/outcome 파일 삭제0 |
| U15 | cancel+start transaction 각 단계 실패 | old 유지 또는 new 하나, 둘 다 사라지는 상태0 |
| U16 | Daily sticker 미선택, Meal 확인 전 arrived, 확인 후 pendingCompletion 각각 | 미확정 지급0; 확정은 같은 intent로 commit1회·재확인0 |
| U17 | shared profile 수정과 IAP cache 갱신 동시 | 두 필드 보존, lost update0 |
| U18 | 저장 preset6개/favorite4개/전부 삭제 후 restart | saved는 원본 정책대로 최근 최대5, favorite 상한3, 삭제 후 defaults 부활0 |
| U19 | 미래 unified schema update fixture(실제 변경 시) | v1 신규 데이터 유지·실패 rollback·unknown newer schema 초기화0 |

과거 설치 호환 decoder·journal replay·migration marker·backup/queue·old meal preset 변환 fixture는 필요 없다. U08의 옛 키 fixture는 이관 검증이 아니라 **읽지 않는지**를 증명하는 단일 격리 검사다. DB fake는 commit 계약만 검증하고 disk crash 보장은 실기기로 확인한다.

## 3. widget 검증

| ID | 흐름 | 기대 |
|---|---|---|
| W01 | 통합 신규 설치·재실행 | 항상 fresh selector, 이름/안내는 최초1회 |
| W02 | Meal/Daily 선택 | 각 기존 home UX·올바른 mode 제목 |
| W03 | home switch100회 | stack 누적0, 실행 ID 불변, listener 중복0 |
| W04 | 각 history/sticker/goal | 자기 mode 저장 facade만 주입 |
| W05 | 실행 중 새 start | return/cancel+start/stay 계약, 조용한 취소0 |
| W06 | 미확정 result back/restart | banner와 동일 intent 복구, 새 start는 확인 우선 |
| W07 | 공용 구매 성공/pending/restore | 양 mode 차량 일치, 재구매 command0 |
| W08 | purchase inactive/resumed | fresh selector로 강제 전환0, timer 유지 |
| W09 | result home·deleted cleanup·selector 결과 banner | origin home back, 잘못 route.isFirst pop0 |
| W10 | DB 오류·corrupt unified payload | retry/error, 빈 지갑으로 조용히 계속0 |
| W11 | Daily builder/preset/recent/direct start meal 입력 | 신규 Daily meal session 생성0, 이관 UI 없음 |
| W12 | locale5×orientation2×large text | overflow0, 독립 보상 label·접근성 |

## 4. integration·실기기

| ID | 시나리오 | 기대 |
|---|---|---|
| I01 | Meal quick15/25/35, custom5/60, ingredient/manual, pause, 조기/도착/초과/미완료 | 기존 정책·선택 ID 유지, Daily 변화0 |
| I02 | Daily 활동/default/custom1/60/preset/favorite/recent/marker | 기존 정책 유지, Meal 변화0 |
| I03 | 각 mode 실행 중 switch/background/lock/kill/relaunch | elapsed/pause/ID/config 유지, cold selector+복구 banner |
| I04 | completion/delete/goal use의 DB transaction 중 kill | 전체 전/후만, 부분 history/보상0 |
| I05 | 다른 mode에서 시간 만료 | 단일 banner/alarm, 확인 전 지급0 |
| I06 | unified v1 데이터 생성 후 재실행·후속 unified 앱 update | history/inventory/goal/preset/profile/session 유지, reset0 |
| I07 | 빈 local cache→실제 Timey store restore→양 mode→offline restart | 동일 차량 해제, 무료2종 유지, entitlement 보존 |
| I08 | 기록만 삭제/연결 삭제·earned/used 조합 | 반복 callback과 경합에도 부활/이중 차감0 |
| I09 | 시작/일시정지/설정/preset 저장 성공 직후 kill | 성공한 신규 상태 유지, 실패면 명시 retry |
| I10 | 실제 iPad portrait/landscape/split view와 Android tablet/phone | 화면 잘림/버튼 접근 불가0 |
| I11 | completion commit 직후 result UI 전 kill | 미확인 outcome/config 복구, 홈/닫기 ack 후 banner0, 재지급0 |
| I12 | 정상 fresh 설치와 반복 launch/update/restore | 최초 defaults1회, startup 전체 clear/delete0 |

**iOS:** Xcode StoreKit T 상품 ID로 성공/취소/interrupted/pending/빈 restore/재설치 시험, 이어 실제 sandbox/TestFlight에서 상품 조회와 실제 Timey 구매 restore를 검증한다. iPhone과 심사 iPad에서 사진 허용·거절, 무음/헤드폰, orientation, parent gate, 외부 support 링크, 5언어 확인. StoreKit mock 성공은 Console 설정 증거가 아니다.

**Android:** Play 내부 테스트+license tester로 성공/지연 승인·거절/구매 중 kill/ack 오류/재시작 restore/계정 변경을 검증한다. pending에서 unlock0, PURCHASED 이후 ack 및 retry. 같은 Timey package 실제 구매는 local 초기화 뒤 복원 가능, 별도 Y package 구매만으로 T 해제0. [Play Billing 수명주기](https://developer.android.com/google/play/billing/lifecycle/one-time).

## 5. 단계별 필수 게이트와 성능

- P1: fake 주입 W01/W02/W09. DB 작업 전 navigation을 검증할 수 있다.
- P2: U03~U09/U17/U18을 도메인 fixture로 구동한 저장 메서드 단위 검사 및 실제 SQLite 생성·transaction smoke. SharedPreferences 원본 읽기0.
- P3/P4: 양 정상 흐름과 공유 IAP/profile 테스트. production 두 mode 실행은 아직 비노출.
- P5: U05/U06/U10/U11/U15/U16, W03~W11, I03/I04/I05/I11. 통과 전 public switch 금지.
- P7: 전체 필수 suite 및 실제 iOS/Android restore/kill/update. 새 데이터 유실·중복 지급·mode 누출·동시 실행0건.

cold selector 표시, 60분 실행 frame time, switch100회 memory/ticker/video 자원, history1,000/10,000건 snapshot encode·쓰기 시간을 동일 기기 profile/release로 baseline과 비교한다. 지금은 수치를 측정하지 않았고 DB 선택으로 빨라진다고 주장하지 않는다. SQL은 tick마다 실행하지 않는다. frame을 지속적으로 막는 payload 크기가 확인될 때만 해당 저장 구조 최적화를 별도 검토한다. 단일 구매 subscription1, active controller1, 화면 밖 video decoder0을 확인한다.

## 6. 출시 전환 체크리스트

- [ ] Timey Rider 표시 이름/아이콘/launch splash 유지, iOS·Android `com.timeyrider.app` 유지.
- [ ] 상품 ID T iOS `com.timeyrider.vehicle_pack`, Android `vehicle_pack` 유지; 실제 Timey store 구매 restore 증거 확보.
- [ ] 실제 제출 build/version 기록을 Console과 대조. `build-3` tag와 pubspec build number를 동일하다고 추정하지 않음.
- [ ] 하나의 앱 안 두 mode 목적, 독립 보상, 공용 차량팩을 description/review notes에 명시.
- [ ] ko/en/ja/es/pt_BR의 실제 mode selector·Meal·Daily·reward·purchase screenshot, iPad 규격과 layout 검증.
- [ ] Kids category 실제 선택 여부·연령·metadata·parent gate·외부 링크·purchase 진입을 검토. 현재 repository만으로 등록 category 단정 금지.
- [ ] 사진의 로컬 저장·백업/삭제·지원 요청 시 데이터 처리, IAP plugin privacy manifest를 실제 binary와 privacy/support 문서에 일치시킴.
- [ ] Yamyam 중복 제출 철회/배포 중단 시점 확인(사전 출시 로컬 데이터 이전 안내는 불필요). 해당 Console 작업은 별도 담당자가 수행.
- [ ] Google Play는 기존 Timey app 등록을 유지하고 Y package를 Timey로 이름만 바꿔 업그레이드한다고 설명하지 않음. 데이터 안전성·대상 연령·billing 조건은 제출 시 재확인.
- [ ] 실제 iOS/iPad/Android 검증, phased rollout/문제 모니터링 담당자·동일 schema hotfix 준비.

Apple 4.3 및 Kids/metadata 요구는 제출 시 최신 원문과 실제 심사 메시지를 확인해야 한다. 통합이 승인 보장은 아니다. [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [Kids category 안내](https://developer.apple.com/app-store/categories/).

## 7. 남은 위험과 이번 검증 범위

DB plugin SDK 호환성·실제 crash/restore·iPad layout은 아직 미검증이다. local cache로 강한 부정 구매 방지나 실시간 revocation을 보장하지 않는다. 실제 사용자의 옛 데이터 샘플 확보나 역사 복원은 출시 blocker가 아니다.

이번 개정은 Markdown 문서만 변경한다. Flutter test/analyze/build와 실제 구매/기기 조작은 하지 않았다. source 재조사·문서 정합성·파일 hash·Git 상태 및 agy 설계 리뷰 결과는 [06](06_DECISIONS_AND_OPEN_ISSUES_KO.md)에 기록한다. 이전 설계 리뷰 결과를 이번 개정 검증으로 간주하지 않는다.
