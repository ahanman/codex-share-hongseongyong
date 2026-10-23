# 스킬 출처와 라이선스

이 디렉터리의 라이선스는 해당 원저작물에 적용됩니다. 배포 저장소의 자체 문서·설치 도구와 각 제3자 스킬의 라이선스를 구분해서 확인하세요. 스킬 내부의 저작자, 출처, 라이선스 표시는 그대로 보존했습니다.

| 배포 범위 | 원본 | 확인한 참조 | 라이선스 파일 |
| --- | --- | --- | --- |
| `skills/codex/`의 292개 사용자 스킬 | [affaan-m/ECC](https://github.com/affaan-m/ECC), 종전 이름 `everything-claude-code` | `90606c8315ee09cafc303515c5f33024db6b9882` | [ECC-MIT.txt](ECC-MIT.txt) |
| Apache-2.0을 명시한 아래 8개 스킬 | ECC의 해당 스킬 및 보존된 작성자 메타데이터 | 각 `SKILL.md`의 `license`, `author`, `homepage` | [Apache-2.0.txt](Apache-2.0.txt) |
| `skills/agents/reverse-engineer-anything/` | [morluto/rea](https://github.com/morluto/rea) | `6c4d880f2dd9ca7d42593be916f90ec19b8a09d7` | [REA-MIT.txt](REA-MIT.txt) |

Apache-2.0 명시 스킬: `carrier-relationship-management`, `customs-trade-compliance`, `energy-procurement`, `inventory-demand-planning`, `logistics-exception-management`, `production-scheduling`, `quality-nonconformance`, `returns-reverse-logistics`. 이들의 작성자 표시는 `evos`이며 원본에 보존되어 있습니다.

`taste-application/scripts/LICENSE`는 원본 MIT 전문을 그대로 보존했습니다. `react-performance/SKILL.md`에는 Vercel Engineering의 MIT 원저작물에 대한 출처와 저작권 표시가 있으며 그대로 보존했습니다. 그 밖의 커뮤니티 출처·기여자 표시는 개별 스킬의 메타데이터와 본문에 있습니다.

2026-10-23에 위 공개 원본을 확인했습니다. 292개 사용자 스킬 모두 ECC의 같은 경로에 존재합니다. 로컬 `SKILL.md` 205개는 확인한 참조의 Git blob과 정확히 일치하고, 87개는 다릅니다. 배포 내용은 이 컴퓨터에 설치된 로컬 스냅샷이며, 현재 upstream의 완전한 복제본이라는 뜻은 아닙니다. 파일별 SHA-256과 upstream 비교 결과는 `inventory/skills.json`에 기록했습니다. 이 내보내기에서는 스킬 내용을 수정하지 않았습니다.

ECC upstream 트리에는 배포한 범위의 별도 `NOTICE` 파일이 없었습니다. 시스템 기본 스킬과 플러그인 관리 스킬은 이 293개 파일 묶음에 포함되지 않습니다.
