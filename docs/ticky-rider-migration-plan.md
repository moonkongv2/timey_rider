# Ticky Rider 마이그레이션 계획

## 1. Goal

이 저장소는 이제 기존 Yamyam Rider 식사 타이머와 분리된 새 앱, Ticky Rider를 위한 저장소이다.

Ticky Rider는 아이들이 일상 루틴과 활동을 즐겁게 끝낼 수 있도록 돕는 범용 키즈 루틴/활동 타이머를 목표로 한다. 지원 대상은 양치, 독서, 정리, 놀이 시간, 사용자 지정 타이머 같은 반복 활동이다.

## 2. Product direction

기존 앱에서 효과적이었던 라이더/차량 기반 여정 메타포는 유지한다. 아이는 활동 시간 동안 차량을 타고 길을 달리며, 남은 시간과 진행 상황을 직관적으로 이해할 수 있어야 한다.

다음 경험은 Ticky Rider에서도 보존한다.

- 아바타 선택 및 흐름
- 차량 카탈로그와 차량 선택 경험
- 동기부여 비디오/오디오 시스템
- 타이머 완료 결과 화면
- 로컬 기록 저장
- 스티커와 보상 목표
- 로컬 전용 저장 방식

식사와 식재료 중심 개념은 활동과 마커 중심 개념으로 대체한다. 기존의 식재료 카탈로그는 활동별 중간 지점, 체크포인트, 보상 마커를 표현하는 구조로 바꾼다.

## 3. Target naming

- App name: Ticky Rider
- Dart package: `ticky_rider`
- Android applicationId: `com.moonkong.tickyrider`
- iOS bundle id: `com.moonkong.tickyrider`

## 4. Planned code refactors

식사 도메인에 묶인 이름은 활동/루틴 도메인 이름으로 단계적으로 변경한다.

- `MealTimerConfig` -> `ActivityTimerConfig`
- `MealTimerController` -> `ActivityTimerController`
- `MealSessionResult` -> `ActivitySessionResult`
- `MealCompletionStatus` -> `ActivityCompletionStatus`
- `ActiveMealTimerSession` -> `ActiveActivityTimerSession`
- `LocalMealProgressService` -> `LocalActivityProgressService`
- `MealIngredientCatalog` -> `ActivityMarkerCatalog`
- `MealHistoryEntry` -> `ActivityHistoryEntry`

리팩터링은 가능한 한 작은 단위로 진행하고, 기존 함수/클래스 스타일과 테스트 구조를 유지한다. 공개 API, 로컬 저장 키, 마이그레이션이 필요한 데이터 구조는 변경 전에 호환 전략을 정리한다.

## 5. MVP activities

Ticky Rider의 첫 MVP 활동은 다음으로 정의한다.

- Brush Teeth
- Reading
- Cleanup
- Play Time
- Custom Timer

각 활동은 기본 시간, 화면 표시 이름, 활동 마커, 완료 보상 흐름을 가질 수 있다. Custom Timer는 보호자나 사용자가 직접 활동 이름과 시간을 정할 수 있는 경로로 유지한다.

## 6. Suggested commit order

1. Product identity
2. Activity domain models
3. Timer config
4. Timer controller/session
5. Activity markers
6. Home UX
7. Timer/result/history
8. Rewards
9. Localization
10. Cleanup and tests
