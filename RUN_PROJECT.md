# 🏃 다이어리 프로젝트 실행 & 배포 가이드

이 프로젝트는 **AI 일기 생성 서버(Node.js)**와 **모바일 앱(Flutter)**으로 구성된 풀스택 애플리케이션입니다. 현재 서버는 Vercel에 배포되어 있으며, 앱은 로컬 데이터베이스(Hive)를 사용하여 보안과 속도를 동시에 확보했습니다.

---

## 🚀 1. 모바일 앱 실행 (Flutter)

앱 실행 시 `IS_PRO` 플래그를 통해 유료/무료 모드를 전환할 수 있습니다.

### **Step A: 에뮬레이터 실행**
안드로이드 에뮬레이터 또는 iOS 시뮬레이터를 먼저 실행하세요.

### **Step B: 앱 시작**
```bash
cd apps/mobile

# 유료 버전 실행 (AI 생성 기능 전체 개방)
flutter run --dart-define=IS_PRO=true

# 무료 버전 실행 (AI 생성 횟수 제한 모드)
flutter run --dart-define=IS_PRO=false
```

---

## 🌐 2. AI 다이어리 서버 (Express)

AI 분석 및 본문 생성을 담당하는 서버입니다. 현재 실서버에 배포되어 있어 로컬 실행 없이도 앱 사용이 가능합니다.

*   **실서버 주소**: `https://tag-diary-app.vercel.app`
*   **로컬 개발 환경 (필요시)**:
    ```bash
    cd apps/diary-server
    npm run dev
    ```

---

## 🛠 3. 주요 기능 및 설정 안내

### **🎨 사용자 경험 (UX/UI) 상세**
*   **감정별 배경색**: 일기 목록에서 행복, 슬픔, 평온 등 선택한 감정에 따라 카드의 배경색이 파스텔톤으로 자동 변경됩니다.
*   **태그 표시 최적화**: 목록에서는 공간에 맞춰 한 줄로 보여주고, 상세 화면에서는 클릭 시 전체 태그를 펼쳐볼 수 있습니다.
*   **상세 화면 헤더**: 날짜와 뒤로가기 버튼이 겹치지 않게 조절되었으며, 날씨 정보는 별도의 영역에 깔끔하게 표시됩니다.

### **🤖 AI 생성 로직**
*   **자동 문구 연동**: 감정 선택 시 본문에 "😊 행복해요" 같은 문구가 로컬에서 즉시 추가됩니다.
*   **AI 덮어쓰기**: AI 작성을 요청하면 기존 감정 문구 대신 AI가 생성한 고품질의 본문 내용만 저장됩니다.
*   **이미지 분석**: 최신 3장의 사진을 분석하여 일기 내용을 구성합니다.

---

## 📦 4. 빌드 및 배포 가이드

### **안드로이드 APK 생성**

#### **방법 A: 통합 빌드 (Fat APK)**
모든 기기에서 작동하도록 모든 아키텍처를 포함한 하나의 파일을 생성합니다.
```bash
cd apps/mobile
flutter build apk --release --dart-define=IS_PRO=true
```
*   **결과물 위치**: `build/app/outputs/flutter-apk/app-release.apk`

#### **방법 B: 아키텍처별 분할 빌드 (추천 - 용량 최적화)**
각 휴대폰 사양(CPU)에 맞게 파일을 나눠서 용량을 절반 이하로 줄입니다.
```bash
cd apps/mobile
flutter build apk --release --split-per-abi --dart-define=IS_PRO=true
```
*   **결과물 위치**: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (최신폰용)

### **서버 배포 (Vercel)**
GitHub `main` 브랜치에 푸시하면 Vercel이 자동으로 배포를 수행합니다.
```bash
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin main
```

---

## 💡 네트워크 설정 (중요)
현재 앱은 모든 네트워크 요청을 Vercel 실서버(`https://tag-diary-app.vercel.app`)로 보내도록 설정되어 있습니다. 로컬 서버로 테스트하려면 `apps/mobile/lib/features/ai/application/ai_service.dart`의 `baseUrl`을 수정하세요.

---

## ❓ 문제 해결 (Troubleshooting)
1.  **AI 생성 실패**: `diary-server`의 `GEMINI_API_KEY` 환경 변수가 Vercel 설정에 올바르게 입력되었는지 확인하세요.
2.  **데이터 초기화**: 설정 화면의 '데이터 전체 삭제' 기능을 통해 로컬 데이터베이스(Hive)를 초기화할 수 있습니다.
3.  **사진 권한**: 설정 -> 권한 설정에서 저장 공간 접근 권한을 허용해야 사진 추가가 가능합니다.
