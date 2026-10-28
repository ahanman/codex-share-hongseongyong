# 받는 분을 위한 설치·사용 안내

이 문서는 다른 사람에게 받은 스킬 293개를 본인의 Codex에 설치하고 사용하는 방법입니다. 2026-10-28(한국 시간)에 설치본과 배포본이 같은지 확인했습니다.

## 1. GitHub에 들어가기

브라우저에서 [공유 저장소 열기](https://github.com/ahanman/codex-share-hongseongyong)를 누릅니다. 공개 저장소이므로 열람·다운로드에는 GitHub 로그인이 필요하지 않습니다.

- 첫 화면의 README에서 설치 요약을 읽습니다.
- `docs/SKILL-CATALOG.md`를 누르면 293개 스킬의 이름·설명·원문 링크를 볼 수 있습니다.
- 직접 내려받으려면 초록색 **Code → Download ZIP**을 누르고 압축을 풉니다. Git을 사용한다면 README의 `git clone` 명령으로 복사합니다.

## 2. Codex에 설치를 맡기기

자신의 계정으로 Codex에 로그인하고 작업할 로컬 폴더를 엽니다. 새 대화에 아래 내용을 붙여 넣습니다.

```text
https://github.com/ahanman/codex-share-hongseongyong 의 README와
docs/START-HERE.ko.md, 스킬 설치 스크립트를 먼저 검토해줘.
공개 저장소를 내려받고, 내 운영체제에 맞는 스킬 전용 설치기로
사용자 스킬 293개를 ~/.agents/skills 에 설치해줘.
이미 같은 이름이 있는 스킬은 덮어쓰지 말고 건너뛰어줘.
이번에는 플러그인·MCP·외부 프로그램 설치나 계정 설정 변경은 하지 말아줘.
설치된 개수, 건너뛴 개수, 실제 설치 경로를 확인해서 알려줘.
설치 후 사용할 명령 예시도 3개 알려줘.
```

설치 경로는 Windows에서 `C:\Users\본인계정\.agents\skills`, Mac·Linux에서 `~/.agents/skills`입니다. 이 저장소의 스킬 전용 설치기는 같은 이름이 있으면 기본적으로 보존합니다. 설치기가 스킬에 포함된 코드를 실행하거나 API를 호출하지는 않습니다.

회사 관리 환경이나 읽기 전용 환경에서는 파일 쓰기·네트워크 권한에 따라 설치가 제한될 수 있습니다. Codex가 권한을 요청하면 작업 내용과 대상 경로를 확인해 처리합니다.

## 3. 터미널에서 직접 설치하기

[README의 운영체제별 명령](../README.md#스킬만-직접-설치)을 사용하세요. ZIP으로 받은 경우 `git clone`은 생략하고 압축을 푼 저장소 폴더에서 실행합니다. Windows에서는 Python이 없어도 PowerShell 설치기를 사용할 수 있습니다. Mac·Linux용 설치기는 Python 3.9 이상이 필요합니다.

전체 대신 한 스킬만 설치할 수도 있습니다. 저장소 폴더에서 다음을 실행합니다.

```bash
python3 scripts/install-skills.py --skill react-patterns --dry-run
python3 scripts/install-skills.py --skill react-patterns
```

Codex에 한 스킬만 요청하려면 다음처럼 경로를 지정합니다.

```text
$skill-installer https://github.com/ahanman/codex-share-hongseongyong/tree/main/skills/codex/react-patterns
의 react-patterns 스킬을 ~/.agents/skills 에 설치해줘.
기존 스킬이 있으면 그대로 보존해줘.
```

## 4. 설치가 인식됐는지 확인하기

설치 후 다음 메시지를 보냅니다.

```text
내 사용자 스킬 경로 ~/.agents/skills 를 확인해줘.
react-patterns, security-review, python-patterns 스킬이 설치되어 있고
이번 대화에서 사용할 수 있는지 확인해줘.
```

스킬이 표시되지 않으면 Codex를 완전히 종료했다가 다시 엽니다. CLI·IDE에서 제공되는 경우 `/skills` 또는 `$` 입력으로 목록을 확인할 수도 있습니다. 설치 수가 많으면 아래 전체 목록에서 정확한 이름을 찾아 지정하세요.

## 5. 실제 작업에 사용하기

작업할 프로젝트 폴더를 연 뒤 `$스킬이름`과 구체적인 요청을 함께 보냅니다. `$`는 그대로 입력합니다.

| 하고 싶은 작업 | Codex에 보낼 내용 |
| --- | --- |
| React 코드 개선 | `$react-patterns 이 프로젝트의 React 컴포넌트 구조를 검토하고 개선해줘.` |
| 프런트엔드 구현 | `$frontend-patterns 검색과 필터가 있는 상품 목록 화면을 만들어줘.` |
| Python 코드 개선 | `$python-patterns 이 프로젝트의 Python 코드를 읽고 중복과 예외 처리를 개선해줘.` |
| 보안 검토 | `$security-review 로그인·권한 검사·입력 검증 코드를 검토하고 발견한 문제를 설명해줘.` |
| 코드 구조 설명 | `$codebase-onboarding 이 저장소의 구조와 실행 방법을 처음 보는 개발자에게 설명해줘.` |
| 스킬 자동 선택 | `이번 작업에 맞는 설치된 스킬을 골라 사용해줘. 사용한 스킬 이름도 알려줘.` |

스킬은 Codex가 일을 수행할 때 참고하는 절차와 자료입니다. 파일을 설치했다고 관련 외부 서비스나 프로그램까지 생기는 것은 아닙니다. 예를 들어 브라우저 자동화·Blender·Figma·ElevenLabs 관련 작업에는 각 도구나 플러그인, 본인 계정 연결이 필요할 수 있습니다. 필요한 경우 [플러그인 안내](PLUGINS.md)와 [MCP 안내](MCP.md)를 따릅니다.

## 공유할 때 그대로 보낼 메시지

```text
Codex 스킬 293개 공유 링크야.
https://github.com/ahanman/codex-share-hongseongyong

GitHub 계정 없이 볼 수 있어.
링크의 README에서 '가장 쉬운 설치' 내용을 네 Codex에 붙여 넣으면 돼.
설치하고 나서는 '$react-patterns 이 프로젝트의 React 코드를 개선해줘'처럼
$스킬이름과 원하는 작업을 같이 입력해서 사용하면 돼.
전체 스킬 목록과 Windows·Mac 설치법도 링크 안에 있어.
```

공식 동작 설명: [OpenAI 스킬 문서](https://learn.chatgpt.com/docs/build-skills). 원본 저작자와 라이선스는 [원저작물 고지](../THIRD_PARTY_NOTICES.md)에 있습니다.
