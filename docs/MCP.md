# 홍성용님 PC의 MCP 설치

현재 Codex 설정에 직접 등록된 MCP **8개**를 `mcp/manifest.json`에 기록했습니다. 원격 4개, 로컬 3개, Codex 내장 런타임 1개입니다. 플러그인이 추가로 제공하는 MCP는 플러그인 설치를 통해 복원합니다.

| 이름 | 원본 설정 | 받는 PC에서 필요한 것 |
| --- | --- | --- |
| node_repl | 켜짐 | 받는 PC의 Codex가 자체 런타임을 구성 |
| higgsfield | 켜짐 | 본인 Higgsfield 계정 연결 |
| elevenlabs | 켜짐 | 본인 ElevenLabs 계정 연결 |
| runway | 켜짐 | 본인 Runway 계정 연결 |
| seedance-direct | 켜짐 | Python 3.12·uv·본인 BytePlus API 키 |
| sync | 켜짐 | Node.js·본인 Sync 로그인 또는 API 키 |
| artlist | 켜짐 | 본인 Artlist 계정 연결 |
| rea | 켜짐 | Node.js, 네이티브 분석은 별도 Ghidra·JDK |

## 먼저 확인하기

Windows PowerShell에서 이 저장소 폴더를 열고 실행합니다. `codex` 명령이 PATH에 있어야 합니다. 원본 PC의 `config.toml`을 그대로 덮어쓰지 않습니다.

```powershell
.\scripts\install-mcp.ps1 -DryRun
```

원격 MCP 주소만 등록하려면 아래 명령을 실행합니다. 계정 로그인은 실행하지 않습니다.

```powershell
.\scripts\install-mcp.ps1
```

원격 주소는 기존에 같은 이름이 있으면 건너뜁니다. 누락된 `[mcp_servers.<이름>]` 구역만 추가하고, 기존 설정이 있다면 같은 폴더에 `config.toml.backup-share-날짜-임의문자` 백업을 만듭니다. 먼저 별도 임시 폴더에서 Codex의 TOML 파서로 기존 설정과 후보 설정을 검증합니다. 백업에는 본인 기존 설정이 들어갈 수 있으므로 공유 저장소에 올리지 않습니다.

원격 `codex mcp add`는 OAuth를 바로 시작할 수 있어, 자동 로그인 없이 등록하기 위해 위 4개만 설정 파일 끝에 추가합니다. [Codex 원본 구현](https://github.com/openai/codex/blob/main/codex-rs/cli/src/mcp_cmd.rs)에서 이 동작을 확인할 수 있습니다. 로컬 3개 등록에는 `codex mcp add`를 사용합니다.

## 로컬 MCP도 설치하기

Git, uv, Python용 네트워크 설치, Node.js 및 npm이 필요합니다. Node는 REA 요구사항인 **22.19 이상인 22 버전, 24.11 이상인 24 버전, 또는 26 이상**을 사용합니다. 설치 프로그램은 uv를 통해 Python 3.12 환경을 구성합니다. npm 패키지는 버전을 고정하고 설치 스크립트 실행을 끕니다.

```powershell
.\scripts\install-mcp.ps1 -InstallLocalDependencies -DryRun
.\scripts\install-mcp.ps1 -InstallLocalDependencies
```

기본 설치 위치는 `%USERPROFILE%\.codex\share-mcp`입니다. `CODEX_HOME`을 설정한 PC는 그 폴더 아래 `share-mcp`를 사용합니다. 경로를 바꾸려면 `-InstallRoot 'D:\CodexMcp'`를 덧붙입니다. 이 경우 이후 키 등록 명령도 그 경로를 사용합니다. 기존 Codex MCP 항목 및 기존 래퍼 파일은 덮어쓰지 않습니다. Ark 원본 폴더가 다른 커밋이거나 수정되어 있으면 중단하므로 다른 설치 경로를 선택합니다.

설치되는 공개 원본은 Ark MCP의 고정 커밋 `be4f495bcabeb51ecd3f4221f026feca698a416f`, `@sync.so/mcp-server@0.1.4`, `rea-agents@6.7.0`입니다. 세 프로젝트 모두 MIT로 표시되어 있습니다. Ark는 원본 LICENSE와 uv.lock을 함께 받습니다. Node 최상위 패키지는 버전 고정이며 하위 의존성은 설치 시 npm이 생성하는 lockfile로 보관합니다. REA의 MCP 실행 파일은 배포본에 들어 있으며, 설치 스크립트를 꺼도 기본 실행에 필요한 빌드 파일을 사용합니다. 선택 기능인 Frida 네이티브 바인딩은 설치 스크립트가 필요할 수 있어 이 자동 설치에서 완성된 것으로 보지 않습니다. Ghidra 등 네이티브 도구도 별도 설치합니다.

## 본인 계정 연결

원격 MCP는 Codex 설정 화면에서 연결하거나, 제공사가 OAuth를 지원하면 아래 명령으로 로그인합니다.

```powershell
codex mcp login higgsfield
codex mcp login elevenlabs
codex mcp login runway
codex mcp login artlist
```

서버가 OAuth를 지원하지 않거나 해당 지역·계정에서 거절하면 제공사의 MCP 안내를 따라 본인 인증 수단을 설정합니다. 주소를 등록했다는 사실만으로 인증이나 서비스 이용 권한이 확인되는 것은 아닙니다.

Seedance 키는 받는 PC에서 마스킹 입력으로 OS 자격 증명 저장소에 넣습니다.

```powershell
$seedanceRoot = Join-Path $env:USERPROFILE '.codex\share-mcp\seedance-direct'
& (Join-Path $seedanceRoot 'ark-mcp\.venv\Scripts\python.exe') (Join-Path $seedanceRoot 'setup-key.py')
```

키 등록 도구는 저장만 수행합니다. 키 인증·영상 생성 권한·잔액을 확인하거나 영상을 생성하지 않습니다. API 키가 없으면 Ark의 제공사 도구가 일부 표시되지 않을 수 있습니다. 대안으로 Codex를 실행하는 프로세스가 본인의 `BYTEPLUS_MODELARK_API_KEY` 환경변수를 상속받게 할 수도 있습니다. 키를 GitHub, 채팅, 설정 예제에 넣지 않습니다.

Sync는 키가 없으면 첫 MCP 실행 때 본인 기기 로그인 절차를 제시합니다. 생성되는 `~/.config/sync/mcp-credentials.json`은 받는 사람의 인증 파일입니다. 원본 PC의 인증 파일을 복사하지 않습니다. 본인 `SYNC_API_KEY` 환경변수도 지원합니다.

REA의 Ghidra 분석이 필요하면 별도로 Ghidra와 해당 버전이 요구하는 JDK를 설치한 뒤 새 설치 시 본인 경로를 전달합니다.

```powershell
.\scripts\install-mcp.ps1 -InstallLocalDependencies -GhidraInstallDir 'D:\Tools\ghidra' -JavaHomePath 'C:\Program Files\Java\jdk'
```

기존 `rea` 항목이 있으면 이 명령은 그 환경변수를 바꾸지 않습니다. 이미 등록된 항목은 Codex 설정에서 필요한 경로를 직접 조정합니다. 원본 PC의 Ghidra·Android Studio 경로는 공유하지 않습니다.

설치·로그인이 끝나면 Codex를 재시작하고 새 채팅에서 MCP 도구 제공을 확인합니다. 이 저장소 작성 시 받는 사람의 계정이나 PC에서는 연결을 시험하지 않았습니다.
