# 🚀 새로운 프로젝트 시작 가이드

이 가이드는 `fullstack-starter` 템플릿을 사용하여 **완전히 새로운 프로젝트**를 시작할 때 필요한 모든 단계를 순서대로 설명합니다.

## 1. 프로젝트 생성 (폴더 만들기)

터미널에서 새로운 프로젝트 폴더를 만들고 해당 위치로 이동합니다.

```bash
# 'my-new-app' 부분에 원하는 프로젝트 이름을 입력하세요
git clone https://github.com/first-fluke/fullstack-starter.git my-new-app
cd my-new-app
```

> **참고:** 기존 `.git` 기록을 지우고 새로 시작하려면:
> ```bash
> rm -rf .git
> git init
> ```

## 2. 의존성 설치

프로젝트에 필요한 라이브러리와 도구들을 한 번에 설치합니다.

```bash
mise run install
```

## 3. 환경 변수 설정

기본 설정 파일(`example`)을 복사하여 실제 설정 파일(`.env`)을 만듭니다.

```bash
# API 설정을 복사
cp apps/api/.env.example apps/api/.env

# Web 설정을 복사
cp apps/web/.env.example apps/web/.env
```

## 4. 로컬 인프라 실행 (DB, Redis 등)

Docker를 이용해 데이터베이스와 필요한 서비스를 실행합니다.
**주의:** Docker Desktop이 켜져 있어야 합니다.

```bash
mise infra:up
```

> **에러 발생 시 확인사항:**
> *   `docker` 명령어를 찾을 수 없다면? → Docker Desktop을 실행하세요.
> *   포트 충돌(5432) 에러? → 로컬의 다른 Postgres를 끄세요 (`brew services stop postgresql`).

## 5. 데이터베이스 초기화 (마이그레이션)

데이터베이스 테이블을 생성합니다.

```bash
mise db:migrate
```

## 6. 개발 서버 실행

모든 준비가 끝났습니다! 이제 개발 서버를 켭니다.

```bash
mise dev
```

---

## ✅ 확인하기

브라우저에서 다음 주소로 접속해 보세요.

*   **웹 사이트:** [http://localhost:3000](http://localhost:3000)
*   **API 문서:** [http://localhost:8000/docs](http://localhost:8000/docs)
