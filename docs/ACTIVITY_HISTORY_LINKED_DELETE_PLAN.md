# Timey Rider 활동 기록 선택적 연동 삭제 구현 계획

작성일: 2026-10-17. 검토 갱신: 2026-10-18. 상태: 구현·자동 검증 완료, 실기기·출시 게이트 대기. 기준 소스: `8b1cf455e73681fd3a67a0c6088ab848abc5adf4`.
요구사항 출처: `../jy_yamyam/docs/MEAL_HISTORY_LINKED_DELETE_PLAN.md`의 목적·사용자 정책·완료 조건.
Yamyam의 구현 알고리즘, 완료 호출부, 테스트 통과 이력은 이식 근거로 사용하지 않는다. 아래 설계는 Timey 소스를 조사하여 작성했다.
이 문서의 최초 작성 범위는 계획 문서와 agy 계획 리뷰였다. 후속 구현·검증 결과는 아래 10절을 참고한다.

## 1. 목적과 고정 요구사항

1. 활동 기록 삭제 확인창에서 `기록만 삭제`와 `이 활동으로 받은 스티커도 함께 삭제`를 선택한다. 기본은 기록만 삭제이며 이전 선택을 저장하지 않는다.
2. 함께 삭제하면 해당 기록에 실제 지급된 스티커만 보관함에서 차감하고, 미사용 보상판의 해당 활동 칸만 제거한다. 현재 활동 설정이나 완료 상태로 과거 지급량을 다시 계산하지 않는다.
3. 미사용 달성 보상이 목표 미달이 되면 진행 중으로 돌아간다. 이미 사용한 보상은 상태·칸·날짜·원시 저장값을 보존한다. 보관함은 누적 수집량이므로 사용한 보상 보존과 별개로 차감한다.
4. 기록만 삭제한 뒤에는 해당 기록으로 연동 삭제할 수 없다. 과거 삭제 기록을 추정하여 정리하지 않는다.
5. 취소와 확인창 닫기는 무변경. 중복 삭제·재시도·앱 재시작·늦은 결과 저장으로 중복 차감하거나 재지급하지 않는다.
6. 달성 취소로 진행 중 보상판이 3개 이상 되어도 보존한다. 새 보상 생성은 진행 중 2개 미만일 때만 허용한다. 다음 스티커 지급 활동은 모든 진행 중 보상판을 기존 규칙대로 채운다.
7. Timey의 활동 유형, `receiveSticker` 선택, 완료 상태, 코스 마커, 초과시간, 차량팩 구매·복원 정책을 유지한다.

## 2. Timey 소스에서 확인한 전제

| 위치 | 현재 동작 | 설계에 미치는 영향 |
|---|---|---|
| `lib/services/local_activity_progress_service.dart` | 삭제는 history만 저장하며 setStringList 성공 bool을 확인하지 않음 | 두 삭제 방식 모두 실패 복구가 필요 |
| 같은 서비스 | `_recordOperation`은 완료 저장만 직렬화. `_preferences()`는 기존 완료 작업을 기다리지만 자신의 읽기/쓰기 전체를 큐에 등록하지 않음 | 삭제·보상 사용·완료 저장의 교차 실행을 막는 공통 진행 데이터 큐 필요 |
| 같은 서비스 | `activityRecordTransaction`은 키→StringList 스냅샷. 완료 시 history/inventory, 보상 변경 시 active/earned를 추가 | 부분 키 트랜잭션과 기존 저널 복구를 유지하면서 확장 |
| 같은 서비스 | 복구가 legacy history/inventory를 무조건 제거하고, active 쓰기가 있으면 legacy earned까지 제거 | 기록만 삭제용 부분 트랜잭션에 그대로 재사용하면 보상 데이터가 사라질 수 있음 |
| 같은 서비스 | active 로더의 `take(2)`; earned/used 별도 목록; legacy 단일 active가 earned로 해석될 수도 있음 | 초과 보존 및 키별·상태별 마이그레이션 검증 필요 |
| `lib/models/reward_goal.dart` | 슬롯 ID는 activitySessionId, mealSessionId 읽기 호환. 파서는 잘못된 슬롯을 건너뛰고 목표 수량만큼 자름 | 파싱 성공/목록 길이만으로 원본 보존을 증명할 수 없음 |
| `lib/screens/timer_screen.dart` | 완료 시 pending 결과 저장 후 ResultScreen으로 이동. 직접 progress 기록을 저장하지 않음 | Yamyam의 타이머 record 예외 경로를 복사하지 않음 |
| `lib/screens/result_screen.dart` | null인 스티커 선택을 받은 뒤 `_persistResult`: pending 선택 갱신 → progress 기록 → 같은 ID pending 제거. 저장 완료 전 영상 시작 | 삭제 상태 확인과 저장/정리 단계 구분, 영상 시작 시점 보강 필요 |
| `lib/services/active_activity_timer_session_store.dart` | 별도 직렬 큐. clearPendingResult는 session ID 비교. savePendingResult는 pending 덮어쓰기 후 active 제거 | 이전 결과의 read→save 사이에 새 pending/active를 덮어쓰는 경합 방지 필요 |
| `lib/screens/home_screen.dart` | pending을 ResultScreen으로 복구. didPopNext에서 진행 요약 재조회 | 홈에서 임의로 스티커를 결정하거나 새 저장 경로를 만들지 않음 |
| `test/support/*` | Timey 전용 결과·pending fixture와 화면 harness 존재 | 기존 도우미를 확장하며 Yamyam 테스트 파일을 그대로 복사하지 않음 |

