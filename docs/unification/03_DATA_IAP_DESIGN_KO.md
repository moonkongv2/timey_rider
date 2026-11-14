# 통합 앱의 신규 데이터·구매 저장 설계

2026-11-14 개정. T=`timey_rider/`, Y=`jy_yamyam/`. VERIFIED는 이번 source 재확인, PROPOSED는 구현할 설계, ASSUMED는 명시 가정이다. 사전 출시 앱 데이터는 이관하지 않는다. 기존 source의 키·journal 설명은 관찰이며 재구현 요구가 아니다. 저장 대안의 전면 비교는 [07](07_SIMPLIFICATION_REVIEW_KO.md).

## 1. 실제 코드의 저장 경계 — VERIFIED

| 책임/근거 | 현재 쓰기·복구·중복 방지 | 확인한 한계와 최소 수정 |
|---|---|---|
| T `lib/services/local_activity_progress_service.dart:17,407,511,579` | static queue; sessionId 중복 조회와 deleted IDs; `activityRecordTransaction` 저장→목표 키별 쓰기→journal 제거; 읽기 전 replay | 프로세스 내 직렬화와 재시도에 유용하나 preferences 다중 키 disk transaction은 아님. 보상 계산 유지, 쓰기 부분만 DB transaction으로 교체 |
| Y `lib/services/local_meal_progress_service.dart:23,34,57,448` | preferences별 Expando queue; completion journal에 history/inventory/active/earned 및 삭제 시 tombstone; sessionId 있으면 중복 기록 반환 | 일부 goal 작업은 journal 밖. sessionId 없는 fallback을 새 실행에서 금지; 동일 계산을 DB로 저장 |
| Y 동일 `:265` useEarnedRewardGoal | earned 목록 저장 후 used 목록 저장 | 첫 쓰기 후 실패하면 보상 사용 상태가 한쪽에만 반영될 수 있음. 하나의 상태 갱신 transaction 필요 |
| T `lib/services/active_activity_timer_session_store.dart:46,82,140` | pending 먼저 저장→active 제거; sessionId 매칭 cleanup; 예외 시 reload | active save는 bool 반환 검사가 없고 decode 오류는 null 반환. progress와 다른 queue/쓰기 경계. active/pending을 한 전역 row에 통합 |
| Y `lib/services/active_meal_timer_session_store.dart:12,38,48` | queue, save/remove bool 검사, malformed load는 null | progress와 별도 queue; `controllers/timer_active_session_controller.dart:58`는 저장 오류를 log만 함. 오류를 caller에 전달해야 함 |
| T `lib/screens/result_screen.dart:309` | pending choice 갱신→recordActivityResult→clearPendingResult | session/progress 일괄 commit 아님. 화면이 저장을 소유하지 않게 변경 |
| Y `lib/screens/timer_screen.dart:1080,1096` | 확정 pendingCompletion 저장→recordMealResult→session clear→연출 | 사용자가 이미 확인한 결과와 미확인 arrived를 구분해 root에서 처리 |
| 양 home T `:154`, Y `:174` | 24h 지난 session clear; Y는 확정 pending 자동 기록·clear | 통합 앱의 새 session도 삭제될 수 있는 실제 코드 경로. 자동 삭제/화면 직접 기록 제거 |
| T `local_saved_timer_preset_service.dart:35,80,143`, `local_recent_timer_service.dart:10` | saved JSON 후 initialized bool; 최근 JSON 한 키, parse 오류 시 빈 값 | 저장 성공 반환 검사·동시 read-modify-write 보호 부족. defaults·최대5·favorite3 정책 유지, DB에서 read/modify/write |
| 양 `local_settings_service.dart` T `:8`, Y `:9,116` | config의 필드를 여러 setBool/setString/setDouble로 저장 | 중간 실패 시 설정 조합 불일치. shared profile과 mode 설정을 나누고 한 명령의 변경은 한 transaction |
| T `local_purchase_entitlement_store.dart:37`, Y 동일 `:39` | T unlocked 먼저/metadata 후, 반환 검사 없음; Y metadata 후 unlocked, 일부 bool 검사 | store 권한과 로컬 cache는 별개. unified cache row 저장 실패를 성공으로 표시하지 않음 |
| 양 `local_avatar_image_service.dart:17,74,83` | image bytes flush 후 경로 반환; Documents 실패 시 systemTemp fallback | 임시 사진을 영구 저장처럼 처리할 수 있음. unified Documents 전용, 저장 실패 시 기존 profile 유지 |

