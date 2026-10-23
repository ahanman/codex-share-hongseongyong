# 플러그인과 앱 이식 안내

2026-10-23에 로컬 Codex CLI와 플러그인 매니페스트를 대조했다. 플러그인 캐시는 30개이고 `codex plugin list --json`에서 실제 설치·활성화가 확인된 플러그인은 28개다. Google Calendar와 Slack은 캐시와 과거 설정만 남아 있어 설치된 것으로 계산하지 않았다. 정확한 목록과 앱 연결 식별자는 [inventory/plugins.json](../inventory/plugins.json)에 있다.

이 저장소에는 개인 플러그인 6개와 그 안의 스킬 30개를 넣었다. 원본 라이선스와 출처 정보를 함께 보존했다. OpenAI 번들, 기본 런타임, 원격 앱과 ElevenLabs 등 나머지 플러그인 24개의 실행 파일과 내부 스킬은 복사하지 않았다. 해당 제품은 받는 사람의 Codex 설치 및 앱 카탈로그에서 받도록 설치 선택자와 목록을 제공한다. ElevenLabs는 공개된 공식 Git 마켓플레이스에서 다시 설치한다.

## 설치

Codex Desktop/CLI가 설치된 Windows PowerShell에서 저장소 루트로 이동한 다음 실행한다.

```powershell
./scripts/install-plugins.ps1 -DryRun
./scripts/install-plugins.ps1
```

기본 실행은 `hong-codex-share` 마켓플레이스의 개인 플러그인 6개와 ElevenLabs 설치를 시도한다. 현재 계정에서 제공되는 공식 플러그인 21개도 재설치하려면 다음 명령을 사용한다.

```powershell
./scripts/install-plugins.ps1 -IncludeOfficial
```

`-DryRun`을 함께 쓰면 명령과 설치 전후 JSON 상태만 출력한다. 설치된 플러그인은 건너뛰고, 같은 이름의 마켓플레이스가 다른 경로를 사용하면 덮어쓰지 않는다. 실제 변경 전에 기존 `config.toml`을 사용자의 Codex 설정 폴더 아래 `backups/hong-codex-share/`에 백업한다. 승인 정책, 샌드박스, 모델, API 키는 변경하지 않는다. 계정에서 제공되지 않거나 인증이 필요한 공식 플러그인은 오류를 표시하므로 Codex 앱 카탈로그에서 해당 항목을 선택해 연결한다. 이미 설치되어 있지만 꺼져 있는 플러그인도 기존 상태를 유지한다.

공식·외부 서비스 설치 실패는 경고와 JSON의 `failures`에 기록한다. 저장소에 포함된 개인 마켓플레이스 또는 개인 플러그인 설치가 실패하면 JSON 상태를 출력한 뒤 오류를 반환한다. JSON에는 `success`와 `localInstallSucceeded`도 있어 전체 결과와 개인 플러그인 설치 결과를 구분할 수 있다.

Codex CLI의 로컬 도움말에서 확인한 명령 형식은 다음과 같다.

```powershell
codex plugin marketplace add .
codex plugin add impeccable@hong-codex-share
codex plugin marketplace add https://github.com/elevenlabs/plugin.git --ref c7eef3cbcf1ff3ef12066a4e8ea964749d8e94be
codex plugin add elevenlabs@elevenlabs
codex plugin list --json
```

설치 후 Codex를 재시작하거나 새 대화를 열어 스킬과 MCP 도구를 확인한다. 이 저장소를 Git 마켓플레이스로 등록하는 방법도 가능하다. 로컬 경로로 등록했다면 저장소 폴더를 그대로 보관한다.

## 포함된 개인 플러그인