현재 저장소에서 SCREENSHOT_MODE 구현은 확인되지 않았다. 존재하지 않는 모드 대응은 구현 범위에 넣지 않는다. 적용 직전 기준 HEAD와 작업 중 변경을 다시 확인한다.

## 3. 저장 계층 설계와 데이터 보존

### 3.1 공통 직렬 실행

- `LocalActivityProgressService` 내 읽기·복구·변경 작업 전체를 하나의 큐에 등록한다. 완료/삭제/연결 보상 조회/스냅샷/보상 생성·수정·취소·사용·clear가 같은 경계를 사용한다.
- public 메서드끼리 큐 안에서 재호출하지 않는다. 내부 helper에는 이미 얻은 SharedPreferences를 전달하여 자기 대기와 deadlock을 막는다. 실패해도 finally에서 다음 작업을 해제한다.
- active/pending 저장소의 큐와는 중첩하여 잠금을 잡지 않는다. 두 저장소를 하나의 원자적 쓰기처럼 취급하지 않고 progress 반영 후 동일 세션 pending 정리를 재시도하는 방식으로 맞춘다.
- 큐는 현재 단일 isolate 앱의 범위이다. isolate 간 잠금·새 DB·새 의존성은 추가하지 않는다.

### 3.2 기존 트랜잭션의 안전한 확장

- `activityRecordTransaction`과 기존 키→StringList 형태를 유지한다. 선택적인 `deletedActivitySessionIds` 키에 활동 내용 없이 세션 ID만 저장한다. 다른 앱의 meal 키를 새 저장 대상으로 쓰지 않는다.
- 먼저 기존 트랜잭션을 완전히 복구한 뒤 새 계산을 한다. 전체 키 이름·값 타입·삭제 ID 형식을 첫 쓰기 전에 검증한다. 지원 키는 activity history/inventory/active/earned/used 및 삭제 ID로 제한한다. 알 수 없는 키나 손상된 구조는 원본 저널을 보존하고 중단한다.
- 삭제 ID 필드가 없는 과거 저널도 복구하며, 기존 삭제 ID 목록을 덮어쓰거나 제거하지 않는다. 새 저널은 삭제 ID를 먼저 적용하고 나머지 스냅샷, 필요한 레거시 정리, 저널 제거 순서로 처리한다.
- 모든 set/remove의 false와 예외를 실패로 취급한다. 저널 저장 전 실패는 원본 무변경. 저널 저장 후 실패는 결과 미확정이며 다음 접근에서 같은 최종값을 재적용한다. 복구 중 차감 연산을 다시 수행하지 않는다.
- 기록만 삭제 트랜잭션에는 history와 삭제 ID만 넣는다. inventory/active/earned/used 및 레거시 보상 키를 읽어 재직렬화하거나 삭제하지 않는다.
- 레거시 제거는 새 키로 안전하게 옮긴 데이터에만 수행한다. history 쓰기는 legacy history만, inventory 쓰기는 legacy inventory만 정리한다. active/earned의 공유 단일 legacy 키는 두 상태가 새 목록에 보존된 경우에만 제거한다. 새 빈 목록이 있으면 legacy보다 우선한다는 기존 읽기 규칙을 유지한다.
- 레거시 보상 해석은 상태 기반이다. 각 신규 active/earned 목록이 있으면 그것을 우선하고, 없을 때 해당 legacy 목록, 그것도 없을 때 단일 activeRewardGoal을 사용한다. 단일 항목의 active는 active로, earned/ready는 earned로 매핑한다. 슬롯 수만으로 상태를 추정하지 않는다. used/redeemed/archived 또는 알 수 없는 상태의 단일 키는 연동 삭제에서 임의 이관·제거하지 않고 데이터 오류로 중단한다. 단일 키에 의존한 active/earned를 변경할 때는 각 목록의 기존 우선순위를 적용한 두 최종 목록을 같은 저널에 기록한 뒤 단일 키를 제거한다. 기록만 삭제로 새 history와 legacy earned가 공존한 뒤의 연동 삭제도 이 규칙을 따른다.
- 같은 레거시 정리 규칙을 기존 저널 복구에도 적용한다. history/inventory만 든 구형 완료 저널은 레거시 보상 키를 제거하지 않는다. active만 든 합성/부분 저널도 earned가 안전하게 표현되지 않았으면 단일 legacy active와 legacy earned를 남긴다. payload에 없는 데이터를 정리했다는 이유만으로 복구 완료로 처리하지 않는다.
- 명시적 보상 사용의 used 이관은 현재의 우선순위(activityUsedRewardGoals → usedRewardGoals → redeemedRewardGoals)를 유지한다. 새 키가 비어 있어도 우선하며 목록들을 합집합으로 합치지 않는다. 선택된 원본 전체를 새 항목과 함께 저장하고, 새 키가 안전하게 기록된 후 선택되어 이관한 레거시 원본만 제거한다. 가려진 하위 우선순위 키는 임의 삭제하지 않는다. redeemed fallback은 기존 로더와 동일하게 used 상태·usedAt/redeemedAt 의미만 변환하고 다른 필드는 보존한다. 손상된 used 원본을 건너뛰어 재저장하지 않고 보상 사용 전체를 중단한다. 연동 삭제는 이러한 used 이관 자체를 실행하지 않는다.
- 기존 완료 저널에는 history/inventory가 항상 포함되고, active가 포함될 때 earned도 포함되는 형태를 그대로 지원한다. 신규 부분 저널에는 그 전제를 강요하지 않는다. used/legacy used/redeemed는 삭제 트랜잭션의 쓰기·제거 대상이 아니다.
- 보상 사용(earned→used)과 목표 수정(active→earned)의 다중 키 쓰기도 같은 트랜잭션 helper로 보호한다. 사용 이력이 절반만 저장된 상태에서 삭제가 재개되는 위험을 차단하기 위한 범위이다. used 쓰기는 명시적인 보상 사용 작업에서만 허용한다. 생성·취소·clear의 레거시 정리도 위 원본 보존 규칙을 따른다. 각 작업의 기존 사용자 규칙은 바꾸지 않는다.

