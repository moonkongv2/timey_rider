# Timey Rider 마이그레이션 계획

## 1. Goal

이 저장소는 이제 기존 Yamyam Rider 식사 타이머와 분리된 새 앱, Timey Rider를 위한 저장소이다.

Timey Rider는 아이들이 일상 루틴과 활동을 즐겁게 끝낼 수 있도록 돕는 범용 키즈 루틴/활동 타이머를 목표로 한다. 지원 대상은 양치, 독서, 정리, 놀이 시간, 사용자 지정 타이머 같은 반복 활동이다.

## 2. Product direction

기존 앱에서 효과적이었던 라이더/차량 기반 여정 메타포는 유지한다. 아이는 활동 시간 동안 차량을 타고 길을 달리며, 남은 시간과 진행 상황을 직관적으로 이해할 수 있어야 한다.

다음 경험은 Timey Rider에서도 보존한다.

- 아바타 선택 및 흐름
- 차량 카탈로그와 차량 선택 경험
- 동기부여 비디오/오디오 시스템
- 타이머 완료 결과 화면
- 로컬 기록 저장
- 스티커와 보상 목표
- 로컬 전용 저장 방식

식사와 식재료 중심 개념은 활동과 마커 중심 개념으로 대체한다. 기존의 식재료 카탈로그는 활동별 중간 지점, 체크포인트, 보상 마커를 표현하는 구조로 바꾼다.

## 3. Target naming

- App name: Timey Rider
- Dart package: `timey_rider`
- Android applicationId: `com.moonkong.timeyrider`
- iOS bundle id: `com.moonkong.timeyrider`

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

Timey Rider의 첫 MVP 활동은 다음으로 정의한다.

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

## 7. Final status

Timey Rider 마이그레이션의 핵심 리팩터링은 완료되었다.

- 앱 이름, Dart 패키지, Android applicationId, iOS bundle id가 Timey Rider 기준으로 변경되었다.
- 타이머 설정, 컨트롤러, 활성 세션, 결과, 기록, 로컬 진행 저장소가 활동 도메인 이름으로 정리되었다.
- 홈 화면은 활동 빠른 시작 흐름을 사용하며, 양치, 책 읽기, 정리, 놀이, 직접 설정을 시작할 수 있다.
- 활동 마커 카탈로그가 도입되어 기존 중간 지점 표현을 활동별 마커로 대체했다.
- 결과, 기록, 설정, 사용자 가이드, 보상 문구는 루틴/활동 타이머 관점으로 정리되었다.
- 스티커 보상은 완료된 활동 미션에만 지급되며, 놀이처럼 시간이 끝나는 활동은 기본 보상을 지급하지 않는다.
- 기존 로컬 저장 데이터는 읽기 전용 fallback으로 불러오되, 새 저장은 activity/marker 키만 사용한다.
- 홈 로고와 앱 아이콘은 Timey Rider 자산 경로를 참조한다.

## 8. Remaining TODO assets

현재 앱은 누락된 일부 선택 자산이 있어도 이모지나 기본 이미지 fallback으로 동작한다. 이후 polish 단계에서 다음 자산을 보강한다.

- 활동 마커 이미지 자산
- 루틴 테마 스티커 이미지 자산
- 차량별 동기부여 영상과 결과 영상의 추가 변형
- 스토어 등록용 스크린샷과 프로모션 이미지

## 9. Remaining product polish

기능 추가 없이 안정화 이후 별도 작업으로 다룰 polish 항목은 다음과 같다.

- 직접 설정 활동의 이름 입력과 프리셋 확장
- 보호자용 활동별 권장 시간 설명
- 활동별 완료 질문 문구 세분화
- 보상 목표 UX의 빈 상태와 장기 사용 흐름 개선
- 실제 기기에서 홈, 타이머, 결과 화면의 시각 밸런스 확인