위 실패 경로는 코드에서 확인했지만 실제 기기 데이터 유실을 재현하거나 발생률을 측정한 것은 아니다. 특히 journal이 살아 있으면 다음 읽기의 replay가 부분 쓰기를 복구할 수 있다. 이를 무시하고 모든 다중 쓰기가 반드시 유실된다고 주장하지 않는다. 반대로 queue/재조회/await가 disk flush를 보장한다고도 주장하지 않는다.

## 2. 현재 키 인벤토리와 목표 소유권

모든 키는 SharedPreferences API 이름이다. 아래 원본 키는 **통합 runtime에서 읽지 않고 이관하지 않는다**. 목표 경로는 DB JSON payload의 논리 경로이며 새로운 preferences key가 아니다.

| 원본 키 | 존재·source | 목표 |
|---|---|---|
| `durationMinutes`, `showRemainingTime`, `soundEnabled`, `motivationVideoEnabled`, `motivationVideoUseCustomInterval`, `motivationVideoIntervalMinutes`, `keepScreenAwake` | 양 `local_settings_service.dart` T:8/Y:9 | 각각 `daily.settings.*`, `mealtime.settings.*` |
| `activityId`, `markerMode` | T 동일:17,29 | `daily.settings.*` |
| `courseIngredientMode` | Y 동일:28 | `mealtime.settings.*` |
| `vehicleId`, `childName`, `avatarMode`, `customAvatarImagePath`, `customAvatarVehicleId`, `avatarScale`, `avatarOffsetX`, `avatarOffsetY`, `avatarRotationDegrees`, `customAvatarsByVehicle` | 양 settings | `shared.profile.*` |
| `hasSeenOnboarding`, `hasSeenFirstRunOnboarding` | T/Y settings | 새 `shared.onboarding` 및 `mealtime.onboardingSeen`, 원본 flag 미참조 |
| `activityHistory`, `activityRewardInventory`, `activityActiveRewardGoals`, `activityEarnedRewardGoals`, `activityUsedRewardGoals` | T `local_activity_progress_service.dart:100` | `daily.progress`의 history/inventory/activeGoals/earnedGoals/usedGoals |
| `deletedActivitySessionIds` | T 동일:18 | 새 `session_outcomes.status=deleted`, 중복 tombstone 목록 없음 |
| `mealHistory`, `rewardInventory`, `activeRewardGoals`, `earnedRewardGoals`, `usedRewardGoals` | Y `local_meal_progress_service.dart:23`; T에서도 fallback | `mealtime.progress` 대응 필드, T fallback 제거 |
| `deletedMealSessionIds` | Y 동일:23 | 해당 mode `session_outcomes.status=deleted` |
| `activityRecordTransaction`, `mealCompletionJournal` | T/Y progress | 원본 journal 미참조; DB native transaction으로 대체 |
| `activeRewardGoal`, `redeemedRewardGoals` 및 T의 일반 Meal 키 fallback | 양 progress 구형 호환 | 사용 중지, 읽기/변환/replay/cleanup 없음 |
| `pendingActivityResult`, `activeActivityTimerSession`, `activeMealTimerSession` | T active store:15,41,44 / Y active store:10 | 단일 `app_state['session']` 새 envelope |
| `savedActivityTimerPresets`, `savedActivityTimerPresetsInitialized`, `recentActivityTimerPreset` | T saved:14/recent:10 | `daily.presets.saved`, `.recent`; 초기 기본값은 DB 최초 생성에서만 |
| `purchase.vehiclePackUnlocked`, `purchase.vehiclePackUpdatedAt`, `purchase.vehiclePackSource` | T entitlement store:14 | `shared.entitlement` 새 cache, 원본 cache 미참조 |
| `purchase.vehiclePackUnlocked`, `purchase.vehiclePackProductId`, `purchase.vehiclePackPurchasedAt`, `purchase.vehiclePackLastUpdatedAt`, `purchase.vehiclePackSource`, `purchase.vehiclePackTransactionId` | Y entitlement store:8 | 원본 cache 미참조, Y 상품을 T 권한으로 인정하지 않음 |

