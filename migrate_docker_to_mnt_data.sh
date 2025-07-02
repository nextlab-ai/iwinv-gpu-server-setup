#!/bin/bash
set -e

DOCKER_SERVICE="docker"
SRC="/var/lib/docker"
DEST="/mnt/data/docker"
BACKUP="/var/lib/docker.bak"
DAEMON_JSON="/etc/docker/daemon.json"

echo "🔧 Docker 중지..."
sudo systemctl stop $DOCKER_SERVICE

echo "📂 Docker 데이터 복사 중..."
sudo rsync -aP "$SRC/" "$DEST/"

echo "📦 원본 백업..."
sudo mv "$SRC" "$BACKUP"

echo "🛠️ Docker 설정 변경..."
sudo mkdir -p "$(dirname "$DAEMON_JSON")"
sudo bash -c "cat > $DAEMON_JSON" <<EOF
{
  "data-root": "$DEST"
}
EOF

echo "🚀 Docker 재시작..."
sudo systemctl start $DOCKER_SERVICE

echo "✅ Docker 상태 확인:"
sudo systemctl status $DOCKER_SERVICE --no-pager
docker info | grep 'Docker Root Dir'