### 3.3 읽기와 변경 검증 분리

- 기존 조회에서 잘못된 항목을 건너뛰는 동작은 유지한다. 다만 삭제 계산에는 원시 저장값을 사용하고, 조회 모델을 전체 데이터로 간주해 덮어쓰지 않는다.
- history는 원시 문자열 목록에서 대상 ID를 찾아 그 항목만 제거한다. 다른 정상·손상 항목과 알 수 없는 필드는 그대로 보존한다. 대상 ID가 중복되면 두 삭제 방식 모두 중단한다. 단일 대상임을 확정할 수 없는 손상 항목은 무시하고 삭제하지 말고 데이터 오류로 중단한다.
- 연동 삭제는 대상 rewardIds의 모든 원소, inventory의 ID/수량, active/earned 보상과 내부 슬롯을 손실 없이 검증한다. `whereType`, 슬롯 건너뛰기, `take(requiredStickerCount)`, unknown status→active 변환으로 손상 데이터를 정상화한 뒤 저장하지 않는다.
- active/earned의 중복 goal ID, inventory 중복 reward ID, 잘못된 슬롯·상태·필수 타입은 연동 삭제를 저널 저장 전에 중단한다. 알 수 없지만 유효한 reward ID는 현재 카탈로그에 없어도 문자열 ID로 처리한다.
- 새 삭제 경로는 원시 JSON을 최소 수정한다. inventory는 해당 count만, 보상판은 연결 슬롯·필요한 status/날짜만 바꾸며 나머지 필드와 무관한 항목은 보존한다. 유효한 초과 슬롯은 절대로 잘라 저장하지 않는다. 기존 목표 수량을 낮춰 생긴 초과 슬롯 fixture를 포함한다.
- 후속 완료/보상 편집에서도 초과 슬롯이 다시 사라지지 않도록 active/earned 변경용 lossless decoder를 서비스 내부에 둔다. 화면 표시용 기존 모델의 손상 복구 정책을 전역 변경하지 않는다. 이 decoder는 정상 슬롯 전체를 보존하고 잘못된 슬롯은 작업 중단으로 처리한다. 무손실 디코더/인코더는 완료·생성·편집·취소·사용·clear 및 이관 등 active/earned 목록을 다시 저장하는 모든 경로에 적용한다. 보상 사용은 이동할 earned의 전체 슬롯을 used에 보존하고 기존 신규 used 목록 항목의 원시 문자열은 유지한다. 레거시 used 이관의 제한적 변환은 3.2를 따른다. 전체 active 개수 제한은 읽기·쓰기 모두 제거한다.
- 모든 보상 변경은 goalId와 편집한 이름/목표값만 입력받고 큐 내부에서 저장소 원본을 다시 읽는다. UI의 RewardGoal/슬롯 목록을 저장 스냅샷으로 받지 않는다. 현재 Timey 호출부도 이 방식이므로 API 계약을 유지한다. 공개 loadSnapshot/loadActiveRewardGoals의 active 로더에서 take(2)를 제거하여 초과 보상판 자체가 모두 조회되게 한다. UI 표시 모델의 슬롯 절삭 여부는 저장 계산에 영향을 주지 않아야 하며 목표/진행 수 표시가 실제 지급·차감 상태와 모순되지 않는지 확인한다.
- 기록만 삭제는 보상 데이터 충돌이나 손상 때문에 막지 않는다. 보상 원시 키를 그대로 둔다. 조회 오류·변경 오류·복구 미완료를 사용자에게 구분하여 안내한다.

