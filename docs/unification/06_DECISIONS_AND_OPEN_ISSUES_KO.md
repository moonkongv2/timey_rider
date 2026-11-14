# 개정 결정·가정·남은 조건

2026-11-14. 이 문서는 이전 과거 데이터 보존 권고를 대체한다. 새 결정의 비교 근거는 [07](07_SIMPLIFICATION_REVIEW_KO.md), 데이터 계약은 [03](03_DATA_IAP_DESIGN_KO.md).

## 1. 확정 요구

- 최종 Timey Rider, T repository·bundle/application ID·Timey IAP 상품 유지. Y는 reference로만 읽는다.
- 사전 출시 두 앱의 로컬 history/sticker/goals/presets/preferences/session/photo/cache/실험 JSON은 **이관·보존 불필요**. 이를 다시 제품 소유자에게 묻지 않는다.
- 통합 앱이 새로 만드는 데이터는 정상 재시작·process kill·crash·미래 update에서 보존한다. 매 startup/version bump 초기화 금지.
- Meal/Daily history·inventory·earning·goal/progress/redemption·통계·삭제 영향 독립. 공용 reward wallet/전송 없음.
- 공용 차량/프로필/사진·단일 Vehicle Pack owner, 실제 Timey store restore 유지. Y bundle 구매 자동 이전 없음.
- fresh selector, warm route 유지, 쉬운 모드 전환, active1개, session mode/완료 멱등성 유지.
- 5언어·기존 정책/UX 유지, Daily meal 신규 실행 제거, serverless. 현재 작업은 설계 문서 수정만.

## 2. 개정 결정

| ID | 결정 | 이유·검증 |
|---|---|---|
| D01 | mode feature 분리 유지, Daily 기존 위치 | 결과/기간 정책 다름, 전체 rename 불필요 |
| D02 | 저장 D: SQLite 모든 구조화 상태 | 완료 성공 뒤 신규 데이터 보존 계약; A/B는 plugin durability 한계, C는 backend2개 |
| D03 | schema2개 table, 명시 service adapter | 기존 metadata/operations/이중 tombstone·범용 capability 계층 제거 |
| D04 | clean namespace·onCreate 최초1회 | 옛 테스트 값 미참조, 신규 production reset0 |
| D05 | 기존 reward 계산·API 재사용 | storage IO와 journal만 교체, 목표 철학 유지 |
| D06 | coordinator notifier+queue+handle1개 | 옛 session 병합/복구 queue 없음, 현재 session 복구는 유지 |
| D07 | root Timey 구매 controller 하나 | 양 mode 같은 entitlement·store stream, Y request guard/restore wait 보완 |
| D08 | mode home→선택 버튼, origin home callback | nested app/shell 불필요, route.isFirst 함정 방지 |
| D09 | Daily meal 선택/실행 제거 | 옛 역사/preset 보존 필요 없음, migration UI 삭제 |
| D10 | 완료 outcome result/config/ack 유지 | commit 후 UI 전 crash 복구와 duplicate 지급 방지 |
| D11 | P1 shell은 fake로 먼저, public switch는 P5 이후 | 데이터 이관 의존 제거, 불완전한 실제 실행 공개 방지 |

SQL 선택은 선결 가정이 아니라 A~D 비교 결과다. SQLite 없이도 논리 경합은 크게 줄일 수 있지만 저장 성공 후 durability는 보장할 수 없다는 제한을 숨기지 않는다. 신뢰성 기준을 낮추는 사용자 승인을 전제로 한 대안은 채택하지 않았다.

## 3. 폐기된 요구 — 구현하지 않음

LegacyTimeyImporter, Y export/import, 옛 SharedPreferences fallback/JSON decoder, 옛 history/goal 복원, 과거 transaction replay, migration gate/marker/journal/backup/queue, migration rollback, 옛 앱 downgrade, legacy meal badge·preset 변환, 과거 설치 보존 전용 fixture를 제거했다. 관련 사용자 결정 질문도 없다. 최초 생성·미래 unified schema update·현재 session recovery·native SQLite transaction은 제거 대상이 아니다.

## 4. 명시 가정과 현실적 조건

