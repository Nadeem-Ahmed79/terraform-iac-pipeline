#!/usr/bin/env bash
# Runs the OPA policies against a real Terraform plan of the dev environment
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEV="$ROOT/infra/envs/dev"

# plan.json contains secrets in plain text: always delete it when the script ends
trap 'rm -f "$DEV/plan.json" "$DEV/policy.tfplan"' EXIT

echo ">> Creating plan"
terraform -chdir="$DEV" plan -input=false -out=policy.tfplan >/dev/null
terraform -chdir="$DEV" show -json policy.tfplan > "$DEV/plan.json"

echo ">> Checking plan against policies"
docker run --rm -v "$ROOT:/project" -w /project openpolicyagent/conftest:v0.64.0 \
  test infra/envs/dev/plan.json --policy policies
