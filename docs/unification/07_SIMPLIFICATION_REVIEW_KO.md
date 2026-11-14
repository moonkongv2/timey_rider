# 저장 아키텍처 단순화 재검토

2026-11-14. 측정 사실과 설계 판단을 구분한다. VERIFIED=source/공식 계약 확인, PROPOSED=권고, ASSUMED=명시 해석. 실기기 실패율·속도·개발 일수는 측정하지 않았다.

## 1. 이전 제안과 새 결정

이전 제안은 mode 분리+root coordinator+SQLite 6개 테이블에 더해 기존 Timey 데이터 importer, 원본 backup, journal replay, marker, 복구 queue, 역사 표시, 구버전 복귀 제약을 요구했다. **새 확정 결정에 따라 사전 출시 데이터 이관 관련 요구 전부 폐기**한다. 옛 테스트 설치의 history/스티커/goal/설정/preset/session/photo/local entitlement cache는 보존 대상이 아니다. 통합 앱의 새 데이터와 실제 Timey store 구매 복원은 계속 보존 대상이다.

## 2. 신뢰성 판단 기준

ASSUMED: “신규 데이터가 crash 후에도 보존되어야 한다”는 저장 성공을 사용자에게 표시한 작업을 재시작 후 조용히 잃어서는 안 된다는 의미로 해석한다. 진행 중 아직 commit하지 못한 작업은 오류 또는 재시도 가능한 이전 상태로 남아도 된다. 물리 디스크 고장·uninstall을 막는 cloud backup은 요구하지 않는다. 이 해석은 새 데이터의 신뢰성 요구를 낮추지 않기 위한 기준이다.

VERIFIED: 기존 code에는 journal, 직렬 queue, 중복 session 검사, 삭제 tombstone이 있다. 이것들은 유효하며 새 설계도 동일한 멱등성 원칙을 유지한다. 그러나 Y goal 사용의 earned 저장→used 저장은 journal 밖이고, 두 앱의 result 기록→active clear는 별도 storage operation이다. 실제 crash 재현은 미실행이다. [03의 source 분석](03_DATA_IAP_DESIGN_KO.md)을 근거로 아래를 판단한다.

## 3. 네 가지 대안 결정표

| 평가 | A 기존 SharedPreferences+분리 키 | B SharedPreferences+일관된 snapshot | C 설정 preferences+핵심 SQLite | D 모든 구조화 상태 SQLite |
|---|---|---|---|---|
| 구현 가능성 | 가능, 보상/세션 요구 일부 미충족 | 가능, 논리 정합성 크게 개선 | 가능, 핵심 상태는 안전한 경계 가능 | 가능, 현재 모바일 범위 적합 |
| 복잡도 | 초기 낮음, 오류 경로 보완 중~높음 | 중, snapshot/queue/검증 필요 | 중~높음, backend2개·오류 모델2개 | 중, 작은 DB adapter 하나 |
| 필요한 변경 | namespace·fallback 제거·오류 전달 | 모드 snapshot, global session 쓰기 조정, 단일 writer | progress/session/outcome DB, settings adapter 유지 | service 저장 IO 교체, snapshot2테이블 |
| 신규 의존성 | 없음 | 없음 | sqflite1개 | sqflite1개 |
| 코드 재사용 | 가장 큼, journal 그대로 | domain 재사용, storage 상당 부분 교체 | domain·settings IO 일부 재사용 | domain/UI/API 재사용, preferences IO 제거 |
| transaction 안전 | 여러 키 원자성 없음 | mode 내부 한 snapshot으로 논리 정합성 개선, mode+session은 별개 | DB에 둔 핵심 범위만 원자적 | 완료·session·goal·shared 상태의 각 명령 원자적 |
| crash 복구 | journal 살아 있으면 replay, 누락 시 제한 | 전체 snapshot이 이전 상태로 남을 수 있음; 확인한 결과 유실 가능 | 핵심 DB 복구, settings 최신 쓰기 영속성 한계 남음 | native rollback, outcome 재확인; 앱 로직 검증은 별도 |
| schema 관리 | key/legacy 분기 증가 위험 | payload version 관리 | payload와 DB version 각각 | DB user_version + 현재 payload validator |
| 테스트 부담 | 실패 지점별 journal·순서 검증 높음 | 동시 쓰기·다중 key 경계·partial flush 검증 높음 | 두 backend+경계 연결 검증 | DB adapter·원자 경계·실기기 kill 검증 |
| runtime 성능 | 작은 설정에 적합, 여러 write | 큰 JSON 재인코딩·rewrite 비용 | 작은 설정 별도, 핵심 DB 비용 | 작은 config도 DB async; mode JSON 크기 증가 시 비용 |
| 미래 유지보수 | 오류 분기 지속 관리 | 규모 커지면 수제 transaction 요구 가능 | 두 lifecycle/테스트 체계 유지 | 저장 책임 한 곳, SQL/플러그인 유지 비용 |
| 개발 노력 | 초기 최소, 신뢰성 추가하면 증가 | 중, 보장 한계는 해소 안 됨 | 중~높음 | 중~높음, 과거 이관 제거로 크게 감소 |
| 남는 실제 위험 | bool 미검사, partial goal update, callback 반복 | flush 미보장, snapshot lost update·session 불일치 | preferences 최신 저장 유실·DB와 config 연결 시차 | 잘못된 SQL/도메인 로직·파일 참조·기기 환경 |
| 단계 영향 | 빠른 UI, 이후 오류 수정 집중 | 저장 경계 PR가 선행 필요 | DB+preferences 합동 gate 필요 | 작은 DB PR만 실행 기능 선행; 화면 shell은 독립 |
| 판정 | 미채택 | 미채택 | 가능하지만 미채택 | **선택** |

