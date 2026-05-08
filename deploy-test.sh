#!/bin/bash
set -e
# deploy-test.sh — 建置 SPA、更新 JAR、部署到 Docker 測試環境
# 用法: bash deploy-test.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_NAME="tw-mxp-idempiere-kanban-idempiere-1"
JAR="$SCRIPT_DIR/tw.mxp.idempiere.kanban/target/tw.mxp.idempiere.kanban-14.0.0-SNAPSHOT.jar"
BUNDLE_FILE="$(basename "$JAR")"

echo "=== Step 1: Build SPA ==="
cd "$SCRIPT_DIR/spa"
npm install --silent 2>/dev/null
npm run build
cd "$SCRIPT_DIR"

echo ""
echo "=== Step 2: Update JAR with new SPA ==="
if [ ! -f "$JAR" ]; then
  echo "ERROR: JAR not found at $JAR"
  echo "Run 'bash build.sh' first (requires iDempiere source)."
  exit 1
fi
cd "$SCRIPT_DIR/tw.mxp.idempiere.kanban"
jar -uf target/"$BUNDLE_FILE" web/
cd "$SCRIPT_DIR"
echo "JAR updated with latest SPA build."

echo ""
echo "=== Step 3: Start containers ==="
docker compose up -d
echo "Waiting for iDempiere to start..."
for i in $(seq 1 60); do
  if docker logs "$CONTAINER_NAME" 2>&1 | grep -q "Server is ready"; then
    echo " Ready!"
    break
  fi
  sleep 5
  printf "."
done

echo ""
echo "=== Step 4: Deploy plugin ==="
docker cp "$JAR" "$CONTAINER_NAME":/opt/idempiere/plugins/
docker exec "$CONTAINER_NAME" bash -c "
  BUNDLES=/opt/idempiere/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
  if ! grep -q 'tw.mxp.idempiere.kanban' \"\$BUNDLES\" 2>/dev/null; then
    echo 'tw.mxp.idempiere.kanban,14.0.0.qualifier,plugins/$BUNDLE_FILE,4,false' >> \"\$BUNDLES\"
  fi
"

echo ""
echo "=== Step 5: Restart iDempiere ==="
docker compose restart idempiere
echo ""
echo "Restarting... wait ~30s then access:"
echo ""
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_IP")
echo "  Desktop:  https://localhost:8443/webui/"
echo "  Mobile:   https://${LOCAL_IP}:8443/webui/"
echo ""
echo "  Login: GardenAdmin / GardenAdmin"
echo "  Menu → Kanban Board"
