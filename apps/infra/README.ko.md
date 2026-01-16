# 인프라

GCP 인프라 프로비저닝을 위한 Terraform 설정입니다.

## 사전 요구사항

### GCP API 활성화

`terraform apply` 실행 전, GCP 프로젝트에서 다음 API를 활성화하세요:

- [Compute Engine API](https://console.cloud.google.com/apis/api/compute.googleapis.com/metrics)
- [Cloud Run API](https://console.cloud.google.com/apis/library/run.googleapis.com)
- [Cloud Tasks API](https://console.cloud.google.com/apis/library/cloudtasks.googleapis.com)
- [IAM Service Account Credentials API](https://console.cloud.google.com/marketplace/product/google/iamcredentials.googleapis.com)
- [Service Networking API](https://console.cloud.google.com/apis/api/servicenetworking.googleapis.com/metrics)

## 사용법

```bash
# 초기화
mise run init

# Dry-run (dev)
mise run plan

# 적용 (dev)
mise run apply

# Dry-run (prod)
mise run plan:prod

# 적용 (prod)
mise run apply:prod
```