ASSUMED: 모바일 iOS/Android 단일 engine, single child profile. multi-window/cloud sync/다중 계정·영양 기능은 이번 범위 밖. profile 수정은 다음 실행에 적용하고 진행 session은 고정 config를 사용한다.

ASSUMED: 저장 성공한 신규 설정/preset도 crash 후 유지해야 한다. 이 요구를 기준으로 D를 선택했다. 저장 중 crash는 이전 committed 상태 또는 완료된 새 상태 중 하나로 복구하며, 하드웨어 파괴/uninstall 복구까지 약속하지 않는다.

| 미확인 항목 | 조건 / 처리 |
|---|---|
| sqflite 최종 버전·Dart/OS 호환 | P0에서 pin과 device smoke; P1 UI 구현은 차단하지 않음 |
| 실제 Console T 상품 활성/가격·sandbox 계정 | P4/P7 구매·restore 검증 필요. local cache 초기화와 실제 store 권한은 별개 |
| baseline 테스트·실제 iPad layout | P0/P7 실행 전 미검증, 기존 테스트 통과 주장 금지 |
| 플랫폼 revocation/계정 변경·지연 restore | pinned IAP plugin 실제 기기 테스트, cache가 server 검증이라는 주장 금지 |
| Y 중복 submission 철회 일정 | release 운영 조건. 데이터 이관/기존 사용자 구제 설계를 강제하지 않음 |

앱 종료 상태 알림은 기존 구현에서 native scheduling을 확인하지 못했으며 이번에는 앱 내 알람만 보존한다. 별도 notification 기능을 통합의 blocker나 새 기능으로 추가하지 않는다. Apple 승인 보장은 없다.

## 5. 준비도

**READY WITH MINOR CONDITIONS**. P0/P1부터 증분 구현 가능. P2 production 연결 전에 plugin 호환성·transaction smoke, P5 공개 전에 active recovery·격리 gate, P7 출시 전에 실제 Timey restore와 unified update 테스트가 필요하다. 과거 테스트 데이터 확보나 제품 재승인은 필요 없다.

## 6. 이번 개정의 조사·검증

양 repo HEAD는 T `8871c5a4887df6ad8e492ef672a2d7e89965fe71`, Y `254feea3c4e33dea179dc86db838dcff94eafab1`, branch는 양쪽 `fix/road-viewport-sizing`. 시작 시 양 repo에 기존 4개 tracked 수정이 있었고 T에는 `docs/unification.zip`과 문서 디렉터리도 untracked였다. 기존 zip은 갱신하지 않는다.

문서 6개를 읽고 progress/session/settings/preset/recent/cache/photo/result 코드와 공식 storage 계약을 재조사했다. 기존 정상 기능/충돌 목록은 유지하고 폐기된 결정만 교체했다. 앱 코드·tests·자산·pubspec·native config·Y 저장소·Git 이력은 수정 대상이 아니다. 이번 agy compact review는 횟수 생략 규칙에 따라 1회이며 이전 2회 리뷰 기록과 구분한다. 실제 검증 결과는 아래에 기록한다.


### 개정 검증 완료

- 검토자: agy, compact/read-only 지시, 1회 완료. 결과 `No actionable findings.`; 반영/기각 지적0, 제품 추가 결정 요구0.
- 일관성: D 선택·두 table·P0~P7 의존성·새 데이터 보존·구매 restore를 문서 간 대조. 옛 importer/marker/rollback 명칭은 폐기 설명에만 남고 구현 요구에는 없다.
- 문서: 상대 Markdown 링크, fence 균형, trailing whitespace 검사 통과. 양 repo `git diff --check` 통과.
- 변경 제한: T의 허용 문서 디렉터리 및 `.git`을 제외한 파일3,816개와 Y의 `.git`을 제외한 파일7,540개의 경로+내용 집계 SHA-256이 시작/종료 시 동일. 기존 T `docs/unification.zip`도 불변. 양 HEAD/branch 불변, 기존 tracked 수정 유지.
- 미실행: Flutter test/analyze/build·실기기 구매/kill 시험. 문서/리뷰 검증을 앱 실행 검증으로 주장하지 않는다.
