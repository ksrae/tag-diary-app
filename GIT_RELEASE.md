# Git Release Guide (Standalone Export)

`diary-release` 폴더를 독립적인 Git 저장소로 배포하고 관리하는 가이드입니다.

## 🚀 슬래시 명령을 사용한 자동 배포

Antigravity AI를 통해 다음 명령어로 간편하게 새 리포지토리에 배포할 수 있습니다:

```bash
/git-release [리포지토리_URL]
```

**예시:**
`/git-release https://github.com/sungraekim/my-diary-app.git`

이 명령은 다음 작업을 자동으로 수행합니다:
1. `diary-release` 폴더 내 Git 초기화 (`git init`)
2. 전체 파일 스테이징 및 초기 커밋 (`git add`, `git commit`)
3. 원격 저장소 연결 (`git remote add origin`)
4. 메인 브랜치로 푸시 (`git push -u origin main`)

## 🛠 수동 배포 방법

AI 명령을 사용하지 않고 직접 터미널에서 수행하려면 아래 명령어를 순서대로 입력하세요.

```bash
# 1. 배포용 폴더로 이동
cd diary-release

# 2. Git 초기화
git init

# 3. 파일 추가 및 첫 커밋
git add .
git commit -m "chore: initial standalone release"

# 4. 원격 저장소 연결
# (주의: 이미 remote가 등록되어 있다면 'git remote set-url origin [URL]' 사용)
git remote add origin [리포지토리_URL]

# 5. 푸시
git push -u origin main
```

## ⚠️ 주의사항

- **인증**: `git push` 시 플랫폼(GitHub, GitLab 등)의 인증이 필요할 수 있습니다. 터미널 창에서 로그인을 완료해 주세요.
- **이미 내용이 있는 저장소**: 새로 만든 빈 리포지토리에 배포하는 것을 권장합니다. 기존 내용이 있는 경우 충돌이 발생할 수 있습니다.
- **환경 변수**: 보안을 위해 `.env` 파일은 배포 대상에서 제외되어 있습니다. 배포 후 서버 측에서 `.env.example`을 참고해 직접 생성해 주세요.
