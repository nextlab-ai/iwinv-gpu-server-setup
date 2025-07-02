#!/bin/bash
set -e  # 에러 발생 시 중단

# ✅ 이미 실행됐는지 확인
if [ -f "$HOME/.setup_done" ]; then
    echo "✅ 이미 초기화 완료됨. 종료합니다."
    exit 0
fi

echo "✅ 시스템 업데이트 중..."
sudo apt update && sudo apt upgrade -y

echo "✅ 필수 유틸리티 설치 중..."
sudo apt install -y \
  curl git build-essential libssl-dev zlib1g-dev \
  libreadline-dev libsqlite3-dev libbz2-dev libffi-dev

# ----------------------------
# OS 타입 확인 및 Python 경로 설정
# ----------------------------
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "🪟 Windows 환경에서 실행 중입니다."
    PYTHON_PATH="python"
    VENV_ACTIVATE=".venv/Scripts/activate"
else
    echo "🐧 Linux/Mac 환경에서 실행 중입니다."
    PYTHON_PATH="python3"
    VENV_ACTIVATE=".venv/bin/activate"
fi

# ----------------------------
# asdf 설치 및 Python 설치
# ----------------------------
echo "🔍 asdf 설치 확인 중..."
if [ ! -d "$HOME/.asdf" ]; then
    echo "📥 asdf 설치 중..."
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
    echo -e '\n. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
    echo -e '\n. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
fi

# asdf 환경 적용
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

# Python 플러그인 추가 (중복 방지)
asdf plugin list | grep -q "python" || asdf plugin add python

echo "🐍 Python 3.10.12 설치 중..."
asdf install python 3.10.12 || echo "이미 설치됨"
asdf local python 3.10.12

# ----------------------------
# 작업 디렉토리 및 프로젝트 클론
# ----------------------------
mkdir -p ~/project/
cd ~/project

#git clone https://github.com/nextlab-ai/llm-rag-poc.git
git clone -b triton_server --single-branch https://github.com/nextlab-ai/llm-rag-poc.git
cd llm-rag-poc

# ----------------------------
# 가상환경 및 패키지 설치
# ----------------------------
VENV_NAME=".venv"
echo "🧪 가상환경 생성 중: $VENV_NAME"
$PYTHON_PATH -m venv $VENV_NAME

echo "✅ 가상환경 활성화"
source $VENV_ACTIVATE

echo "📦 requirements.txt 설치 중..."
pip install --upgrade pip
pip install -r requirements.txt

echo "🎉 완료! 서버 환경 세팅이 완료되었습니다."

# ----------------------------
# Docker daemon 설정 추가 (기본 설정만)
# ----------------------------
echo "🛠️ Docker daemon 기본 설정 중..."

sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "data-root": "/mnt/data/docker"
}
EOF

echo "🔄 Docker 데몬 재시작 중..."
sudo systemctl daemon-reexec
sudo systemctl restart docker


# ✅ 마지막 줄에 실행 완료 마커 생성
touch "$HOME/.setup_done"
