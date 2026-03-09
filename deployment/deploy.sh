#!/usr/bin/env bash
# Deploy to Cloud Run — API key มาจาก env.yaml (Cloud Run env vars)
# ใช้: ./deployment/deploy.sh
# ก่อนรัน: แก้ env.yaml ให้มี GEMINI_API_KEY จริง หรือชี้ไปที่ Secret

set -e

# ใช้ path จาก root ของ repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# โหลดค่า config จาก params.sh (PROJECT_ID, LOCATION_ID ฯลฯ)
PARAMS_FILE="$SCRIPT_DIR/params.sh"
if [[ -f "$PARAMS_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$PARAMS_FILE"
else
  echo "ไม่พบไฟล์ params.sh ที่ $PARAMS_FILE"
  exit 1
fi

# --- กำหนดค่า (แก้ตามโปรเจกต์) ---
# ACCOUNT, PROJECT_ID, LOCATION_ID มาจาก params.sh
ACCOUNT="${GCP_ACCOUNT:-$ACCOUNT}"
PROJECT_ID="${GCP_PROJECT_ID:-$PROJECT_ID}"
REGION="${GCP_REGION:-${LOCATION_ID:-asia-southeast1}}"
SERVICE_NAME="${SERVICE_NAME:-skill-analysis-chaiyo}"
ENV_FILE="${ENV_FILE:-env.yaml}"

ENV_PATH="$ROOT_DIR/$ENV_FILE"

if [[ ! -f "$ENV_PATH" ]]; then
  echo "ไม่พบไฟล์ env: $ENV_PATH"
  echo "สร้าง env.yaml ที่ root โดยมี GEMINI_API_KEY"
  exit 1
fi

# ใช้ account จาก params.sh
if [[ -n "$ACCOUNT" ]]; then
  echo "ตั้ง gcloud account เป็น: $ACCOUNT"
  gcloud config set account "$ACCOUNT"
fi

echo "Deploying to Cloud Run..."
echo "  Account: $ACCOUNT"
echo "  Project: $PROJECT_ID"
echo "  Region:  $REGION"
echo "  Service: $SERVICE_NAME"
echo "  Env:     $ENV_PATH"
echo ""

cd "$ROOT_DIR"

gcloud run deploy "$SERVICE_NAME" \
  --source . \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --allow-unauthenticated \
  --env-vars-file "$ENV_PATH"

echo ""
echo "Deploy เสร็จแล้ว"