### 3.4 삭제 계산과 완료 재지급 차단

API 초안: `deleteActivityHistoryEntry(String entryId, {bool deleteLinkedRewards = false})`.
기존 bool은 실제 대상 삭제 여부, 저장 실패·데이터 오류는 별도 예외로 구분한다.

1. 큐 진입 → 기존 저널 복구 → 원본 읽기 → 대상 확인. 대상 없음은 false이며 차감하지 않는다.
2. 두 삭제 방식 모두 대상 ID를 deletedActivitySessionIds에 추가한다. ID 계산은 `result.sessionId ?? result.endedAt.microsecondsSinceEpoch.toString()`와 동일하게 한다.
3. 연동 삭제는 기록의 rewardIds 빈도만큼 inventory 차감. 없는 항목은 건너뛰고 0 이하이면 제거한다. 남은 기록으로 총량을 재계산하지 않는다.
4. active/earned의 activitySessionId(레거시 mealSessionId 호환)가 일치하는 칸만 제거한다. 목표 미달인 earned만 active로 돌리고 earnedAt/readyAt을 명시적으로 null로 바꾼다. 목표 이상이면 earned 유지. 남은 전체 유효 슬롯 수를 기준으로 비교하며 별도의 유효/초과 슬롯 순위를 만들지 않는다. 예를 들어 목표 5·슬롯 6에서 1칸 삭제하면 5칸 earned 유지, 다시 1칸 삭제하면 4칸 active 복귀이다. 기존 active 순서 뒤에 기존 earned 순서대로 복귀시킨다.
5. 상태·칸·목표·이름·생성일 보존 조건을 검증하고 최종 스냅샷을 저널에 저장한 뒤 복구 helper로 반영한다.
6. `recordActivityResult`는 복구 직후 삭제 ID를 확인하여 삭제된 ID면 `DeletedActivitySessionException`으로 중단한다. 기록 재생성·스티커 지급·보상판 증가가 모두 없어야 한다.
7. 삭제 ID는 임의 개수/기간으로 제거하지 않는다. 키 없음만 빈 집합, 정상 중복은 집합 처리. 잘못된 타입·빈 ID는 `ActivityProgressDataException`으로 변경을 중단하며 자동 초기화하지 않는다. 정상 저널이 있으면 먼저 복구하여 정상 삭제 ID로 교체할 수 있다.
8. 삭제 ID 손상만 있는 경우 정상 스냅샷 조회는 계속 가능하게 한다. 저널 자체가 손상되어 복구할 수 없으면 진행 상태를 확정할 수 없으므로 조회 오류로 표시하고 변경을 막는다. 구버전 앱으로 다운그레이드한 뒤의 재지급까지 보장하지 않는다.

## 4. Timey 결과 선택·pending 복구 흐름

### 4.1 ResultScreen 상태와 비동기 경합

