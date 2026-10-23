# 스킬 설치

사용자 스킬 293개를 포함합니다. `skills/codex/`에는 292개, `skills/agents/`에는 `reverse-engineer-anything` 1개가 있습니다. 각 스킬의 설명, 스크립트, 참조 자료, 자산을 함께 보존했습니다. 플러그인이 제공하는 스킬은 플러그인 설치 안내를 따라 설치합니다.

저장소 루트의 PowerShell에서 먼저 설치 내용을 확인합니다.

```powershell
.\scripts\install-skills.ps1 -DryRun
```

설치합니다. 기본 위치는 현재 사용자의 `~/.agents/skills`입니다. 같은 이름이 이미 있으면 건너뜁니다.

```powershell
.\scripts\install-skills.ps1
```

다른 위치를 사용할 때는 `-TargetRoot`를 지정합니다. 기존 스킬을 교체하려면 `-Force`를 지정합니다. 교체되는 기존 디렉터리는 설치 대상의 부모 아래 `skills-backups/<실행 시각>/`에 먼저 백업합니다.

```powershell
.\scripts\install-skills.ps1 -TargetRoot "$env:USERPROFILE\.codex\skills" -DryRun
.\scripts\install-skills.ps1 -Force
```

설치 스크립트는 변경 전에 모든 스킬의 파일 개수와 SHA-256을 `inventory/skills.json`과 대조합니다. 설치 후 Codex를 다시 열어 스킬 목록을 새로 불러오세요. 스킬별 Python·Node·외부 도구 의존성은 해당 `SKILL.md`와 포함된 요구사항 파일을 따릅니다. 이 설치 과정에서는 스킬에 포함된 실행 파일이나 스크립트를 실행하지 않습니다.

원래 Codex의 `.system`에 있는 `imagegen`, `openai-docs`, `review-agent`, `skill-creator`, `skill-installer` 5개는 인벤토리에 기록했습니다. 해당 파일은 배포하지 않으며, 받는 사람의 Codex가 제공하는 기본 스킬을 사용합니다.

로컬 원본은 그대로 두고 배포본을 복사했습니다. 계정 인증, 개인 대화·메모리, API 키, 로그 및 실행 캐시는 포함하지 않았습니다. 내보낸 사용자 스킬에서 알려진 실제 토큰 서명, 개인 키 및 원래 사용자의 절대 경로는 발견되지 않았으며, 스킬 내용의 추가 치환은 하지 않았습니다.

스킬 원본과 라이선스 정보는 [licenses/skills/README.md](../licenses/skills/README.md)에 있습니다.
