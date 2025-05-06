.PHONY: all setup brew kubectl minikube docker helm start status flink prepare version-check \
        kafka-help setup-kafka delete-kafka setup-ui delete-ui setup-kafka-all delete-kafka-all create-topic \
        start-consumer forward-port forward-ui

# 네임스페이스 정의
KAFKA_NS = kafka
FLINK_NS = flink

# 원하는 버전
MINIKUBE_VERSION = v1.32.0
KUBECTL_VERSION = v1.29.0
HELM_VERSION = v3.14.0

# 전체 실행
all: setup start setup-kafka-all status flink

# minikube 재실행시
prepare: start setup-kafka-all status flink

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

# 버전 확인
version-check:
	@echo "🔍 Checking installed versions..."
	@echo "- Minikube: $$(minikube version | head -n 1)"
	@echo "- Kubectl: $$(kubectl version --client --output=yaml | grep gitVersion | head -n 1)"
	@echo "- Helm: $$(helm version --short)"

# Minikube 클러스터 시작
start:
	@echo "🚀 Starting Minikube with Docker driver..."
	minikube start --driver=docker --cpus=6 --memory=7g --kubernetes-version=v1.25.0

# 클러스터 상태 확인
status:
	@echo "🔍 Checking cluster status..."
	minikube status
	kubectl get pods -A

# Flink 설치
flink:
	@echo "📦 Deploying Flink..."
	helm repo add flink https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade --install my-flink bitnami/flink \
	  --namespace $(FLINK_NS) --create-namespace \
	  -f helm/flink/values.local.yaml

#-----------------------------------------------------------------------------
# Kafka KRaft 관련 타겟들
#-----------------------------------------------------------------------------

# Kafka 도움말
kafka-help:
	@echo "=== Kafka on Minikube ==="
	@echo "make setup-kafka       - Kafka 설치"
	@echo "make delete-kafka      - Kafka 삭제"
	@echo "make setup-ui          - Kafka UI 설치"
	@echo "make delete-ui         - Kafka UI 삭제"
	@echo "make setup-kafka-all   - Kafka와 UI 모두 설치"
	@echo "make delete-kafka-all  - Kafka와 UI 모두 삭제"
	@echo "make create-topic      - 'upbit-btc-data' 토픽 생성"
	@echo "make forward-port      - Kafka 포트 포워딩 시작 (9092)"
	@echo "make forward-ui        - Kafka UI 포트 포워딩 시작 (8080)"
	@echo "make start-consumer    - 테스트 컨슈머 시작"

# Minikube 데이터 디렉토리 준비
prepare-data-dir:
	@echo "=== 데이터 디렉토리 준비 ==="
	minikube ssh "sudo mkdir -p /data/kafka-1 && sudo chown -R 1000:1000 /data/kafka-1"

# Kafka 설치
setup-kafka: prepare-data-dir
	@echo "=== Kafka 설치 ==="
	kubectl apply -f infra/kafka.local.yaml
	@echo "Kafka 파드가 준비될 때까지 기다리는 중..."
	kubectl wait --for=condition=ready pod -l app=kafka --timeout=120s
	@echo "Kafka가 성공적으로 설치되었습니다!"

# Kafka 삭제
delete-kafka:
	@echo "=== Kafka 삭제 ==="
	kubectl delete -f infra/kafka.local.yaml
	@echo "Kafka가 삭제되었습니다."

# Kafka UI 설치
setup-ui:
	@echo "=== Kafka UI 설치 ==="
	kubectl apply -f infra/kafka-ui.yaml
	@echo "Kafka UI 파드가 준비될 때까지 기다리는 중..."
	kubectl wait --for=condition=ready pod -l app=kafka-ui --timeout=60s
	@echo "Kafka UI가 성공적으로 설치되었습니다!"
	@echo "접속 URL: http://localhost:8080 (포트 포워딩 필요)"

# Kafka UI 삭제
delete-ui:
	@echo "=== Kafka UI 삭제 ==="
	kubectl delete -f infra/kafka-ui.yaml
	@echo "Kafka UI가 삭제되었습니다."

# Kafka와 UI 모두 설치
setup-kafka-all: setup-kafka setup-ui
	@echo "=== Kafka와 UI 모두 설치 완료 ==="

# Kafka와 UI 모두 삭제
delete-kafka-all: delete-ui delete-kafka
	@echo "=== Kafka와 UI 모두 삭제 완료 ==="

# 토픽 생성
create-topic:
	@echo "=== 'upbit-btc-data' 토픽 생성 ==="
	kubectl run kafka-client --rm -it --image=confluentinc/cp-kafka:7.7.0 --restart=Never -- kafka-topics --bootstrap-server kafka-external:9092 --create --topic upbit-btc-data --partitions 1 --replication-factor 1

# Kafka 포트 포워딩 (백그라운드로 실행)
forward-port:
	@echo "=== Kafka 포트 포워딩 시작 (9092) ==="
	@echo "포트 포워딩을 중지하려면 'pkill -f \"port-forward svc/kafka-external\"' 명령어를 사용하세요."
	nohup kubectl port-forward svc/kafka-external 9092:9092 > /dev/null 2>&1 &
	@echo "포트 포워딩이 시작되었습니다. localhost:9092로 Kafka에 접속할 수 있습니다."

# Kafka UI 포트 포워딩 (백그라운드로 실행)
forward-ui:
	@echo "=== Kafka UI 포트 포워딩 시작 (8080) ==="
	@echo "포트 포워딩을 중지하려면 'pkill -f \"port-forward svc/kafka-ui\"' 명령어를 사용하세요."
	nohup kubectl port-forward svc/kafka-ui 8080:8080 > /dev/null 2>&1 &
	@echo "포트 포워딩이 시작되었습니다. http://localhost:8080로 Kafka UI에 접속할 수 있습니다."

# Kafka Connect 설치
setup-kafka-connect:
	@echo "=== Kafka Connect 설치 ==="
	kubectl apply -f infra/kafka-connect.yaml
	@echo "Kafka Connect 파드가 준비될 때까지 기다리는 중..."
	kubectl wait --for=condition=ready pod -l app=kafka-connect -n elk --timeout=120s
	@echo "Kafka Connect가 성공적으로 설치되었습니다!"

# Kafka Connect 삭제
delete-kafka-connect:
	@echo "=== Kafka Connect 삭제 ==="
	kubectl delete -f infra/kafka-connect.yaml
	@echo "Kafka Connect가 삭제되었습니다."

# Kafka Connect 포트 포워딩
forward-kafka-connect:
	@echo "=== Kafka Connect 포트 포워딩 시작 (8083) ==="
	@echo "포트 포워딩을 중지하려면 'pkill -f \"port-forward svc/kafka-connect\"' 명령어를 사용하세요."
	nohup kubectl port-forward -n kafka svc/kafka-connect 8083:8083 > /dev/null 2>&1 &
	@echo "포트 포워딩이 시작되었습니다. http://localhost:8083로 Kafka Connect에 접속할 수 있습니다."
	