- 결과 진입 시 짧은 사전 확인 상태를 두어 삭제 ID 여부를 확인한다. 삭제된 활동은 스티커 선택 화면과 축하 영상으로 진입하지 않고, 같은 ID pending과 같은 ID 잔여 active만 정리한 뒤 삭제 안내와 홈 이동을 제공한다. 복구 판정 순서는 저널 복구 → 삭제 ID 확인 → 기존 기록 중복 판정 → 필요 시 선택/저장으로 고정한다. 이전 기록 성공 이력이나 화면 내 캐시보다 삭제 ID가 우선한다. 삭제 상태 UX는 자동 성공 화면/재생 대신 동일한 삭제 안내와 홈 버튼으로 통일한다.
- 정상 활동은 기존 `receiveSticker == null` 선택 조건과 완료 상태 규칙을 그대로 사용한다. 특히 timeEnded의 선택 가능 여부, true/false/null 조합, needsMoreTime/canceled 처리를 기존 테스트와 비교한다.
- 사전 확인 뒤 삭제가 일어날 수 있으므로 최종 recordActivityResult의 삭제 ID 검사가 권위 있는 판정이다. 사전 확인만 믿고 지급하지 않는다.
- 진행 상태를 확인 중 / 선택 대기 / 기록 저장 중 / pending 정리 중 / 저장 완료 / 일반 저장 오류 / 데이터 오류 / 삭제 완료로 구분한다. 별도 프레임워크나 controller 도입 없이 기존 State의 최소 필드와 helper로 구현한다.
- 스티커 수령 선택을 pending에 먼저 반영한 뒤 기록을 저장한다. 저장과 필요한 pending 정리가 끝난 뒤에만 보상 영상·효과음·스티커 비행을 시작한다. false 선택은 저장된 뒤 중립 결과로 이동한다. 실패 화면에서 재시도 중 기존 성공 UI가 노출되지 않게 한다.
- 저장 성공 후 pending 정리만 실패한 경우 메모리에 기록 성공 결과를 유지하고 정리만 재시도한다. 앱 재시작 후에는 위 우선순위에 따라 삭제를 먼저 판정한 다음 기존 기록 ID로 중복 지급을 막는다. 정리만 재시도하는 경로도 성공 화면/미디어를 열기 전에 삭제 여부를 다시 읽어 삭제되었다면 삭제 안내로 끝낸다. 이 확인은 기록 저장을 다시 호출하지 않는다.
- 삭제 전용 예외를 일반 저장 재시도 버튼에 연결하지 않는다. 정리 실패에는 정리 재시도와 홈 이동을 제공하며, 같은 pending이 남아도 다음 홈 복구가 같은 삭제 상태로 안전하게 처리한다.
- 오류·성공 콜백은 mounted 및 작업 세대/ID를 검사한다. dispose 후 애니메이션 초기화, 중복 선택·재시도, 오래된 callback의 라우트 이동을 차단한다. 재시도마다 intro controller/audio가 중복 생성되지 않는지 검증한다.

### 4.2 세션 저장소 경계

- 기존 `clearPendingResult(sessionId)`의 ID 일치 조건을 유지한다. 삭제 결과 정리에 무조건 `clear()`를 호출하지 않는다. 새 active/pending B를 이전 결과 A의 정리 콜백이 지워서는 안 된다.
- ResultScreen의 현재 loadPendingResult→savePendingResult 조합을 저장소 큐 내부의 조건부 갱신(예: `updatePendingResultIfSessionMatches`)으로 대체한다. 현재 pending ID가 A일 때만 선택값을 갱신하며 active 키에는 쓰지 않는다. 없거나 B이면 그 pending을 만들거나 덮어쓰지 않는다. 갱신 거절 시 현재 화면의 오래된 요청 여부를 판단하고 새 세션에는 손대지 않는다.
- 타이머의 최초 savePendingResult는 기존 완료 경계로 남긴다. pending 저장 후 active 제거 실패는 사용자에게 완료 실패로 숨기지 말고 재시도 가능하게 유지한다. 삭제 정리 후 같은 ID의 잔여 active가 복원되지 않는지 테스트하고, 필요하면 저장소 큐 안에서 ID가 일치하는 잔여 active/legacy active만 정리하는 helper를 추가한다.
- 홈은 삭제 상태 사전 확인을 수행하는 ResultScreen에 복구를 위임한다. 새 타이머 시작 전에 pending 처리가 끝나야 한다는 기존 흐름을 유지한다. 홈·타이머에 별도 progress 기록 호출을 새로 만들지 않는다.
- null sessionId인 직접 결과는 기존 endedAt 기반 ID로 삭제를 판정하되, 일치하는 pending ID를 증명할 수 없으면 pending/active를 제거하지 않는다. 현재 PendingActivityResult.fromJson은 유효한 ActiveActivityTimerSession의 필수 sessionId를 result.sessionId에 채우므로 정상 저장된 pending은 null ID가 아니다. 직접 결과의 종료 시각을 다른 pending 식별자로 추정하지 않는다. 저장소 테스트로 유효 pending의 ID 유지 및 ID 누락/공백 시 파싱 실패 계약을 고정한다.

## 5. 화면·안내·오류 처리

