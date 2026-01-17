---
name: GCP Project Migration
description: GCP 프로젝트 간 마이그레이션 (DB, Storage, Container Images, Terraform)
---

# GCP Project Migration Skill

이 스킬은 GCP 프로젝트를 한 프로젝트에서 다른 프로젝트로 완전 이전하는 작업을 안내합니다.

## 사전 조건

1. **두 GCP 프로젝트** 모두에 대한 Owner/Editor 권한
2. **gcloud CLI** 설치 및 인증됨
3. **Docker** 설치됨 (컨테이너 이미지 이전용)
4. 새 프로젝트에 **Terraform 인프라가 먼저 배포**되어 있어야 함

## 마이그레이션 순서

### Phase 1: API 활성화

새 프로젝트에서 필요한 API들을 활성화합니다:

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

### Phase 2: 데이터베이스 마이그레이션

1. **Export from old project**
   ```bash
   # 구 프로젝트 계정으로 전환
   gcloud config set account OLD_ACCOUNT@gmail.com
   
   # Cloud SQL 서비스 계정에 버킷 권한 부여
   OLD_SA=$(gcloud sql instances describe OLD_INSTANCE --project=OLD_PROJECT --format="value(serviceAccountEmailAddress)")
   gcloud storage buckets add-iam-policy-binding gs://MIGRATION_BUCKET \
     --member="serviceAccount:$OLD_SA" \
     --role="roles/storage.objectAdmin"
   
   # DB 덤프
   gcloud sql export sql OLD_INSTANCE gs://MIGRATION_BUCKET/dump.sql \
     --database=pic2cook --project=OLD_PROJECT
   ```

2. **Import to new project**
   ```bash
   # 신 프로젝트 계정으로 전환
   gcloud config set account NEW_ACCOUNT@gmail.com
   
   # 권한 부여 및 Import
   NEW_SA=$(gcloud sql instances describe NEW_INSTANCE --project=NEW_PROJECT --format="value(serviceAccountEmailAddress)")
   gcloud storage buckets add-iam-policy-binding gs://MIGRATION_BUCKET \
     --member="serviceAccount:$NEW_SA" \
     --role="roles/storage.objectViewer"
   
   gcloud sql import sql NEW_INSTANCE gs://MIGRATION_BUCKET/dump.sql \
     --database=pic2cook --user=postgres --project=NEW_PROJECT
   ```

### Phase 3: GCS 버킷 마이그레이션

```bash
# 구 계정에서 신 계정에 읽기 권한 부여
gcloud storage buckets add-iam-policy-binding gs://OLD_BUCKET \
  --member="user:NEW_ACCOUNT@gmail.com" \
  --role="roles/storage.objectViewer"

# 신 계정에서 버킷 생성 및 동기화
gcloud storage buckets create gs://NEW_BUCKET --location=REGION --project=NEW_PROJECT
gcloud storage rsync -r gs://OLD_BUCKET gs://NEW_BUCKET
```

### Phase 4: 컨테이너 이미지 마이그레이션

```bash
# Docker 인증
gcloud auth configure-docker OLD_REGION-docker.pkg.dev,NEW_REGION-docker.pkg.dev

# 이미지 Pull -> Tag -> Push
docker pull OLD_REGION-docker.pkg.dev/OLD_PROJECT/REPO/IMAGE:TAG
docker tag OLD_REGION-docker.pkg.dev/OLD_PROJECT/REPO/IMAGE:TAG \
  NEW_REGION-docker.pkg.dev/NEW_PROJECT/REPO/IMAGE:TAG
docker push NEW_REGION-docker.pkg.dev/NEW_PROJECT/REPO/IMAGE:TAG
```

### Phase 5: Terraform 변수 수정

`apps/infra/variables.tf` 파일 상단의 변수만 수정:

```hcl
variable "project_id" {
  default = "NEW_PROJECT_ID"  # ← 변경
}

variable "region" {
  default = "asia-northeast1"  # ← 필요 시 변경
}
```

**수동 변경 필요**:
- `provider.tf`의 `backend.bucket` (Terraform 제약)

### Phase 6: GitHub Secrets 업데이트

Repository Settings > Secrets and variables > Actions에서:

| Secret                           | 값                                                                                                       |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/pic2cook-pool/providers/github-provider` |
| `GCP_SERVICE_ACCOUNT`            | `pic2cook-deployer@NEW_PROJECT.iam.gserviceaccount.com`                                                  |

값 조회:
```bash
# Project Number
gcloud projects describe NEW_PROJECT --format="value(projectNumber)"

# WIF Provider
gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=pic2cook-pool --location=global --project=NEW_PROJECT --format="value(name)"
```

### Phase 7: 코드 변경 및 배포

1. `apps/api/src/lib/config.py`의 `gcs_bucket_name` 기본값 변경
2. 커밋 및 푸시
3. GitHub Actions가 자동 배포

## 자동화 스크립트

전체 데이터 마이그레이션을 한 번에 실행:

```bash
./.agent/skills/gcp-migration/scripts/migrate-gcp-project.sh \
  --old-project OLD_PROJECT_ID \
  --new-project NEW_PROJECT_ID \
  --old-region us-central1 \
  --new-region asia-northeast1
```

## 참조 문서

- [마이그레이션 가이드](docs/gcp-migration-guide.md)
- [마이그레이션 스크립트](.agent/skills/gcp-migration/scripts/migrate-gcp-project.sh)

## 체크리스트

- [ ] API 활성화 완료
- [ ] DB 마이그레이션 완료
- [ ] GCS 버킷 마이그레이션 완료
- [ ] 컨테이너 이미지 마이그레이션 완료
- [ ] Terraform variables.tf 수정
- [ ] GitHub Secrets 업데이트
- [ ] config.py 수정 및 푸시
- [ ] 배포 확인 및 테스트
