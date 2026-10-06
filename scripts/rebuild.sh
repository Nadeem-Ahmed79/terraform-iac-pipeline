#!/usr/bin/env bash
# Recreate the full local environment from code
set -euo pipefail
cd "$(dirname "$0")/.."

echo ">> Starting LocalStack"
docker compose up -d
until curl -s localhost:4566/_localstack/health | grep -q '"s3": "\(available\|running\)"'; do
  sleep 3
done

echo ">> Creating state bucket"
terraform -chdir=infra/bootstrap apply -auto-approve

echo ">> Building dev environment"
terraform -chdir=infra/envs/dev init -reconfigure -input=false
terraform -chdir=infra/envs/dev apply -auto-approve

echo ">> Done. Resources in state:"
terraform -chdir=infra/envs/dev state list | wc -l
