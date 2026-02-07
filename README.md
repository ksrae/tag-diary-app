# 📔 AI Tag Diary (AI 태그 다이어리)

사용자의 하루를 자동으로 기록하고 AI가 일기 작성을 도와주는 스마트 다이어리 플랫폼입니다.

## 🚀 프로젝트 소개
AI 태그 다이어리는 사용자의 기분, 태그뿐만 아니라 **날씨 정보, 건강 정보(걸음 수, 칼로리 등), 그리고 오늘 찍은 사진**을 종합하여 나만의 특별한 일기를 기록할 수 있게 도와줍니다. 특히 유료(Pro) 버전에서는 **AI**를 활용하여 수집된 데이터를 바탕으로 다양한 스타일의 일기를 자동으로 생성해 줍니다.

## 🛠 주요 기능
- **🤖 AI 일기 생성**: Gemini AI를 통해 SNS 스타일, 시, 편지 등 원하는 스타일로 일기 자동 작성 (Pro 기능)
- **🏷️ 스마트 태그 & 기분**: 자주 쓰는 태그 추천 및 기분 선택 시 자동 문구 삽입
- **📊 데이터 통합**: 현재 위치 기반 날씨 정보와 건강 앱(Apple Health/Google Fit) 연동
- **📸 갤러리 연동**: 오늘 찍은 사진을 자동으로 불러오고 일기에 포함

## 📂 프로젝트 구조
프로젝트는 모노레포(Monorepo) 형식으로 구성되어 있습니다.

- **`apps/mobile`**: Flutter 기반의 크로스 플랫폼 모바일 애플리케이션 (iOS/Android)
- **`apps/diary-server`**: Node.js Express 기반의 AI 프록시 서버 (Vercel 배포)
- **`apps/api`**: FastAPI/PostgreSQL 기반의 메인 백엔드 서버

## 💻 기술 스택
- **Frontend**: Flutter, Riverpod, PhotoManager
- **Backend (AI Proxy)**: Node.js, Express
- **Backend (Main)**: Python, FastAPI, SQLAlchemy, PostgreSQL
- **Deployment**: Vercel (AI Server), GitHub Actions (CI/CD)

## 🏗 시작하기
전체 프로젝트 실행 방법은 [RUN_PROJECT.md](./RUN_PROJECT.md) 가이드를 참고해 주세요.

---
© 2026 AI Tag Diary Team.
