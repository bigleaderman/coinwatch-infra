.PHONY: all brew kubectl minikube docker helm kafka start status

# 전체 설치 순서 실행
all: brew kubectl minikube docker helm start kafka status

# Homebrew 설치
brew:
	@echo "🔧 Installing Homebrew..."
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@echo '✅ Homebrew installation complete.'

# kubectl 설치
kubectl:
	@echo "🔧 Installing kubectl..."
	brew install kubectl
	kubectl version --client
	@echo '✅ kubectl installation complete.'

# minikube 설치
minikube:
	@echo "🔧 Installing Minikube..."
	brew install minikube
	minikube version
	@echo '✅ Minikube installation complete.'

# Docker Desktop 4.26.1 설치
docker:
	@echo "🔧 Installing Docker Desktop version 4.26.1..."
	brew install --cask homebrew/cask-versions/docker@4.26.1
	@echo '⚠️  Please manually launch Docker Desktop and ensure it is running.'

# Helm 설치
helm:
	@echo "🔧 Installing Helm..."
	brew install helm
	helm version
	@echo '✅ Helm installation complete.'

# Minikube 클러스터 시작
start:
	@echo "🚀 Starting Minikube with Docker driver..."
	minikube start --driver=docker --cpus=4 --memory=4g

# Kafka 설치 (Bitnami 차트 + 최소 설정)
kafka:
	@echo "📦 Installing Kafka via Helm (Bitnami, lightweight config)..."
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade --install my-kafka bitnami/kafka --namespace kafka --create-namespace \
	  --set replicaCount=1 \
	  --set resources.requests.cpu=250m \
	  --set resources.requests.memory=512Mi \
	  --set resources.limits.cpu=500m \
	  --set resources.limits.memory=1Gi \
	  --set zookeeper.replicaCount=1 \
	  --set zookeeper.resources.requests.memory=256Mi \
	  --set zookeeper.resources.limits.memory=512Mi
	@echo '✅ Kafka installed in namespace "kafka".'

# 클러스터 상태 확인
status:
	@echo "🔍 Checking Minikube status..."
	minikube status
	kubectl get pods -A