복잡도/노력 비교는 정성 추정이며 개발 기간·성능 개선율이 아니다. 사진 파일은 모든 대안에서 별도 파일 서비스이며 D의 “모든 상태”는 구조화 metadata를 뜻한다.

## 4. 왜 SQLite를 남기는가

**이관을 없애도 저장 성공한 보상과 활성 세션이 crash 후 사라지면 안 된다는 요구는 남는다.** A의 journal 누락·부분 goal 갱신은 신규 데이터에서도 발생 가능한 경로다. B는 mode별 스티커/history/goal을 한 JSON으로 묶고 write queue와 stable sessionId를 쓰면 상당수 문제를 줄인다. 하지만 SharedPreferences는 쓰기 완료 뒤 disk 반영을 보장하지 않는다. 전체 앱을 한 키에 넣어도 최신 완료 결과 전체가 이전 snapshot으로 돌아갈 위험과 모든 mode가 같은 저장 단위를 공유하는 부담이 남는다. `reload`, 두 슬롯/백업 키, 지연 대기, SharedPreferencesAsync는 해당 계약을 transaction/durable commit으로 바꾸지 않는다. [SharedPreferences 공식 문서](https://pub.dev/packages/shared_preferences).

따라서 네 대안 중 현재 요구를 만족시키려면 핵심 상태에 C 또는 D가 필요하다. SQLite 자체만 유일한 기술인 것은 아니지만 다른 durable 파일/WAL 저장소를 직접 만드는 것은 더 복잡하다. C는 설정/최근값의 최근 저장 손실을 허용하는 제품이라면 합리적이다. 이번 요구는 새 앱의 설정·preset도 보존 대상으로 해석했으며, DB 도입 후 작은 JSON row 몇 개를 추가하는 것보다 별도 preferences backend를 유지하는 실익이 작다. **D를 유지하되 이전의 이관·일반화·중복 ledger를 제거하는 쪽이 단순하다.**

구체적으로 거절할 실패는 (1) 저장됐다고 표시한 새 sticker/goal 사용 결과 소실, (2) history는 있는데 inventory/goal은 반영되지 않은 상태, (3) 완료 후 session 부활 또는 결과 확인 불가, (4) 삭제된 기록의 늦은 callback 재지급이다. 2·4는 B로 완화 가능하지만 1의 저장 계약과 3의 여러 상태 경계를 해결하려면 추가 수제 transaction 계층이 필요하다. 이 때문에 SQLite를 선택하며 일반적인 “더 강력하니 좋다”가 이유는 아니다.

SQLite는 검증된 transaction 구현을 제공하지만 앱 버그나 파일시스템 손상까지 없애지 않는다. 처음 도입하는 plugin/API/DDL 위험은 있고 실기기 검증 전에 안전하다고 확정할 수 없다. [SQLite atomic commit](https://sqlite.org/atomiccommit.html), [sqflite](https://pub.dev/packages/sqflite). 기존 prefs보다 순위상 무조건 안전하다는 주장 대신 P2 adapter 게이트와 P7 kill 테스트를 출시 조건으로 둔다.

## 5. 질문 8개에 대한 명시 답변

1. **SQLite가 필요한가?** 네 대안과 위 신뢰성 해석에서는 적어도 핵심 상태에 필요하며, 최종적으로 D를 권고한다. 이관 목적 때문은 아니다.
2. **SQLite 없이 남는 실패는?** 성공 반환 후 최신 쓰기 유실, 다중 상태 partial update, snapshot과 global session 간 시차, 영속 dedup 정보 유실.
3. **기존 구조로 충분히 완화 가능한가?** queue/idempotency/journal/snapshot으로 논리 경합은 완화 가능. preferences의 disk 계약 자체는 개선 불가하므로 요구를 완전히 만족한다고 할 수 없다.
4. **SQLite 도입이 더 위험한가?** 초기 adapter 회귀 위험은 증가한다. 그러나 옛 데이터 이관이 없고 두 테이블로 제한하면 기존 수제 journal 확장을 피할 수 있다. 총 위험 감소는 정성 판단이며 실측 아님.
5. **가장 작은 충분한 구현은?** 기존 도메인 서비스와 JSON, 한 DB connection·두 테이블, 고정 namespace, 단일 active coordinator, 원자적 완료/삭제, durable outcome.
6. **삭제 가능한 원 설계는?** 아래 제거 목록 전부. 특히 importer와 backup/recovery queue 및 범용 operations ledger를 만들지 않는다.
7. **유효한 원 결정은?** mode 모듈 분리, 단일 구매/세션 owner, 각 보상 service, cold selector/warm route 유지, origin home 복귀, confirmed pending 구분, 5언어.
8. **얼마나 단순화되는가?** 기존 6 table 제안→2 table, 별도 과거 데이터 importer0, export/import0, 앱 레벨 이관 journal0. P0~P7는 제품별 검증 단계로 유지하나 P1-b 전체 이관 PR와 호환 fixture·옛 preset 전환 UX를 제거. 일정 절감률은 산정하지 않았다.

## 6. 제거·유지 목록

| 제거(결정으로 폐기) | 유지(통합 앱의 새 데이터) |
|---|---|
| LegacyTimeyImporter / Y export·import | 새 DB 최초 생성, store 구매 restore |
| 옛 preferences fallback·과거 JSON 변환 | 현재 v1 decoder/validator |
| 과거 history/reward 재구성·transaction replay | 현재 transaction/완료 재시도 |
| migration gate/marker/journal/backup/복구 queue | DB open 준비 상태·native crash recovery |
| legacy meal preset badge/전환·history 표시 | Daily meal 신규 선택/실행 제거 |
| 옛 app downgrade 지원·migration rollback | 미래 unified update 데이터 보존 |
| 과거 설치 보존만 검증하는 test fixtures | 새 데이터 kill/restart/update·격리 테스트 |
| 일반 operations table·이중 tombstone 목록 | session_outcomes의 완료/취소/삭제 상태 |

## 7. 수정한 단계 의존성

P0 기준선 → P1 개발용 mode shell → P2 새 저장 경계 → P3 Meal 이식 → P4 공유 구매/프로필 → P5 단일 session·공개 전환 → P6 localization → P7 실기기/출시. P1 UI는 fake 주입으로 P2와 독립 검증 가능; P3의 파일 복사·모델 compile도 P1 뒤 가능하나 실제 저장은 P2 이후. 실제 두 모드 실행 공개는 P2/P3/P4/P5를 모두 통과해야 한다. 과거 데이터 이관이 전체 기능의 선행 조건인 구조는 제거했다.

## 8. 남은 위험과 준비도

핵심 위험은 DB adapter 구현, session controller 수명 이전, 두 모드 데이터 접근 실수, store restore 지연, 사진 파일/DB 경계다. 각 위험에 대응하는 실패 주입·실기기 테스트는 [05](05_TEST_RELEASE_PLAN_KO.md)에 있다. 실제 backend plugin 호환성과 store 설정은 아직 미검증이다.

**READY WITH MINOR CONDITIONS**: P0/P1 구현은 시작 가능. P2 연결 전에 SDK 호환 sqflite 버전과 최소 기기 transaction smoke 확인, 공개 전환 전에 P5 복구 gate, 출시 전에 실제 Timey 상품 restore가 필요하다. 새로운 제품 승인이나 전체 아키텍처 재설계는 필요하지 않다. 앱 코드는 이번 검토에서 변경하지 않는다.


검증 기록: 이번 개정 agy 리뷰1회에서 추가 조치 사항 없음. 문서 정합성 검사와 허용 문서 외 양 저장소 파일 hash/HEAD 비교 통과. 실제 앱 테스트·구매·성능 측정은 미실행이다.
