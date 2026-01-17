# GCP 프로젝트 마이그레이션 가이드

이 문서는 GCP 프로젝트를 새로운 프로젝트로 이전하는 전체 과정을 정리합니다.

## 📋 마이그레이션 체크리스트

### Phase 1: 사전 준비
- [ ] 새 GCP 프로젝트 생성
- [ ] 필요한 API 활성화 (아래 목록 참조)
- [ ] Terraform으로 인프라 구성 (`terraform apply`)
- [ ] Cloud SQL 인스턴스 및 DB 생성

### Phase 2: 데이터 마이그레이션
- [ ] Cloud SQL 데이터베이스 덤프 및 복원
- [ ] GCS 버킷 데이터 복사 (prod, backup)
- [ ] 컨테이너 이미지 이전 (api, web)

### Phase 3: 설정 변경
- [ ] GitHub Secrets 업데이트
- [ ] 소스 코드 설정 변경 (`config.py` 등)
- [ ] Terraform 환경변수 변경

### Phase 4: 배포 및 검증
- [ ] Terraform apply
- [ ] GitHub Actions 배포 테스트
- [ ] API/Web 엔드포인트 테스트

---

## 🔧 필요한 API 목록

새 프로젝트에서 활성화해야 할 API들:

```bash
gcloud services enable \
  sqladmin.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  cloudtasks.googleapis.com \
  pubsub.googleapis.com \
  storage.googleapis.com \
  compute.googleapis.com \
  vpcaccess.googleapis.com \
  aiplatform.googleapis.com \
  --project=NEW_PROJECT_ID
```

---

## 1️⃣ 데이터베이스 마이그레이션

### Cloud SQL Export (기존 프로젝트)

```bash
# 기존 프로젝트의 Cloud SQL 서비스 계정에 버킷 권한 부여
OLD_SA=$(gcloud sql instances describe OLD_INSTANCE \
  --project=OLD_PROJECT --format="value(serviceAccountEmailAddress)")

gcloud storage buckets add-iam-policy-binding gs://MIGRATION_BUCKET \
  --member="serviceAccount:$OLD_SA" \
  --role="roles/storage.objectAdmin"

# DB 덤프 생성
gcloud sql export sql OLD_INSTANCE gs://MIGRATION_BUCKET/dump.sql \
  --database=pic2cook \
  --project=OLD_PROJECT
```

### Cloud SQL Import (새 프로젝트)

```bash
# 새 프로젝트의 Cloud SQL 서비스 계정에 버킷 권한 부여
NEW_SA=$(gcloud sql instances describe NEW_INSTANCE \
  --project=NEW_PROJECT --format="value(serviceAccountEmailAddress)")

gcloud storage buckets add-iam-policy-binding gs://MIGRATION_BUCKET \
  --member="serviceAccount:$NEW_SA" \
  --role="roles/storage.objectViewer"

# DB Import
gcloud sql import sql NEW_INSTANCE gs://MIGRATION_BUCKET/dump.sql \
  --database=pic2cook \
  --user=postgres \
  --project=NEW_PROJECT
```

### 직접 Import (psql 사용)

Private IP 인스턴스의 경우 Public IP를 임시 활성화하거나 Cloud SQL Proxy 사용:

```bash
# Public IP 활성화
gcloud sql instances patch NEW_INSTANCE --assign-ip --project=NEW_PROJECT

# IP 승인
MY_IP=$(curl -s ifconfig.me)
gcloud sql instances patch NEW_INSTANCE \
  --authorized-networks=$MY_IP \
  --project=NEW_PROJECT

# psql로 직접 Import
PGPASSWORD='PASSWORD' psql -h PUBLIC_IP -U postgres -d pic2cook -f dump.sql
```

---

## 2️⃣ GCS 버킷 마이그레이션

```bash
# 기존 버킷에 새 계정 읽기 권한 부여 (기존 계정으로)
gcloud storage buckets add-iam-policy-binding gs://OLD_BUCKET \
  --member="user:NEW_ACCOUNT@gmail.com" \
  --role="roles/storage.objectViewer"

# 새 버킷 생성 및 동기화 (새 계정으로)
gcloud storage buckets create gs://NEW_BUCKET --location=REGION --project=NEW_PROJECT
gcloud storage rsync -r gs://OLD_BUCKET gs://NEW_BUCKET
```

