.PHONY: all setup brew kubectl minikube docker helm start kafka flink status prepare version-check

# 네임스페이스 정의
KAFKA_NS = kafka
FLINK_NS = flink

# 원하는 버전
MINIKUBE_VERSION = v1.32.0
KUBECTL_VERSION = v1.29.0
HELM_VERSION = v3.14.0

# 전체 실행
all: setup start kafka flink status

# minikube 재실행시
prepare : start kafka flink status

# 설치 관련 설정
setup: brew kubectl minikube docker helm version-check

# Homebrew 설치
brew:
	@echo "🔧 Installing Homebrew..."
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
	@echo '✅ Homebrew installation complete.'

# kubectl 설치 (ARM 전용)
kubectl:
	@echo "🔧 Installing kubectl $(KUBECTL_VERSION)..."
	curl -LO "https://dl.k8s.io/release/$(KUBECTL_VERSION)/bin/darwin/arm64/kubectl"
	chmod +x kubectl
	sudo mv kubectl /usr/local/bin/kubectl
	kubectl version --client
	@echo '✅ kubectl installation complete.'

# minikube 설치 (ARM 전용)
minikube:
	@echo "🔧 Installing Minikube $(MINIKUBE_VERSION)..."
	curl -LO "https://storage.googleapis.com/minikube/releases/$(MINIKUBE_VERSION)/minikube-darwin-arm64"
	chmod +x minikube-darwin-arm64
	sudo mv minikube-darwin-arm64 /usr/local/bin/minikube
	minikube version
	@echo '✅ Minikube installation complete.'

# Docker 설치
docker:
	@echo "🔧 Installing Docker Desktop..."
	brew install --cask docker || true
	@echo '⚠️  Please manually launch Docker Desktop and ensure it is running.'

# Helm 설치 (ARM 전용)
helm:
	@echo "🔧 Installing Helm $(HELM_VERSION)..."
	curl -LO "https://get.helm.sh/helm-$(HELM_VERSION)-darwin-arm64.tar.gz"
	tar -zxvf helm-$(HELM_VERSION)-darwin-arm64.tar.gz
	sudo mv darwin-arm64/helm /usr/local/bin/helm
	rm -rf helm-$(HELM_VERSION)-darwin-arm64.tar.gz darwin-arm64
	helm version
	@echo '✅ Helm installation complete.'


# Minikube 클러스터 시작
start:
	@echo "🚀 Starting Minikube with Docker driver..."
	minikube start --driver=docker --cpus=6 --memory=7g

# Kafka 설치 (Bitnami)
kafka:
	@echo "📦 Deploying Kafka (Bitnami)..."
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade --install my-kafka bitnami/kafka \
	  --namespace $(KAFKA_NS) --create-namespace \
	  -f helm/kafka/values.local.yaml

# Flink 설치
flink:
	@echo "📦 Deploying Flink..."
	helm repo add flink https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade --install my-flink bitnami/flink \
	  --namespace $(FLINK_NS) --create-namespace \
	  -f helm/flink/values.local.yaml

# 클러스터 상태 확인
status:
	@echo "🔍 Checking cluster status..."
	minikube status
	kubectl get pods -A