`legacyUsedSourceToRemove`는 T journal 내부 필드이며 preferences 키가 아니다. 원본 JSON 안의 과거 session ID alias/unknown field 보존을 위한 코드도 통합 저장 경로에서 필요 없다. 단, 현재 model의 mode-specific 필드·duration 단위·기능은 그대로 유지하고 새 v1 encoder/decoder의 round-trip을 검증한다.

키 충돌 위험은 데이터 이관이 없어도 두 서비스를 그대로 붙이면 생긴다. T의 `mealHistory` fallback, Y의 일반 reward 키, 양 settings 키와 purchase cache 이름은 동일하다. **분리된 repository의 고정 scope + 원본 preferences 접근 제거**가 해결책이다. UI에서 mode를 필터링하는 방식은 허용하지 않는다.

## 3. 선택: D를 작은 저장소로 구현

SharedPreferences 공식 문서는 쓰기 반환 후 disk 영속성을 보장하지 않는다. single snapshot·reload·직렬화는 이 계약을 강화하지 않는다. [공식 문서](https://pub.dev/packages/shared_preferences). SQLite는 transaction과 native crash recovery를 제공하지만 하드웨어/파일시스템의 정상 동작과 설정을 전제로 한다. [SQLite atomic commit](https://sqlite.org/atomiccommit.html).

PROPOSED: `LocalStateDatabase` 하나, `sqflite` runtime 의존성 하나. 최신 버전을 무조건 선택하지 않고 P0에서 Dart ^3.9.2 및 배포 OS 하한과 호환되는 버전을 고정한다. 실제 설치/빌드·테스트는 이번 작업에서 하지 않았다. [sqflite 패키지 문서](https://pub.dev/packages/sqflite).

파일: Application Support의 **고정 경로** `timey_unified.db`. 파일명에 앱 버전을 넣어 업데이트 때 새 DB를 만들지 않는다. `onCreate` transaction에서 기본 row 4개와 최초 Daily preset 두 개(양치/놀이)를 한 번 생성한다. 통합 전 preferences/사진/DB 후보는 탐색하지 않는다. DB가 존재하는데 row가 없거나 decode가 실패하면 빈 값으로 재초기화하지 않는다.

```text
app_state(
  scope TEXT PRIMARY KEY CHECK scope IN ('daily','mealtime','shared','session'),
  revision INTEGER NOT NULL,
  payload_json TEXT NOT NULL
)
session_outcomes(
  mode TEXT NOT NULL CHECK mode IN ('daily','mealtime'),
  session_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK status IN ('completed','canceled','deleted'),
  result_json TEXT NULL,
  config_json TEXT NULL,
  acknowledged_at TEXT NULL,
  PRIMARY KEY(mode, session_id)
)
```

payload 구조:
- `daily`: settings, presets(saved/recent), progress(history/inventory/activeGoals/earnedGoals/usedGoals).
- `mealtime`: settings, onboardingSeen, progress(동일 책임의 Meal 모델).
- `shared`: profile(이름/선택 차량/차량별 사진·transform), onboarding, entitlement.
- `session`: active=null 또는 {mode,sessionId,phase,config,startedAt,pausedAt,totalPausedDuration,motivationState,alarmAcknowledged,pendingResult}. session phase는 running/paused/arrived/awaitingConfirmation/awaitingStickerChoice/committing.

DB `user_version=1`와 payload의 현재 형식 validator만 둔다. 범용 schema registry, migration metadata/table, operations table, 별도 deleted ID 배열은 만들지 않는다. goal 신규 생성 ID는 command 전에 생성해 retry에도 같게 쓰고, 사용/취소는 goalId와 현재 상태 조건으로 멱등 처리한다. 이후 **통합 앱 버전 간** schema 변경이 생기면 실제 변경에 필요한 `onUpgrade` transaction과 fixture를 그때 추가한다. 현재는 과거 테스트 앱을 위한 decoder/fixture를 만들지 않는다.

각 ProgressService는 constructor에서 고정된 Daily 또는 Meal 저장 facade를 받는다. facade는 자기 row와 자기 mode outcome만 읽고 쓰며 UI에 임의 scope 쓰기 API를 노출하지 않는다. SQL connection은 저장 파일 내부에만 둔다. 두 mode를 섞는 함수는 없다. cross-mode cancel/start만 coordinator 전용 transaction이다. snapshot은 항상 transaction 내부에서 최신 상태를 읽어 변경한 뒤 저장한다; shared profile 수정과 IAP 갱신이 같은 shared row를 사용하므로 외부의 오래된 전체 snapshot으로 덮어쓰기 금지.

최소 명시 계약(예시, 구현 아님):
```dart
// 기존 service API는 유지하고 내부 persistence만 주입한다.
Future<RecordedActivitySession> commitDailyCompletion(SessionKey key, ActivitySessionResult result);
Future<RecordedMealSession> commitMealCompletion(SessionKey key, MealSessionResult result);
Future<void> saveProfile(SharedProfile profile, int expectedRevision);
Future<void> cacheEntitlement(PurchaseEntitlement entitlement);
Future<void> replaceActive(SessionKey oldKey, SessionDraft next);
```

sqlite transaction callback에서는 transaction handle만 쓰고 미디어·UI·network await를 하지 않는다. 16ms tick마다 저장하지 않는다. SQL bound parameter와 revision 검사를 사용한다. native rollback journal 기본 모드 및 `synchronous=FULL`을 최소 기준으로 검증하고 OFF/MEMORY로 낮추지 않는다. 전용 WAL 튜닝·수제 WAL·이중 snapshot 파일은 필요하지 않다. SQLite 자체 journal은 제거 대상인 **앱의 과거 데이터 이관 journal**과 다르다.

## 4. 현재 통합 앱의 완료·삭제·복구

### 완료

1. start 성공을 표시하기 전에 random sessionId, mode, 고정 config, start 시각을 session row에 commit. ID는 timestamp fallback 없이 secure random 기반으로 만들고 중복을 거절한다.
2. pause/resume/완료 의도는 sessionId+mode+revision을 검사하여 commit 후 UI 확정. 화면 전환은 owner 변경이나 취소가 아니다.
3. Daily 스티커 선택 전은 awaitingStickerChoice, Meal 확인 전은 awaitingConfirmation. **확인 후 Meal pendingCompletion**은 확정 result이며 자동으로 같은 의도의 저장 재시도가 가능하다. 재확인으로 시각/보상을 바꾸지 않는다.
4. `commitDailyCompletion` 또는 `commitMealCompletion` transaction에서 outcome을 먼저 조회한다. completed면 기존 결과 반환, deleted/canceled면 재지급 거절. 없으면 현재 active와 ID/revision 일치를 확인한다.
5. 기존 보상 계산으로 해당 mode history/inventory/goals를 갱신하고 completed outcome(result/config, acknowledged_at=NULL), session.active=null을 **같은 transaction**에 쓴다. 다른 mode row를 읽거나 변경하지 않는다.
6. commit 성공 후 결과 UI/애니메이션. kill 후에도 outcome으로 결과를 열고, 홈/닫기에서 acknowledged_at을 별도 idempotent transaction으로 설정한다. initState만으로 확인 처리 금지. outcome을 읽을 때 보상을 다시 계산하지 않는다.

completion commit 전 crash면 마지막 active/pending에서 복구, 후 crash면 outcome에서 복구한다. commit 응답 유실로 실패처럼 보이는 경우 DB를 재조회해 operation 완료 여부를 먼저 확인하고 동일 ID로 retry한다. 메모리 부울만으로 완료 여부를 판정하지 않는다.

### 보상 정책·삭제

T `local_activity_progress_service.dart:623`: activityCompleted 및 explicit receiveSticker/기본 policy. Y 동일 역할 `:560`: mealCompleted이면 차량 sticker1. 활성 목표 각각에 slot이 채워지는 기존 철학 유지; 하나의 소비형 wallet로 바꾸지 않는다. 목표2개·1~20칸 유지.

기록만 삭제 / 연결 보상도 삭제의 기존 선택을 유지한다. 삭제 transaction은 history 제거, 필요 시 inventory와 active/earned slot 조정, outcome.status=deleted를 함께 commit한다. 이미 used인 목표는 기존 의미대로 보존한다. earned에서 active로 복귀해 2개를 초과하더라도 복귀 목표를 버리지 않고 신규 생성만 상한으로 막는다. deleted outcome은 result/config를 NULL로 지워 개인정보·이미지 참조를 해제하되 ID tombstone은 유지한다. 늦은 완료·반복 삭제는 부활/이중 차감하지 않는다. 삭제가 먼저 확정되면 result 배너도 사라진다.

goal 사용은 earned→used를 한 transaction에 넣고 goalId 조건으로 재시도한다. create/update/cancel도 명시 ID와 현재 상태를 검증한다. 별도 일반 transaction ledger가 필요하지 않다. 통계 및 수집 스티커 종류 수는 오직 mode별 snapshot에서 계산한다.

### 단일 active owner

`ActiveSessionCoordinator`는 notifier+command queue+현재 controller handle 하나로 충분하다. 기존 ActivityTimerController와 MealTimerController 계산은 유지하며 switch(mode)로 두 adapter를 선택한다. plugin registry나 범용 timer engine은 만들지 않는다. 복구 입력은 새 session row 하나이며 과거 여러 session 병합/복구 queue는 없다. completed 미확인 outcome 목록은 active timer가 아니며 새 timer와 공존 가능하다.

cancel+start는 old canceled outcome과 새 active row를 한 transaction으로 교체한다. 실패면 old active 유지; commit 응답 불명확이면 재조회. stale clear/pause/complete는 ID/revision 불일치로 거절한다. home의 24시간 자동 clear를 제거하고 오래된 새 통합 세션도 사용자 명시 확인/취소까지 보존한다. DB 열기/validation 실패 시 timer 시작·보상 쓰기를 차단하고 오류를 표시한다. 정상적인 빈 신규 설치와 손상된 저장소를 혼동하지 않는다.

## 5. 초기화·사진·미래 update

통합 전 앱의 데이터는 읽지 않는다. 새 고정 namespace/DB 파일과 `Documents/unified_avatar_images/`를 사용하여 이전 키/사진을 자동 재사용하지 않는다. 기본값은 DB 첫 생성에서만 쓰며 정상적인 빈 목록에도 seed를 반복 삽입하지 않는다. 개발용 reset은 별도 명시 도구로만 허용하고 release startup에는 clear/delete 분기가 없어야 한다. 버전 bump·cold launch·restore purchase가 reset을 호출해서는 안 된다.

통합 앱 사진은 durable Documents에 flush 완료한 새 파일을 만들고 검증한 뒤 shared profile을 DB commit한다. DB 쓰기 실패면 기존 profile 유지; 새 미참조 파일 정리는 후순위다. systemTemp fallback은 제거한다. 파일과 DB는 같은 transaction이 아니므로 **새 파일 먼저, 참조 commit 나중**, 이전 파일 삭제는 모든 profile/active/outcome 참조 해제 후에만 한다. 경로는 상대 경로로 저장하여 sandbox base 변경에 대응한다. 읽기 실패 시 기본 라이더로 표시하고 데이터 손상 안내; 자동으로 새 empty DB를 만들지 않는다. 물리 저장장치 고장·사용자 uninstall까지 무손실이라고 주장하지 않는다.

통합 앱 v1→후속 버전의 저장 보존은 필수다. 미래 schema transaction 중 실패는 native rollback하고 재시도한다. unknown newer schema를 열었다고 파일을 지우지 않는다. 사전 출시 앱 downgrade 지원은 범위 밖이며 이를 위한 이중 쓰기/호환 계층도 없다. 통합 앱 출시 후 문제는 현재 schema를 지원하는 수정판으로 해결하며 reset으로 우회하지 않는다.

## 6. 공유 IAP — 구조 유지, 로컬 cache만 새로 시작

VERIFIED T `lib/catalogs/vehicle_unlock_catalog.dart:7`: Android `vehicle_pack`, iOS `com.timeyrider.vehicle_pack`, 무료 `motorcycle`/`supercar`. StoreKit 설정 `ios/Runner/StoreKitConfiguration.storekit:48`도 T iOS ID. Y `lib/constants/iap_product_ids.dart:2`는 별도 앱의 `vehicle_pack`. 문자열 동일을 bundle 간 구매 호환 근거로 쓰지 않는다.

| 기존 근거 | 통합 변경 |
|---|---|
| T controller `lib/services/vehicle_pack_purchase_controller.dart:77` 생성 시 구독; Y `controllers/vehicle_pack_purchase_controller.dart:119` startListening | T root owner/stream 하나, Y controller/client 복사 금지 |
| T `:367` save→completePurchase→state, catch에서도 unlocked state 설정 | durable cache 저장 실패와 store ack 실패를 분리; 저장 실패를 영구 unlock 성공으로 표시 금지 |
| T `:121` recover/30초 retry, `iap_purchase_client.dart:123` Android queryPastPurchases, iOS empty | startup/resume recovery 유지, iOS 명시 restore 버튼 항상 제공 |
| Y controller `:217` request guard, `:263` restore batch wait | T에 구매/restore single-flight와 지연 이벤트 처리 추가; 이미 구매/pending 중 재구매 차단 |
| T restore `:292` Future 뒤 queue 확인 | Future 반환만으로 restore event 종료 판단 금지; 늦은 성공 수용, timeout은 재확인 가능 상태 |
| T client `:204,252` Android BillingResponse 검사/native pending 우선 | pending을 restored로 바꿔 해제 금지, ack 실패는 retry |

순서: 보호자 gate→상품 조회→buy→pending→유효 purchased/restored→shared.entitlement DB commit→양 mode 갱신→필요 completePurchase. entitlement 캐시 중복 저장은 멱등하지만 dedup 때문에 필요한 native ack를 건너뛰지 않는다. 저장 실패면 재시도, ack 실패면 저장된 권한 유지하고 recover한다. cache는 server 검증 시스템이 아니며 실시간 revocation/위변조 방지를 구현했다고 주장하지 않는다.

사전 출시 local test cache는 폐기 가능하다. **실제 Timey store entitlement는 삭제되지 않으며 새 cache가 비어도 복원 가능해야 한다.** 초기 offline이면 무료 차량+복원 안내, 한번 복원해 저장한 통합 cache는 이후 offline에 유지한다. 빈 restore/네트워크 오류가 기존 unlocked cache를 박탈하면 안 된다. Y 별도 bundle 구매를 자동 이전하지 않는다.

native 구매창 중 mode 변경은 UI상 차단, 창 반환 후 장기 pending은 mode 이동 허용·새 구매 금지. 모든 route가 같은 state를 보고 구매는 스티커/목표 row를 수정하지 않는다. purchase overlay의 inactive/resumed는 새 launch나 timer cancel이 아니다. 플랫폼 실제 restore·계정 변경·ack 재시도는 P7 실기기 게이트다.

## 7. 허용되지 않는 실패와 검증

| 경계 | 요구 |
|---|---|
| 저장 성공 뒤 즉시 kill | 새 보상·설정·프리셋·세션이 재시작 후 유지 |
| completion/삭제/goal 사용 중 kill | transaction 전체 전/후 중 하나, 부분 wallet0 |
| 완료 commit 뒤 UI 전 kill | result/config 복구, 스티커 중복0 |
| 완료 callback100회/삭제 경합 | 같은 mode session outcome1개, 삭제 부활0 |
| profile와 IAP 동시 쓰기 | 두 shared 필드 모두 보존, lost update0 |
| 새 DB 열기 실패·잘린 unified JSON | 오류, 자동 reset0, 새 timer 차단 |
| 정상 설치 반복 실행/미래 update | 기본값 재삽입0, 기존 unified 데이터 유지 |

이 기준은 SQLite라는 이름만으로 통과하지 않는다. mock unit 검증과 실제 iOS/Android kill/relaunch 검증이 모두 필요하다. 확률이나 성능 개선 수치는 현재 미측정이다.


동시성 token은 `app_state.revision` 하나를 사용한다. active payload 안에 별도 revision을 중복 저장하지 않는다. coordinator가 읽은 revision을 명령의 expectedRevision으로 넘기고 조건부 update가 실패하면 최신 row를 다시 읽는다. SessionKey의 안정된 정체성은 `(mode,sessionId)`이며 revision은 상태 변경 검사용 별도 값이다. 완료 transaction에서 outcome 중복 검사는 active revision 검사보다 먼저 수행하여 성공 후 재시도를 정상 처리한다.