### 필요한 버킷 목록
| 기존 버킷        | 새 버킷             |
| ---------------- | ------------------- |
| `PROJECT-prod`   | `PROJECT-v2-prod`   |
| `PROJECT-backup` | `PROJECT-v2-backup` |

---

## 3️⃣ 컨테이너 이미지 마이그레이션

```bash
# Docker 인증 설정
gcloud auth configure-docker OLD_REGION-docker.pkg.dev,NEW_REGION-docker.pkg.dev

# 이미지 Pull -> Tag -> Push
docker pull OLD_REGION-docker.pkg.dev/OLD_PROJECT/REPO/IMAGE:TAG
docker tag OLD_REGION-docker.pkg.dev/OLD_PROJECT/REPO/IMAGE:TAG \
  NEW_REGION-docker.pkg.dev/NEW_PROJECT/REPO/IMAGE:TAG
docker push NEW_REGION-docker.pkg.dev/NEW_PROJECT/REPO/IMAGE:TAG
```

---

## 4️⃣ GitHub Secrets 업데이트

Repository Settings > Secrets and variables > Actions에서 업데이트:

| Secret                           | 형식                                                                                           |
| -------------------------------- | ---------------------------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID` |
| `GCP_SERVICE_ACCOUNT`            | `SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com`                                           |

### 값 조회 방법

```bash
# Project Number
gcloud projects describe NEW_PROJECT --format="value(projectNumber)"

# WIF Provider 전체 경로
gcloud iam workload-identity-pools providers describe PROVIDER_ID \
  --workload-identity-pool=POOL_ID \
  --location=global \
  --project=NEW_PROJECT \
  --format="value(name)"
```

---

## 5️⃣ 소스 코드 변경

### `apps/api/src/lib/config.py`
```python
gcs_bucket_name: str = "NEW_BUCKET_NAME"  # pic2cook-v2-prod
```

### `apps/infra/compute-*.tf`
```hcl
env {
  name  = "GCS_BUCKET_NAME"
  value = "NEW_BUCKET_NAME"  # pic2cook-v2-prod
}
```

---

## 🚀 자동화 스크립트

전체 마이그레이션을 자동화하려면:

```bash
./.agent/skills/gcp-migration/scripts/migrate-gcp-project.sh \
  --old-project OLD_PROJECT \
  --new-project NEW_PROJECT \
  --old-region us-central1 \
  --new-region asia-northeast1
```

---

## ⚠️ 주의사항

1. **Cloud SQL Private IP**: 로컬에서 직접 접근 불가. Public IP 임시 활성화 필요.
2. **계정 전환**: 기존/신규 프로젝트 작업 시 `gcloud config set account` 필수.
3. **권한 전파 지연**: IAM 변경 후 몇 분 대기 필요할 수 있음.
4. **Terraform lifecycle.ignore_changes**: 이미지 변경은 `gcloud run deploy`로 별도 수행.

---

## 🔧 Terraform 변수 구조

Terraform 파일들은 프로젝트 ID와 리전이 변수화되어 있어, 마이그레이션 시 `variables.tf` 상단만 수정하면 됩니다.

### 핵심 변수 (`variables.tf` 상단)

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "pic2cook-v2"  # ← 새 프로젝트 ID로 변경
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"  # ← 필요 시 변경
}
```

### 변수화된 리소스 목록

| 파일           | 변수화된 항목                                   |
| -------------- | ----------------------------------------------- |
| `provider.tf`  | `project`, `region`                             |
| `storage.tf`   | 버킷 이름 (`${var.project_id}-prod`), 리전      |
| `database.tf`  | `project`, `region`, VPC 경로                   |
| `iam.tf`       | `project`, SA 이메일                            |
| `compute-*.tf` | 이미지 경로, `GOOGLE_CLOUD_PROJECT_ID` 환경변수 |

### ⚠️ 수동 변경 필요 항목

다음 항목들은 Terraform 제약으로 변수화할 수 없어 수동 변경 필요:

1. **`provider.tf` - backend bucket**
   ```hcl
   backend "gcs" {
     bucket = "NEW_PROJECT-tfstate"  # 수동 변경
   }
   ```

2. **`database.tf` - 인스턴스 이름** (기존 인스턴스 유지 시 그대로, 새로 생성 시 변경)
   ```hcl
   name = "pic2cook-postgres-XXXXXXXX"
   ```
