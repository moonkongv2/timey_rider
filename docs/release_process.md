# Release Process

## Version policy

- 사용자 버전: `major.minor.patch`
- 스토어에 빌드를 업로드할 때마다 build number를 1 증가한다.
- Android와 iOS의 build number는 동일하게 유지한다.
- 첫 출시 전에는 `1.0.0`을 유지한다.
- 버그 수정 출시: `1.0.1`
- 기능 추가 출시: `1.1.0`

## Build examples

- `1.0.0+1`: 최초 내부 테스트
- `1.0.0+2`: IAP 테스트 빌드
- `1.0.0+3`: 스토어 심사 제출
- `1.0.0+4`: 심사 대응 수정

## Release commands

```bash
flutter test
flutter analyze
flutter build appbundle --release
flutter build ipa --release
