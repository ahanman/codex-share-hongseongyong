# 홍성용 님을 위한 Codex 공유 패키지

기존 Codex 환경의 플러그인·앱 연결 목록, MCP 설정, 사용자 스킬을 다른 PC에서 재설치하기 위한 공개 저장소입니다. 기준일: **2026-10-23 (한국 시간)**. 원본 PC의 설정은 수정하지 않고 별도 복사본을 만들었습니다.

스냅샷: **설치·활성 플러그인 28개**, **사용자 스킬 293개**, **직접 등록 MCP 8개**. 파일로 제공하는 개인 플러그인은 6개이며, 그 안의 스킬 30개도 포함됩니다. MCP 8개에는 대상 Codex가 자체 구성하는 `node_repl` 1개가 포함됩니다.

## 빠른 설치 (Windows PowerShell)

먼저 홍성용 님 계정으로 Codex에 로그인하고, Git과 `codex` 명령을 사용할 수 있는지 확인합니다.

```powershell
git clone https://github.com/ahanman/codex-share-hongseongyong.git
cd codex-share-hongseongyong
powershell -ExecutionPolicy Bypass -File .\Install.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\Install.ps1
```

기본 설치는 사용자 스킬 복사, 공유 가능한 개인 플러그인 설치, 외부 플러그인 재설치 시도, 원격 MCP 등록을 진행합니다. 이미 존재하는 항목은 각 설치 스크립트의 충돌 처리 규칙을 따릅니다. 원본 PC의 계정·인증·권한 설정은 가져오지 않습니다. 완료 후 Codex를 완전히 종료했다가 다시 실행합니다.

로컬 MCP 의존성까지 설치하려면 Python/uv와 Node.js 등 필요한 프로그램을 준비한 뒤 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\Install.ps1 -IncludeLocalMcp
```

구성요소별 선택 설치도 가능합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-skills.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\install-plugins.ps1 -IncludeOfficial
powershell -ExecutionPolicy Bypass -File .\scripts\install-mcp.ps1
```

## 포함 범위

| 항목 | 공유 방법 | 상세 안내 |
| --- | --- | --- |
| 사용자 스킬 | 문서·스크립트·참조 파일과 출처/라이선스 포함 | [스킬 안내](docs/SKILLS.md), [목록](inventory/skills.json) |
| 개인 플러그인 | 이 저장소의 `hong-codex-share` 마켓플레이스에서 설치 | [플러그인 안내](docs/PLUGINS.md) |
| 공식·외부 플러그인 | 설치 상태·버전·출처 및 재설치 명령 제공 | [전체 플러그인 목록](inventory/plugins.json) |
| 앱 연결 | 플러그인의 앱 바인딩 목록 제공, 대상 계정으로 다시 연결 | [플러그인 안내](docs/PLUGINS.md) |
| MCP | 비밀정보를 제거한 설정 예시, 원격 등록/로컬 설치 스크립트 | [MCP 안내](docs/MCP.md), [설정 예시](mcp/config.template.toml) |
| Codex 기본 기능 | 현재 세션의 도구 표면 목록, 대상 Codex에서 제공되는 기본 기능 사용 | [런타임 목록](inventory/runtime-capabilities.json) |

설치 캐시와 실제 설치·활성 상태는 다를 수 있어 목록에서 구분했습니다. Codex 기본 제공 스킬·런타임과 재배포가 제한된 공식 플러그인 파일은 원본 제공 경로에서 설치하도록 구성했습니다. 캐시 전체를 복제하는 방식이 아닙니다.

## 홍성용 님이 직접 연결할 항목

Codex 플러그인 화면에서 GitHub, Figma, ElevenLabs, Higgsfield, Runway 등 필요한 앱을 본인 계정으로 설치·연결합니다. 공급자의 계정, 요금제, 조직 정책에 따라 사용 가능 여부가 달라질 수 있습니다. 원격 MCP는 등록 후 `codex mcp login <이름>` 또는 해당 공급자 안내를 따릅니다. BytePlus와 Sync 등 API 키가 필요한 서비스에는 본인의 키를 사용합니다.

OAuth 토큰, API 키, `auth.json`, 대화 기록, 메모리, 작업 결과물, 브라우저 프로필, Windows 자격 증명은 포함하지 않았습니다. 이 저장소만으로 다른 사람의 로그인이나 유료 서비스 사용 권한이 이전되지는 않습니다.

## 검증과 출처

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-package.ps1
```

`SHA256SUMS`는 배포 파일의 누락·변경을 확인합니다. 설치 전 검증을 통과해야 합니다. 개별 구성요소는 원 저작자의 라이선스를 유지합니다. [라이선스 안내](THIRD_PARTY_NOTICES.md)를 확인해 주세요.

공유본에서 수행한 검증 범위는 [검증 기록](docs/VALIDATION.md)에 정리했습니다. 홍성용 님 계정의 OAuth 로그인, 유료 API 호출, 대상 PC의 로컬 프로그램 실행은 이 준비 과정에서 수행하지 않았습니다.

설치 형식은 [공식 플러그인 패키징 문서](https://developers.openai.com/plugins/build/plugins)와 원본 PC에서 확인한 `codex plugin add --help`, `codex mcp add --help`를 기준으로 작성했습니다. 기준 Codex CLI는 `0.163.0-alpha.11`이며, 다른 버전에서는 CLI·앱 화면의 지원 범위를 확인해야 합니다.