- ActivityHistoryScreen: 확인창 준비부터 완료까지 중복 진입 차단. 서비스의 연결 보상 조회 helper는 같은 큐/복구/레거시 해석을 사용한다. rewardIds가 비어도 연결된 미사용 칸이 있으면 옵션 표시, 둘 다 없으면 숨김. used 칸만으로 옵션을 표시하지 않는다.
- 옵션 준비 실패는 삭제 금지. 실제 삭제는 확인창의 오래된 snapshot 대신 큐 안 최신 데이터로 다시 계산한다. 선택 상태에 따라 ‘기록만 삭제’와 ‘함께 차감’ 설명이 모순되지 않게 바뀐다.
- 저장 실패는 ‘저장을 완료하지 못했어요’처럼 결과 미확정 안내. 재시도는 먼저 복구·재조회하며, 사라진 기록에 다시 차감하지 않는다. 성공이나 대상 없음은 목록을 새로 읽는다.
- 진행 스냅샷을 읽는 Home/ActivityHistory/RewardGoal/StickerCollection 화면에 복구 오류 상태와 재조회 동작을 둔다. 오류를 빈 보관함·0개 보상 또는 무한 로딩으로 표시하지 않는다. RewardGoal 변경 콜백도 새 저장/데이터 예외를 catch하고 입력·재시도 상태를 복원한다.
- RewardGoal 화면은 모든 진행 중 보상판을 표시한다. 홈은 기존 2개 요약을 유지하고 ‘외 N개’ 표시. 생성 제한은 화면·서비스 모두 전체 개수로 검사하며 기존 첫 보상판 요약 기준을 유지한다.
- `text_sets.dart`, 5개 언어 activity_history/rewards/user_guide에 동일 정책을 자연스럽게 반영한다. 도움말에도 ‘활동 완료’가 아닌 ‘스티커를 받은 활동’이 보상판을 채운다는 점을 유지한다.
- 삭제·오류 확인창은 스크롤 가능하게 하고 작은 세로/가로 화면·큰 글씨·VoiceOver 읽기 순서와 버튼 접근을 확인한다.

## 6. 구현 단위와 범위 통제

| 단계 | 변경 | 해당 단계의 종료 조건 |
|---|---|---|
| 1 | 기존 저장·선택·복구 fixture 및 실패 주입 도우미 확인, 신규 서비스 회귀 작성 | 현재 기록만 삭제/스티커 선택 계약을 테스트로 고정 |
| 2 | progress 공통 큐, 트랜잭션 검증·키별 legacy 정리, 관련 보상 변경의 원자적 저장 | 기존 완료 저널·보상 사용·목표 편집·실패 복구 통과 |
| 3 | 원시 보존 삭제, lossless 변경용 보상 로더, 삭제 ID·초과 보상 보존 | 차감·재지급 방지·손상/레거시/동시성 테스트 통과 |
| 4 | 조건부 pending 선택 갱신, ResultScreen 삭제 상태/기록·정리 재시도·미디어 시작 | pending/결과/타이머/홈 회귀 통과 |
| 5 | 삭제 확인창, 오류 표시, 홈 초과 요약, 5개 언어 안내 | 화면·통합·현지화 검증 통과 |
| 6 | 심사 안내·수동 결과 기록, 전체 테스트·분석, 최종 바이너리 검증 | 아래 출시 게이트 충족 |

주요 파일: `local_activity_progress_service.dart`, `active_activity_timer_session_store.dart`, `activity_history_screen.dart`, `result_screen.dart`, `home_screen.dart`, `reward_goal_screen.dart`, `sticker_collection_screen.dart`, `text_sets.dart`, 각 언어 activity_history/rewards/user_guide.
`timer_screen.dart`는 기존 pending handoff를 유지하며 저장소 오류 처리 보완이 실제로 필요한 부분만 수정한다. 공용 모델 파서를 전역적으로 엄격화하거나 전체 파일을 재작성하지 않는다.
신규 테스트는 `test/activity_history_linked_delete_test.dart`, `test/activity_history_linked_delete_screen_test.dart`로 분리하고 기존 test/support fixture를 재사용한다.

## 7. 심사 전 필수 검증과 실패 기준

### 7.1 데이터·동시성 테스트

- 두 삭제 방식 각각: 대상 없음·중복 탭·동일 ID 재시도·여러 서비스 인스턴스. 완료→삭제와 삭제→오래된 완료의 실행 순서 모두 최종 기록·수량 확인.
- true/false/null receiveSticker와 모든 ActivityCompletionStatus 조합, 동일 차량 여러 활동 중 하나만 삭제, 스티커 미수령 완료 기록, rewardIds 없는 연결 칸, unknown reward ID·중복 rewardIds·없는 inventory·마지막 수량 삭제.
- 같은 활동의 여러 active/earned 칸 차감, 다른 활동 칸 유지, 사용한 보상 및 legacy used/redeemed 문자열 목록의 전후 완전 일치.
- earned 복귀·날짜 null·목표 이상 earned 유지·목표 하향 수정 후 초과 슬롯 보존. raw active 3개 이상 및 여러 earned 동시 복귀 후 조회·수정·취소·재시작·다음 지급·신규 생성 제한.
- 새 키만/legacy만/혼합/새 빈 키와 오래된 legacy/단일 legacy active가 earned인 상태/legacy mealSessionId 및 상태 명칭. 기록만 삭제로 레거시 보상 키가 없어지지 않음. 세 used 키 공존·신규 빈 목록·redeemed만 있는 상태에서 기존 우선순위와 원본 보존을 검증하며 used 이관 중 실패를 주입한다.
- history·inventory·보상 목록·내부 슬롯 손상, 중복 ID, 잘못된 삭제 ID 타입/빈 값. 조회 허용 범위와 변경 중단 범위, 원시 데이터 무변경 확인. 알 수 없는 JSON 필드 보존.
- 완료·삭제·보상 사용·목표 수정/취소/생성을 제어 가능한 Future로 교차 실행해 stale read 덮어쓰기가 없음. 실패 작업 뒤 큐가 멈추지 않음.
- 저널 저장, 삭제 ID, 각 데이터 키, 각 legacy 제거, 저널 제거 단계에서 false와 throw 주입. 이미 적용된 쓰기 후 예외, 새 서비스/앱 재시작 복구 포함. 기록·차감·사용·이관 결과가 정확히 한 번 적용되어야 함.
- history/inventory만 든 기존 완료 저널, active-only 합성 저널과 새 부분 삭제 저널을 모두 복구. 저널의 후반 필드 손상이 첫 쓰기 전에 검출됨. 삭제 ID 없는 저널이 기존 삭제 ID를 보존함.
- 삭제 ID 1만 건 규모의 mock 무손실 검증과 실기기 로드/삭제/완료 응답시간을 구분해 기록. mock 시간만으로 디스크 성능 통과를 주장하지 않음.

