# 🏃 프로젝트 실행 가이드 (재부팅 후 필수 체크)

이 가이드는 시스템 재부팅 후 또는 매일 프로젝트를 시작할 때 **백엔드 서버**, **다이어리 서버**, 그리고 **모바일 앱**을 각각 개별적으로 실행하는 가장 안정적인 방법을 설명합니다.

---

## 0. 시작 전 필수 체크 (최초 1회)

터미널에서 `mise` 명령어를 찾을 수 없다면 설정을 먼저 반영해야 합니다.
```bash
source ~/.zshrc
```

또한, **Docker Desktop**이 실행 중인지 반드시 확인하세요. (데이터베이스 실행을 위해 필수)

---

## 1. 터미널 1: 백엔드 API 서버 (FastAPI)

백엔드는 데이터베이스와 함께 로컬 인프라 위에서 돌아갑니다.

### **Step A: 로컬 인프라(DB, Redis) 실행**
```bash
# 프로젝트 루트에서 실행
mise run infra:up
```

### **Step B: 백엔드 서버 시작**
```bash
cd apps/api
mise run dev
```
> **참고:** 에뮬레이터 접속을 위해 내부적으로 `0.0.0.0:8000`으로 실행됩니다.

---

## 2. 터미널 2: 다이어리 서버 (Express)

AI 분석 및 다이어리 관리를 위한 Node.js 서버입니다.

```bash
cd apps/diary-server
npm run dev
```
> **주의:** 이 서버가 실행되지 않으면 앱에서 다이어리 목록을 불러올 때 통신 오류(Timeout)가 발생할 수 있습니다.

---

## 3. 터미널 3: 모바일 앱 (Flutter)

반드시 안드로이드 에뮬레이터나 iOS 시뮬레이터가 먼저 켜져 있어야 합니다.

### **Step A: 에뮬레이터 실행**
*   **Android Studio**의 Device Manager에서 원하는 기기(예: 갤럭시 S24)를 실행하세요.
*   에뮬레이터가 정상적으로 켜졌는지 확인:
    ```bash
    ~/Library/Android/sdk/platform-tools/adb devices
    ```

### **Step B: Flutter 앱 시작**
```bash
cd apps/mobile

# 일반 실행
flutter run

# 무료 버전 실행 (AI 기능 제한 모드)
flutter run --dart-define=IS_PRO=false

# 유료 버전 실행 (AI 기능 전체 모드)
flutter run --dart-define=IS_PRO=true
```

---

## 4. 모바일 앱 빌드 가이드 (APK 생성)

배포용 APK를 생성할 때 용량 최적화 수준에 따라 두 가지 방법을 선택할 수 있습니다.

### **방법 A: 통합 빌드 (Fat APK)**
모든 아키텍처(arm, arm64, x86)용 바이너리를 하나의 파일에 합친 방식입니다. 설치 파일 하나로 모든 기기에서 작동하지만 용량이 매우 큽니다.
```bash
cd apps/mobile
flutter build apk --release --dart-define=IS_PRO=true
```

### **방법 B: 아키텍처별 분할 빌드 (추천 - 용량 최소화)**
각 CPU 아키텍처(ABI)별로 최적화된 APK를 따로 생성합니다. 필요한 바이너리만 포함되므로 **용량이 절반 이하로 줄어듭니다.**
```bash
cd apps/mobile
flutter build apk --release --split-per-abi --dart-define=IS_PRO=true
```
*   **결과물 위치:** `build/app/outputs/flutter-apk/`
*   **파일명 예시:** `app-arm64-v8a-release.apk` (최신 안드로이드 폰용)

### **방법 C: 스토어 출시용 빌드 (App Bundle - 강력 추천)**
구글 플레이 스토어에 실제로 배포할 때는 APK가 아닌 **App Bundle (.aab)** 형식을 사용해야 합니다. 구글 서버가 기기에 맞춰 최적화된 APK를 생성해주므로 유저가 다운로드할 때 **용량이 최소화**됩니다.
```bash
cd apps/mobile
flutter build appbundle --release --dart-define=IS_PRO=true
```
*   **결과물 위치:** `build/app/outputs/bundle/release/app-release.aab`
*   **장점:** 플레이 스토어 배포 시 필수 사양이며, 모든 최적화 기술이 집약됨.

---

## 💡 네트워크 설정 참고 (중요)

안드로이드 에뮬레이터에서 컴퓨터의 로컬 서버에 접속할 때는 `localhost` 대신 다음 주소를 사용하도록 설정되어 있습니다:
*   **FastAPI 백엔드**: `http://10.0.2.2:8000`
*   **다이어리 서버**: `http://10.0.2.2:3001`

---

## 🛠 기타 유용한 명령어

### **데이터베이스 초기화 (필요시)**
```bash
mise run db:migrate
```

---

## ❓ 문제가 발생하면?

1.  **Connection Timeout**: 다이어리 서버(터미널 2)가 실행 중인지 확인하세요.
2.  **Address already in use**: `lsof -i :8000` 또는 `lsof -i :3001`로 확인 후 프로세스를 종료하세요.
3.  **mise: command not found**: `source ~/.zshrc`를 입력하세요.

---

## 5. Git 배포

코드 변경 후 GitHub에 푸시하면 Vercel이 자동으로 배포합니다.

### **모든 변경사항 커밋 & 푸시**
```bash
# 프로젝트 루트에서 실행
git add -A
git commit -m "feat: 변경 내용 설명"
git push origin main
```

### **특정 파일만 커밋**
```bash
git add apps/diary-server/
git commit -m "fix: diary server bug fix"
git push origin main
```

---

## 6. Vercel 배포 (다이어리 서버)

Vercel과 GitHub이 연결되어 있으면 `main` 브랜치에 푸시할 때마다 자동 배포됩니다.

### **Vercel 설정 (최초 1회)**
1. [Vercel Dashboard](https://vercel.com) → New Project
2. GitHub 저장소 연결
3. 설정:
   - **Framework Preset**: Express
   - **Root Directory**: `apps/diary-server`
4. **Environment Variables**:
   - `GEMINI_API_KEY`: Gemini API 키
   - `NODE_ENV`: `production`

### **수동 배포 (Vercel CLI)**
```bash
cd apps/diary-server
npx vercel --prod
```

### **배포 후 모바일 앱 URL 업데이트**
Vercel 배포 URL을 받으면 `apps/mobile/lib/features/ai/application/ai_service.dart`에서 서버 URL을 업데이트하세요.
