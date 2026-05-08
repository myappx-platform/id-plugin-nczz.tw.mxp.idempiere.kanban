#!/bin/bash
set -e
# deploy-spa-only.sh — 只更新 SPA 前端（快速迭代用）
# 不需重啟 iDempiere，刷新瀏覽器即可看到變更

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_NAME="tw-mxp-idempiere-kanban-idempiere-1"

echo "=== Building SPA ==="
cd "$SCRIPT_DIR/spa"
npm run build
cd "$SCRIPT_DIR"

echo "=== Deploying to container ==="
docker cp "$SCRIPT_DIR/tw.mxp.idempiere.kanban/web/." "$CONTAINER_NAME":/opt/idempiere/plugins/tw.mxp.idempiere.kanban-14.0.0-SNAPSHOT.jar_web/ 2>/dev/null || \
docker exec "$CONTAINER_NAME" bash -c "
  # Find the extracted web folder
  WEB_DIR=\$(find /opt/idempiere -path '*/tw.mxp.idempiere.kanban*/web' -type d 2>/dev/null | head -1)
  if [ -n \"\$WEB_DIR\" ]; then
    echo \"Found: \$WEB_DIR\"
  else
    echo 'Web dir not found. Full restart needed: docker compose restart idempiere'
    exit 1
  fi
" && docker cp "$SCRIPT_DIR/tw.mxp.idempiere.kanban/web/." "$CONTAINER_NAME":/opt/idempiere/plugins/

echo ""
echo "Done! Refresh browser to see changes."
echo "No restart needed for SPA-only changes."
