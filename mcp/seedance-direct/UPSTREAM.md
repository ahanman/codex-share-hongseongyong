# Seedance 직접 MCP 설치 원본

- 원본: https://github.com/byteplus-sa/ark-mcp
- 커밋: `be4f495bcabeb51ecd3f4221f026feca698a416f`
- 라이선스: upstream MIT. 설치 시 원본 저장소의 LICENSE를 함께 받습니다.
- Python: 3.12 이상. 원본 `uv.lock`을 `uv sync --frozen --no-dev --python 3.12`로 사용합니다.
- OS 키 저장 의존성: `keyring==25.7.0`.

원본 소스와 Python 가상환경을 이 GitHub 저장소에 중복 업로드하지 않습니다. `scripts/install-mcp.ps1 -InstallLocalDependencies`가 위 커밋을 새 PC에 내려받아 설치합니다. 실행 진입점은 이 폴더의 `launch.py`이며, 원본과 같은 Seedance 모델·API 주소를 기본값으로 사용합니다.

`setup-key.py`는 입력을 화면에 표시하지 않고 받는 사람의 OS 자격 증명 저장소에 넣습니다. 키의 유효성·요금·영상 생성 권한 검증은 수행하지 않습니다. 원본 PC의 키, 키 저장소, 작업 내역, 휴대폰 연결 상태는 포함하지 않습니다.
