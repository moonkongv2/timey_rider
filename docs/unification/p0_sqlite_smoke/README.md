# P0 SQLite 격리 실험

운영 앱이 import하지 않는 재현 자료다. production schema, 저장 adapter, 이관 코드는 없다.
`probe` 단일 테이블에서 최초 생성 1회, commit, 예외 rollback, close/reopen, integrity_check를 검사한다.
각 실행은 고유 `p0_probe_*.db`만 만들고 finally에서 해당 실험 파일만 삭제한다.

## 재현

Flutter 3.44.1 / Dart 3.12.1에서 실행했다. 원본 저장소 밖의 새 임시 디렉터리를 사용한다.

```sh
P0_DIR=$(mktemp -d /private/tmp/timey-sqlite-p0.XXXXXX)
flutter create --platforms=ios,android --project-name=p0_sqlite_smoke --no-pub "$P0_DIR"
cp docs/unification/p0_sqlite_smoke/pubspec.yaml "$P0_DIR/pubspec.yaml"
cp docs/unification/p0_sqlite_smoke/pubspec.lock "$P0_DIR/pubspec.lock"
cp -R docs/unification/p0_sqlite_smoke/integration_test "$P0_DIR/integration_test"
```

현재 Xcode는 iOS 15 이상만 지원하므로 **임시 프로젝트만** 다음처럼 맞춘다.
이는 운영 앱의 기존 iOS 15 설정과 같다.

```sh
python3 - "$P0_DIR/ios/Runner.xcodeproj/project.pbxproj" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
p.write_text(p.read_text().replace('IPHONEOS_DEPLOYMENT_TARGET = 13.0',
                                 'IPHONEOS_DEPLOYMENT_TARGET = 15.0'))
PY
# Android runner만 기존 앱에서 검증된 도구 버전으로 맞춘다.
python3 - "$P0_DIR/android" <<'PY_ANDROID'
from pathlib import Path
import sys
p = Path(sys.argv[1])
f = p / 'gradle/wrapper/gradle-wrapper.properties'
f.write_text(f.read_text().replace('gradle-9.1.0-all.zip', 'gradle-8.12-all.zip'))
f = p / 'settings.gradle.kts'
f.write_text(f.read_text().replace('version "9.0.1"', 'version "8.9.1"')
             .replace('version "2.3.20"', 'version "2.1.0"'))
f = p / 'app/build.gradle.kts'
f.write_text(f.read_text().replace('id("com.android.application")',
    'id("com.android.application")\n    id("org.jetbrains.kotlin.android")'))
PY_ANDROID
cd "$P0_DIR"
flutter pub get
flutter analyze integration_test --no-pub
flutter devices
flutter test integration_test/sqlite_smoke_test.dart --no-pub -d <simulator-or-emulator-id> --reporter expanded
```

Flutter 3.44.1 생성 template 기준 명령이다. template가 달라지면 위 치환 결과를 확인한다.

선언된 Dart 제약은 앱과 같은 `^3.9.2`다. 다만 의도적으로 기존 Timey와 같은
`synchronized 3.4.0+1`을 고정했으며 실제 의존성 그래프의 하한은 Dart 3.11 이상이다.
현재 Flutter의 integration_test SDK도 필요하다. **Dart 3.9.2 실행 검증 자료가 아니다.**
SQLite wrapper만 고정하면 하위 plugin이 최신판으로 해결될 수 있어 하위 패키지도 고정했다.
`dependency_overrides`는 사용하지 않았다. 앱의 pubspec/lock에는 반영하지 않았다.

결과와 한계는 [P0 보고서](../P0_IMPLEMENTATION_REPORT_KO.md)를 참조한다.
close/reopen은 정상 connection 재열기다. 프로세스 강제 종료, 전원 손실, 미래 schema update,
실제 Timey production dependency graph의 iOS 빌드/실기기 동작을 증명하지 않는다.
