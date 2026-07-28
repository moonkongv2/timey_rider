# Timey Rider 코드 리뷰 가이드

이 문서는 이 코드베이스를 처음 보는 개발자가 리뷰 전에 빠르게 맥락을 잡기 위한 가이드입니다. 변경 사항을 볼 때는 기능 자체보다도 타이머 동작, 로컬 저장, 화면 흐름, 다국어 문구, 테스트 범위를 함께 확인하는 것이 중요합니다.

## 제품 맥락

Timey Rider는 아이용 루틴 타이머 Flutter 앱입니다. 아이가 활동과 차량을 고르면 차량이 코스를 따라 움직이고, 활동을 완료하면 스티커를 받아 보상 목표를 채울 수 있습니다.

현재 구조는 로컬 우선입니다. 설정, 실행 중 타이머 세션, 활동 기록, 스티커 인벤토리, 보상 목표는 `shared_preferences`에 저장됩니다. 별도 백엔드는 없습니다.

## 먼저 볼 파일

대부분의 리뷰는 아래 파일을 먼저 읽으면 흐름을 잡기 쉽습니다.

- `lib/main.dart`: 서비스 생성과 앱 부트스트랩.
- `lib/app.dart`: 초기 라우팅, 온보딩, 아이 이름 설정, 앱 전역 설정 저장, 구매 권한에 따른 fallback.
- `lib/screens/home_screen.dart`: 활동 선택, 프리셋, 활성 타이머 재개/취소, 차량팩 진입점, 타이머 진입.
- `lib/screens/timer_screen.dart`: 타이머 생명주기, 활성 세션 저장, 동기부여 미디어, 방향 전환, 완료 처리.
- `lib/screens/result_screen.dart`: 결과 기록, 스티커 선택, 성공/실패 미디어, 보상 목표 업데이트.
- `lib/controllers/activity_timer_controller.dart`: 타이머 상태 머신과 경과 시간 계산.
- `lib/models/activity_timer_config.dart`: 화면 사이에서 공유되고 설정으로 저장되는 핵심 설정 객체.

정적 데이터 정의는 아래 파일에서 확인합니다.

- `lib/catalogs/activity_catalog.dart`: 기본 활동과 기본 시간.
- `lib/catalogs/vehicle_catalog.dart`: 차량 asset, 라벨, 아바타 위치, 코스 종류.
- `lib/catalogs/activity_marker_catalog.dart`: 활동 마커 정의와 코스 마커 생성.
- `lib/catalogs/motivation_asset_catalog.dart`: 동기부여 영상과 음성 asset 선택.
- `lib/catalogs/timer_audio_asset_catalog.dart`: 타이머 BGM, 마커, 미리보기, 도착 오디오 경로.
- `lib/catalogs/result_audio_asset_catalog.dart`: 결과 화면 오디오 경로.
- `lib/catalogs/vehicle_unlock_catalog.dart`: 무료 차량, 잠긴 차량, 차량팩 product id.

## 주요 실행 흐름

일반적인 앱 흐름은 다음과 같습니다.

1. `main.dart`가 `LocalSettingsService`, `LocalActivityProgressService`, `ActiveActivityTimerSessionStore`, 저장된 차량팩 권한을 준비합니다.
2. `TimeyRiderApp`이 splash, onboarding, child name setup, home 중 어떤 화면을 보여줄지 결정하고, 저장된 차량이 아직 잠겨 있으면 무료 차량 fallback을 적용합니다.
3. `HomeScreen`이 선택한 활동, 시간, 차량, 마커로 타이머 설정을 만듭니다.
4. `TimerScreen`이 `ActivityTimerController`를 새로 시작하거나 저장된 세션에서 복원합니다.
5. `TimerScreen`은 실행 중인 `ActiveActivityTimerSession`을 계속 저장해 나중에 재개할 수 있게 합니다.
6. 타이머가 끝나면 `TimerScreen`이 `ActivitySessionResult`를 만들고 `ResultScreen`으로 이동합니다.
7. `ResultScreen`이 `LocalActivityProgressService`를 통해 결과를 기록합니다.
8. `LocalActivityProgressService`가 활동 기록, 스티커 인벤토리, 보상 목표를 업데이트합니다.

리뷰할 때는 변경 지점이 이 흐름 중 어디에 있는지 먼저 확인하고, 앞뒤 단계의 전제도 함께 확인합니다.

## 상태와 저장

대부분의 영속 상태는 `shared_preferences`에 저장됩니다.