### 7.2 pending·결과·UI 테스트

- 삭제 후 pending 재개: receiveSticker null/true/false 모두 선택·영상·효과음·재지급 없음. 사전 확인 이후 삭제되고 저장 직전에 도착한 경우도 차단.
- 기록 저장 성공→pending 정리 실패→삭제→재시도/앱 재시작. 일반 실패와 삭제 완료를 구분하며 정리 재시도는 progress를 재기록하지 않음.
- A 선택 갱신 또는 정리 전 대기 중 B pending/active 생성: A가 B를 덮어쓰거나 지우지 않음. disposed A의 콜백은 B 화면/오디오/방향을 바꾸지 않음.
- pending은 저장됐지만 active 제거가 실패한 상태에서 삭제 정리 후 옛 타이머가 되살아나지 않음. 불일치 ID active는 유지.
- 삭제 ID/저널 데이터 오류에서 선택·재지급 차단, 복구 불가 오류에 무한 재시도 약속 없음, 홈 이동 가능. 일반 저장 오류는 재시도 성공 가능.
- 정상 미선택 pending의 선택 복구, 스티커 받기/받지 않기, 조기·정시·초과 완료, timeEnded·needsMoreTime 결과, 결과 영상/음향/방향/다시 시작 회귀.
- 확인창 기본 해제·옵션 숨김·취소/뒤로/바깥 터치·오류·대상 없음·중복 탭. 실제 appRouteObserver로 홈 활동 수·스티커 합계·보상 수 갱신.
- 5개 언어(ko/en/ja/es/pt_BR), 작은 세로/가로 화면 및 글자 확대에서 삭제창·결과 오류·초과 보상·사용 안내가 넘치지 않고 모든 버튼 접근 가능.

### 7.3 실행 명령과 출시 게이트

우선 실행할 기존 테스트:
`local_activity_progress_service_test`, `reward_history_screen_test`, `pending_activity_result_storage_test`, `pending_activity_result_test`, `active_activity_timer_session_store_test`, `result_screen_test`, `result_screen_media_test`, `result_screen_help_layout_test`, `timer_completion_lifecycle_test`, `home_active_session_test`, `home_screen_test`, `localization_support_test`, `locale_smoke_test`.
신규 두 테스트를 더해 관련 검증을 통과시킨 뒤 `flutter analyze --no-pub`, `git diff --check`, 전체 `flutter test --no-pub`를 최종 코드에서 수행한다. 명령·소스·기기·실패/성공 수를 기록한다.

다음 중 하나라도 실패하면 새 기능을 포함한 바이너리를 심사에 넘기지 않는다:
- 원본 보상/이관 데이터 손실, 중복 지급·차감, 사용한 보상 변경, 새 세션 오삭제.
- 저장 실패 후 복구 불능·무한 로딩·새 타이머 진입 불능, 정상 결과 선택/미디어 회귀.
- 삭제 설명과 실제 동작 불일치, 작은 화면에서 삭제·취소·복구 버튼 접근 불가.

실기기는 현재 배포 데이터가 있는 상태로 업데이트하여 검사한다. 최소 흐름: 기록만 삭제 → 스티커 연동 삭제 → 마지막 스티커 → 미사용 보상 복귀/3개 이상 → 사용한 보상 유지 → 홈 복귀·강제 종료·재시작 → 새 타이머 → 받기/받지 않기.
iPhone의 작은 화면·가로 및 지원 iPad에서 확인하고 지원 OS 미검증 범위를 남긴다. 자동 실패 주입은 실기기 결과와 구분한다.
최종 제출 후보 소스에서 Release/Archive/export 및 배포 검증을 다시 수행한다. 기능 테스트 통과를 Sandbox 구매·복원이나 Organizer 검증 통과로 기재하지 않는다. IAP 기본 구매/복원·기존 권한 유지도 출시 smoke 범위에 포함한다.
이 계획 작업에서는 버전·빌드 번호·서명·IAP를 변경하지 않는다. 실제 새 업로드 준비 시 AGENTS.md와 release_process.md에 따라 성공 업로드 이력을 확인하여 번호를 결정한다.