| 플러그인 | 버전 | 스킬 수 | 출처/라이선스 | 준비 사항 |
| --- | --- | ---: | --- | --- |
| Blender | 0.1.0 | 1 | 로컬 래퍼, [mcp-for-blender](https://github.com/ahujasid/mcp-for-blender), MIT | Blender와 MCP 애드온, `uvx`; 서버 2.0.3/Python 3.12, localhost:9876 |
| Emil Kowalski | 0.1.0 | 13 | [emilkowalski/skills](https://github.com/emilkowalski/skills), MIT | 별도 로그인 없음 |
| Google Flow | 0.1.0 | 1 | 개인 브라우저 작업 지침 | Google Flow 이용 권한과 본인 브라우저 로그인 |
| Impeccable | 4.3.1 | 1 | [pbakaus/impeccable](https://github.com/pbakaus/impeccable), Apache-2.0 | 포함된 스킬과 24개 명령 참조 사용 |
| Playwright | 0.1.0 | 1 | 개인 래퍼, [Microsoft MCP](https://github.com/microsoft/playwright-mcp) | Node.js/npm의 `npx`, Chrome; MCP 0.0.82 |
| Taste Skills | 1.0.0 | 13 | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill), MIT | 선택한 개별 스킬의 도구 요구사항 확인 |

플러그인의 개인 PC 실행 경로는 `uvx`와 `npx` 명령 및 상대 경로로 바꿨다. Blender의 선택 실행기는 `-BlenderPath` 또는 `BLENDER_EXECUTABLE`로 실행 파일을 지정할 수 있다. Blender 설치 파일이나 애드온 자체는 이 저장소에 포함하지 않았다. 원본 검토 버전·커밋은 각 플러그인의 `UPSTREAM.json`에 있다.

## 앱과 계정 연결

실제 설치된 플러그인 중 앱 매니페스트가 있는 항목은 10개다. GitHub, Higgsfield, Runway, Figma, Default templates, Pages, Sites, Plugin Management, Pets 및 Spreadsheets가 이에 해당한다. Figma 매니페스트에는 앱 연결과 선택적 런타임 연결 두 항목이 있다. 앱 매니페스트의 존재는 계정 인증 완료를 뜻하지 않는다.

이전 계정의 앱 권한, 구독, API 키, OAuth 토큰, 브라우저 로그인은 전달하지 않는다. 홍성용님의 계정으로 Codex에 로그인하고 사용할 앱을 본인 계정에 연결해야 한다. ElevenLabs도 본인 계정 인증이 필요하다. 조직 정책이나 계정별 제공 여부에 따라 보이는 항목이 다를 수 있다. Google Calendar와 Slack은 캐시만 확인되었으므로 설치 스크립트가 자동 설치하지 않는다.

## 전체 플러그인 목록

아래 `설치`는 CLI에서 확인한 상태이고, `포함`은 이 저장소에 플러그인 파일을 넣었는지를 나타낸다.

| 표시 이름 | 원본 선택자 | 버전 | 설치 | 포함 |
| --- | --- | --- | --- | --- |
| ElevenLabs | `elevenlabs@elevenlabs` | 0.4.0 | 예 | 목록/재설치 안내 |
| Impeccable | `impeccable@personal` | 4.3.1 | 예 | 예 |
| Google Flow (Browser) | `google-flow@personal` | 0.1.0 | 예 | 예 |
| Emil Kowalski Design Skills | `emil-kowalski@personal` | 0.1.0 | 예 | 예 |
| Blender | `blender@personal` | 0.1.0 | 예 | 예 |
| Template Creator | `template-creator@openai-primary-runtime` | 26.1017.22136 | 예 | 목록/재설치 안내 |
| Spreadsheets | `spreadsheets@openai-primary-runtime` | 26.1017.22136 | 예 | 목록/재설치 안내 |
| Presentations | `presentations@openai-primary-runtime` | 26.1017.22136 | 예 | 목록/재설치 안내 |
| PDF | `pdf@openai-primary-runtime` | 26.1017.22136 | 예 | 목록/재설치 안내 |
| Documents | `documents@openai-primary-runtime` | 26.1017.22136 | 예 | 목록/재설치 안내 |
| Pets | `work-pets@openai-curated-remote` | 0.1.6 | 예 | 목록/재설치 안내 |
| Sites | `sites@openai-curated-remote` | 1.1.1 | 예 | 목록/재설치 안내 |
| Plugin Management | `plugin-management@openai-curated-remote` | 0.1.0 | 예 | 목록/재설치 안내 |
| Pages | `pages@openai-curated-remote` | 0.1.25 | 예 | 목록/재설치 안내 |
| Default templates | `openai-templates@openai-curated-remote` | 0.1.1 | 예 | 목록/재설치 안내 |
| GitHub | `github@openai-curated-remote` | 0.1.12-5f7cd798dc99 | 예 | 목록/재설치 안내 |
| Figma | `figma@openai-curated-remote` | 16.0.0 | 예 | 목록/재설치 안내 |
| Higgsfield | `app-6a3293e129088191abf0875820e839da@openai-curated-remote` | 2.2.1 | 예 | 목록/재설치 안내 |
| Runway | `app-6a05e3b201788191be12b590b43e6ce3@openai-curated-remote` | 1.3.1 | 예 | 목록/재설치 안내 |
| Slack | `slack@openai-curated` | 0.1.7 | 캐시만 | 목록/재설치 안내 |
| Google Calendar | `google-calendar@openai-curated` | 1.2.6 | 캐시만 | 목록/재설치 안내 |
| Visualize | `visualize@openai-bundled` | 1.0.55 | 예 | 목록/재설치 안내 |
| unified-computer-use | `unified-computer-use@openai-bundled` | 26.1016.51333 | 예 | 목록/재설치 안내 |
| Computer Use | `computer-use@openai-bundled` | 26.1016.51333 | 예 | 목록/재설치 안내 |
| codex-app-tools | `codex-app-tools@openai-bundled` | 0.1.6 | 예 | 목록/재설치 안내 |
| Code Review | `code-review@openai-bundled` | 26.1016.51333 | 예 | 목록/재설치 안내 |
| Chrome | `chrome@openai-bundled` | 26.1016.51333 | 예 | 목록/재설치 안내 |
| Browser | `browser@openai-bundled` | 26.1016.51333 | 예 | 목록/재설치 안내 |
| Playwright MCP | `playwright@personal` | 0.1.0 | 예 | 예 |
| Taste Skills | `taste-skill@personal` | 1.0.0 | 예 | 예 |