- `LocalSettingsService`: 앱 설정, 아이 이름, 선택 차량, 사운드/영상 옵션, 마커 모드, 아바타 설정.
- `ActiveActivityTimerSessionStore`: 현재 실행 중이거나 일시정지된 타이머를 JSON으로 저장.
- `LocalActivityProgressService`: 활동 기록, 스티커 인벤토리, 활성/획득/사용된 보상 목표.
- `LocalRecentTimerService`, `LocalSavedTimerPresetService`: 최근 타이머와 저장된 타이머 프리셋.
- `LocalAvatarImageService`: 가져온 아바타 이미지 저장과 정규화.
- `LocalPurchaseEntitlementStore`: 차량팩 권한 캐시.

저장 관련 변경은 특히 보수적으로 리뷰합니다.

- 기존 키와의 호환성을 유지해야 합니다. 의도적인 마이그레이션이면 범위가 명확해야 합니다.
- 잘못된 JSON이나 누락된 필드가 앱 크래시로 이어지지 않아야 합니다.
- 모델의 `toJson`과 `fromJson`이 함께 업데이트되었는지 확인합니다.
- 기본값이 `ActivityTimerConfig.defaults()`와 충돌하지 않는지 확인합니다.
- 누락 필드, 예전 필드, 잘못된 값에 대한 테스트가 있는지 확인합니다.

## 타이머 동작

`ActivityTimerController`는 wall-clock 기반입니다. `Timer.periodic`은 UI 갱신을 위해 쓰지만, 실제 경과 시간은 `DateTime` 차이로 계산합니다. 프레임이나 tick이 늦어져도 실제 타이머 시간이 밀리지 않도록 한 구조입니다.

주요 상태는 다음과 같습니다.

- `idle`: 시작 전.
- `running`: 타이머 실행 중.
- `paused`: 일시정지 상태이며 정지 시간이 누적됩니다.
- `arrived`: 목표 시간이 끝났지만 완료 처리가 아직 남아 있을 수 있습니다.
- `completed`: 최종 결과가 생성된 상태입니다.

타이머 변경 리뷰 시 확인할 점:

- pause/resume 계산이 맞는지.
- 저장된 세션 복원이 맞는지.
- 경과 시간이 음수가 되지 않도록 clamp 되는지.
- 활동별 완료 방식에 따른 도착 처리 흐름이 맞는지.
- 완료 후 활성 세션이 정리되는지.
- 앱 pause/resume lifecycle에서 세션 저장과 시간 갱신이 맞는지.
- 미리보기, ready/start, 마커, finish drive, arrival 같은 타이머 오디오 cue가 중복 재생되거나 누수되지 않는지.

## 활동, 마커, 차량

활동과 차량은 정적 카탈로그로 관리됩니다. 새 항목이나 변경이 있으면 asset, 테스트, 다국어 문구를 함께 봐야 합니다.

활동 변경 시 확인할 점:

- `ActivityCatalog`에 안정적인 id, 지원 locale별 라벨, emoji, 기본 시간, 프리셋 시간, 완료 방식, 보상 기본값, 마커 id가 들어갔는지.
- 마커 id가 `ActivityMarkerCatalog`에 존재하는지.
- catalog lookup과 fallback 동작이 테스트되는지.

차량 변경 시 확인할 점:

- `VehicleCatalog`의 `assetPath`, `selectionAssetPath`, 지원 locale별 라벨, 아바타 슬롯, 필요한 road anchor offset, course kind가 맞는지.
- 결과 영상과 동기부여 미디어 fallback이 여전히 유효한지.
- 보상 스티커 lookup이 깨지지 않는지.
- 차량팩 잠금 정책이 `VehicleUnlockCatalog`와 계속 맞는지.
- 동작이 바뀌었다면 아바타/차량 표시 테스트가 있는지.

## 구매와 보호자 확인

차량팩은 클라이언트 전용 non-consumable 구매입니다. 앱은 로컬 권한을
캐시하고, 재설치나 기기 변경 후 복구는 스토어 restore에 의존합니다.

주요 파일:

- `lib/catalogs/vehicle_unlock_catalog.dart`
- `lib/models/purchase_entitlement.dart`
- `lib/services/iap_purchase_client.dart`
- `lib/services/local_purchase_entitlement_store.dart`
- `lib/services/vehicle_pack_purchase_controller.dart`
- `lib/widgets/purchase/parent_gate_sheet.dart`
- `lib/widgets/purchase/vehicle_pack_info_sheet.dart`
- `lib/widgets/purchase/vehicle_pack_purchase_sheet.dart`
- `docs/iap-release-setup.md`

리뷰 체크포인트:

- 잠긴 차량은 보이되 권한 전에는 바로 선택할 수 없어야 합니다.
- 구매와 복원 진입점은 보호자 확인 뒤에만 열려야 합니다.
- 보호자 확인 전 안내 sheet에는 가격이나 직접 구매 문구가 노출되지 않아야 합니다.
- 구매나 복원 성공 시 잠긴 차량이 모두 열리고, 가능한 경우 사용자가 고르려던 차량 선택이 이어져야 합니다.
- 실패, 취소, pending, 상품 없음, 복원 내역 없음 상태가 로컬 설정을 망가뜨리지 않아야 합니다.
- 저장된 잠긴 차량 id는 권한 복원 전까지 무료 차량으로 fallback되지만, 저장된 premium 선택 자체를 덮어쓰면 안 됩니다.
- product id 변경은 스토어 설정 문서와 테스트까지 함께 맞아야 합니다.

## 동기부여 미디어

동기부여 영상과 음성은 타이머 중에 선택됩니다.

주요 파일:

- `lib/screens/timer_screen.dart`
- `lib/utils/motivation_video_schedule.dart`
- `lib/catalogs/motivation_asset_catalog.dart`
- `lib/services/motivation_audio_service.dart`

리뷰 체크포인트:

- 사운드가 꺼져 있으면 음성이 재생되지 않아야 합니다.
- 동기부여 영상이 꺼져 있으면 영상 스케줄링이 되지 않아야 합니다.
- 같은 세션에서 진행률 milestone이 반복 표시되지 않아야 합니다.
- 긴 타이머와 custom interval에서 timed schedule이 맞게 동작해야 합니다.
- 복원된 세션은 이미 보여준 milestone과 마지막 표시 시간을 유지해야 합니다.
- fallback asset 경로가 유효해야 합니다.

## UI와 네비게이션

중앙 라우터 대신 `MaterialPageRoute`를 직접 사용합니다. `HomeScreen`은 `appRouteObserver`를 통해 하위 화면에서 돌아왔을 때 데이터를 새로고침합니다.

UI 변경 리뷰 시 확인할 점:

- `TimerScreen`의 portrait/landscape 동작.
- timer와 result 화면 사이의 orientation handoff.
- 작은 화면에서 text overflow가 없는지.
- 버튼 활성/비활성 조건과 dialog cancel 경로.
- 새 타이머 시작 전 활성 세션 경고 흐름.
- onboarding과 child name setup 회귀 여부.

공통 UI primitive는 `lib/widgets/app/`, 디자인 토큰은 `lib/theme/`에 있습니다. 새 스타일을 만들기보다 기존 토큰과 컴포넌트를 우선 사용해야 합니다.

## 다국어

이 프로젝트는 ARB 기반 generated localization이 아니라 직접 만든 텍스트 번들을 사용합니다.

주요 파일:

- `lib/l10n/app_texts.dart`
- `lib/l10n/text_sets.dart`
- `lib/l10n/en/`
- `lib/l10n/ko/`
- `lib/l10n/ja/`
- `lib/l10n/es/`
- `lib/l10n/pt_BR/`

사용자에게 보이는 문구가 추가되면:

- `text_sets.dart`의 적절한 interface에 getter나 method를 추가합니다.
- 영어, 한국어, 일본어, 스페인어, 브라질 포르투갈어 구현을 모두 추가합니다.
- catalog 라벨은 `labelKo`, `labelEn`, `labelJa`, `labelEs`, `labelPtBr`처럼 지원 locale별 필드를 모두 업데이트합니다.
- 주변 코드가 명시적으로 비현지화 debug/test copy를 쓰는 경우가 아니라면 화면 파일에 문자열을 직접 넣지 않습니다.
- 정확한 문구를 검증하는 widget test가 깨지는지 확인합니다.
- 넓은 locale 검증은 `test/localization_support_test.dart`도 확인합니다.

## 보상과 활동 기록

완료된 세션의 핵심 기록 경로는 `LocalActivityProgressService.recordActivityResult`입니다.

리뷰 체크포인트:

- 완료/미완료 상태 판정이 맞는지.
- `ActivityCompletionStatus`별 스티커 지급 가능 여부가 맞는지.
- 보상 목표 slot 채우기와 active에서 earned로 넘어가는 전환이 맞는지.
- 스티커 인벤토리 count가 올바르게 증가하는지.
- 활동 기록 정렬, 삭제, 선택 마커 저장이 유지되는지.
- 아직 필요한 경우 이전 `meal*` 키 fallback이 유지되는지.

## 아바타 흐름

아바타는 차량별로 저장되며, 과거 단일 아바타 설정과의 호환 코드도 있습니다.

주요 파일:

- `lib/models/activity_timer_config.dart`
- `lib/services/local_settings_service.dart`
- `lib/services/local_avatar_image_service.dart`
- `lib/screens/avatar_setup_screen.dart`
- `lib/widgets/avatar/avatar_composite_preview.dart`
- `lib/widgets/vehicle_widget.dart`
- `lib/widgets/vehicle_selection_card.dart`

리뷰 체크포인트:

- 커스텀 아바타가 설정한 차량에만 적용되는지.
- 로컬 이미지 파일이 없어도 안전하게 fallback 되는지.
- scale, offset, rotation이 저장과 복원 모두 되는지.
- legacy avatar field가 차량별 map으로 계속 마이그레이션되는지.

## 테스트 선택

변경 범위에 맞는 가장 작은 테스트부터 실행하고, 여러 영역을 건드렸다면 범위를 넓힙니다.

공통 명령:

```bash
flutter analyze
flutter test
```

변경 유형별 추천 테스트:

- 타이머 계산 또는 복원: `flutter test test/activity_timer_controller_test.dart`
- 활성 세션 저장: `flutter test test/active_activity_timer_session_store_test.dart`
- 설정 저장: `flutter test test/local_settings_service_test.dart test/local_settings_service_onboarding_test.dart`
- 활동/마커 catalog 변경: `flutter test test/activity_domain_test.dart test/activity_marker_catalog_test.dart`
- 타이머 프리셋 변경: `flutter test test/activity_timer_preset_test.dart test/local_recent_timer_service_test.dart test/local_saved_timer_preset_service_test.dart`
- 아바타 변경: `flutter test test/local_avatar_image_service_test.dart test/avatar_composite_preview_test.dart test/vehicle_avatar_presentation_test.dart`
- 다국어 변경: `flutter test test/localization_support_test.dart`
- 구매 또는 잠긴 차량 변경: `flutter test test/app_purchase_entitlement_test.dart test/vehicle_pack_purchase_controller_test.dart test/vehicle_pack_purchase_sheet_test.dart test/parent_gate_sheet_test.dart test/iap_purchase_client_test.dart test/local_purchase_entitlement_store_test.dart`
- 온보딩과 앱 레벨 흐름: `flutter test test/onboarding_screen_test.dart test/app_onboarding_flow_test.dart`
- 넓은 UI 동작: `flutter test test/widget_test.dart`

테스트를 실행할 수 없다면 실행한 명령, 실패 이유, 영향 범위를 리뷰 코멘트에 명확히 남깁니다.

## 특히 위험한 변경 지점

아래 파일이나 개념을 건드리는 변경은 리뷰 강도를 높입니다.

- `TimerScreen`: 타이머 상태, 저장, 미디어 재생, 방향 전환, 네비게이션, dialog가 한 곳에 모여 있습니다.
- `ActivityTimerConfig`: 여러 화면에서 공유되고 여러 저장 경로에 들어가는 핵심 모델입니다.
- `LocalActivityProgressService`: 결과 기록 한 번에 여러 상태를 업데이트합니다.
- `LocalSettingsService`: 앱 업데이트 후 기존 사용자 설정에 직접 영향을 줄 수 있습니다.
- `VehiclePackPurchaseController`, `IapPurchaseClient`, `VehicleUnlockCatalog`: 구매 상태가 차량 선택, 설정, 아바타 설정, 복원 동작에 영향을 줍니다.
- vehicle id 또는 activity id: 저장 데이터, catalog, 보상, 미디어, 테스트, 기록에서 참조됩니다.
- localization interface: getter 추가 시 지원 locale 구현이 모두 필요합니다.
- asset path: 컴파일보다 런타임에서 깨지는 경우가 많습니다.

## 리뷰 체크리스트

승인 전에 아래 항목을 빠르게 확인합니다.

- 변경 범위가 요청한 동작에 맞게 제한되어 있습니다.
- home -> timer -> result 기본 흐름이 유지됩니다.
- 저장 모델이 예전 데이터와 누락 데이터를 안전하게 처리합니다.
- 타이머 pause, resume, restore, arrival, completion 동작이 자연스럽습니다.
- 사용자에게 보이는 문구가 모든 지원 언어에 추가되었습니다.
- asset 경로가 `assets/` 실제 파일과 `pubspec.yaml` 선언에 맞습니다.
- 보호자 확인이 필요한 구매, 복원, 지원, 개인정보 링크 진입점이 계속 gate 뒤에 있습니다.
- 관련 UI가 작은 화면과 타이머 양방향에서 깨지지 않습니다.
- 위험도에 맞는 테스트가 있거나, 테스트가 불필요한 이유가 명확합니다.
- `flutter analyze`와 관련 `flutter test` 실행 결과 또는 미실행 사유가 남아 있습니다.
