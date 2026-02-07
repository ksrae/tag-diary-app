# AI 일기 앱 (AI Diary App)

AI가 자동으로 일기를 작성해주는 안드로이드 앱입니다.

## 기능

- 📧 이메일 인증 기반 가입
- 📱 기기 데이터 수집 (사진, 메모, 캘린더)
- 🤖 AI 자동 일기 작성 (유료)
- 📅 1년 전 추억 기능
- 🔐 앱 잠금 비밀번호

---

## 빠른 시작

### 사전 요구사항

- [mise](https://mise.jdx.dev/) - 런타임 버전 관리
- [Android Studio](https://developer.android.com/studio) - Android SDK 및 에뮬레이터
- Node.js 20+
- Supabase 계정 (데이터베이스)
- Upstage API 키 (AI 생성)

### 1. 환경 변수 설정

```bash
cd apps/diary-server
cp .env.example .env
```

`.env` 파일을 열어 다음 값들을 입력하세요:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
UPSTAGE_API_KEY=your-upstage-api-key
PORT=3001
```

### 2. 에뮬레이터 실행

```bash
# 사용 가능한 에뮬레이터 목록 확인
mise exec flutter -- flutter emulators

# 에뮬레이터 실행
mise exec flutter -- flutter emulators --launch <EMULATOR_ID>
```

### 3. 앱 실행

#### 방법 1: 한 번에 실행 (권장)

```bash
./scripts/run-diary-app.sh
```

#### 방법 2: 개별 실행

**터미널 1 - 서버:**
```bash
cd apps/diary-server
npm install
npm run dev
# 🚀 Diary server running on http://localhost:3001
```

**터미널 2 - Flutter 앱:**
```bash
cd apps/mobile
mise exec flutter -- flutter run
```

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 모바일 | Flutter 3.22, Riverpod 2.6, go_router 14 |
| 백엔드 | Node.js, Express |
| 데이터베이스 | Supabase (PostgreSQL) |
| AI | Upstage API (Solar Pro) |
| 인증 | 커스텀 이메일 인증 (6자리 코드) |

---

## 프로젝트 구조

```
apps/
├── diary-server/          # Node.js 백엔드
│   ├── src/
│   │   ├── index.js       # 메인 서버
│   │   ├── routes/        # API 라우트
│   │   │   ├── auth.js    # 인증 API
│   │   │   ├── diary.js   # 일기 API
│   │   │   └── ai.js      # AI 생성 API
│   │   └── lib/           # 유틸리티
│   │       ├── supabase.js
│   │       └── upstage.js
│   └── supabase-schema.sql
│
└── mobile/                # Flutter 앱
    └── lib/
        ├── main.dart
        ├── core/          # 공통 설정
        │   └── router/
        └── features/      # 기능별 모듈
            ├── auth/      # 인증
            ├── diary/     # 일기
            └── settings/  # 설정
```

---

## API 엔드포인트

### 인증
| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/auth/signup` | 이메일 가입 (인증 코드 발송) |
| POST | `/auth/verify` | 인증 코드 확인 |
| POST | `/auth/password/set` | 비밀번호 설정 |
| POST | `/auth/password/reset/request` | 비밀번호 초기화 요청 |
| POST | `/auth/password/reset/verify` | 비밀번호 초기화 확인 |

### 일기
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/diaries` | 일기 목록 (페이지네이션) |
| GET | `/diaries/:id` | 일기 상세 |
| POST | `/diaries` | 일기 작성 |
| PATCH | `/diaries/:id` | 일기 수정 (하루 3회 제한) |
| DELETE | `/diaries/:id` | 일기 삭제 |
| GET | `/diaries/year-ago` | 1년 전 오늘 일기 |

### AI
| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/ai/generate` | AI 일기 생성 (유료) |
| POST | `/ai/regenerate` | AI 일기 재생성 |

---

## 문제 해결

### Flutter 빌드 오류

```bash
# 캐시 초기화
cd apps/mobile
mise exec flutter -- flutter clean
mise exec flutter -- flutter pub get
mise exec flutter -- dart run build_runner build --delete-conflicting-outputs
```

### 에뮬레이터가 안 보일 때

```bash
# 에뮬레이터 새로 생성
mise exec flutter -- flutter emulators --create --name Pixel_7

# 또는 Android Studio에서 생성
# Tools → Device Manager → Create Device
```

### 서버 연결 오류 (에뮬레이터)

에뮬레이터에서 `localhost`는 에뮬레이터 자체를 가리킵니다.
호스트 머신의 서버에 접속하려면 `10.0.2.2`를 사용하세요.

---

## 라이선스

MIT