## 8. 사용자 안내와 심사 메모

- 앱 내 사용 안내/활동 기록 도움말 5개 언어와 README에 확정 동작을 반영한다. `receiveSticker=false`인 완료 기록에는 지급 스티커가 없다는 Timey 규칙을 포함한다.
- `docs/iap-release-setup.md`의 심사 노트와 QA에 활동 기록 삭제 절차·보상 유지/복귀를 보완하고, 실제 검증 결과는 해당 Timey 소스와 연결해 별도 기록한다.
- 영문 초안: “In Activity History, deleting a record keeps its stickers by default. When linked stickers or unused reward-board slots exist, you can also remove them. Unused rewards return to in-progress status if they fall below their goal; used rewards remain unchanged.” 최종 버튼·화면명과 대조한다.
- 앱 이름·활동 용어·지원 URL은 Timey 기준. iOS IAP는 `com.timeyrider.vehicle_pack`, Android는 `vehicle_pack`을 유지한다. Yamyam의 최소 5분 안내·커밋 해시·검증 수치·출시 완료 표시를 가져오지 않는다.
- 외부 FAQ를 갱신할 경우 ‘기록 삭제가 모든 관련 데이터의 완전 삭제’라고 표현하지 않는다. 삭제 ID와 사용한 보상 이력이 남고 구매 복원과도 별개다. 최근 Timey 개인정보 안내의 로컬 이미지 저장·외부 서비스 설명을 보존한다. 외부 게시와 App Store Connect 입력은 별도 실행 결과로 기록한다.

## 9. 계획 리뷰와 현재 검증 상태

- Reviewer: agy, compact plan review 최대 2회.
- 1차 유효 리뷰: 지적 3건 반영. 모든 보상 변경 경로의 초과 슬롯 무손실 보존, 단일 레거시 보상의 상태별 이관, 삭제 ID 우선 복구 및 정리 재시도의 재확인을 명확히 했다. 레거시 상태는 슬롯 수로 추정하지 않는다.
- 2차 유효 리뷰: 지적 3건 중 2건 부분 반영, 1건 제외. 원본 재조회/전체 active 조회 계약과 과거 저널의 키별 정리를 구체화하고 used 이관의 기존 우선순위를 명시했다.
- 부분 미수용: 레거시 used/redeemed 전체 병합은 기존 fallback 우선순위를 바꾸고 중복 이력을 만들 수 있어 채택하지 않았다. 현재 UI가 슬롯 모델을 저장 API로 전달한다는 전제도 실제 goalId 기반 호출과 다르며, 재조회 계약을 보강하는 수준으로 반영했다.
- 제외: 정상 pending에 null sessionId가 있다는 가정은 ActiveActivityTimerSession.fromJson의 필수 ID 검증과 PendingActivityResult.fromJson의 ID 복원에 맞지 않는다. endedAt을 pending 정리 식별자로 사용하는 변경은 새 세션 오정리 위험 때문에 적용하지 않는다.
- 리뷰 요약: agy 유효 리뷰 2회, 지적 총 6건(3건 반영·2건 부분 반영·1건 제외), 사용자 결정 필요 없음. 긴 리뷰 산출물은 남기지 않았다.
- 현재 검증: Timey 소스·모델·저장소·기존 테스트 13개 경로 대조 및 문서 공백 검사. 구현 전이므로 앱 테스트·실기기·빌드 결과는 NOT RUN.

## 10. 후속 구현 결과 (2026-10-18)

계획에 따른 앱 코드·5개 언어 안내·저장소/화면 회귀 테스트를 구현했다.
최종 전체 테스트 615개, 정적 분석, 공백 검사, 서명 없는 iOS Release 로컬 빌드가 통과했다.
보상 사용 이관의 선택 원본을 안전하게 재복구하기 위한 저널 메타데이터와 SharedPreferences 캐시 실패 처리를 구현 세부 사항으로 보완했다.

상세 범위·소스 지문·명령·남은 실기기 및 출시 게이트는
[ACTIVITY_HISTORY_LINKED_DELETE_VERIFICATION.md](ACTIVITY_HISTORY_LINKED_DELETE_VERIFICATION.md)에 기록했다.
실기기 업데이트/접근성/응답시간, Sandbox 구매·복원, 서명된 Archive/export·배포 검증은 완료로 표시하지 않는다.
