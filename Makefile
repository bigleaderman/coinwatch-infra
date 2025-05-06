.PHONY: all setup brew kubectl minikube docker helm start status flink prepare version-check \
        kafka-help deploy-namespace-kafka clean-namespace-kafka setup-kafka delete-kafka setup-ui delete-ui \
		setup-kafka-all delete-kafka-all create-topic create-es-sink-connector delete-es-sink-connector \
        start-consumer forward-kafka forward-ui deploy-elasticsearch deploy-kibana clean-elasticsearch clean-kibana \
		port-forward-kibana deploy-pv deploy-config clean-pv clean-config deploy-namespace-elk clean-namespace es-help

# 네임스페이스 정의
KAFKA_NS = kafka
ELK_NS = elk

# 원하는 버전
MINIKUBE_VERSION = v1.32.0
KUBECTL_VERSION = v1.29.0
HELM_VERSION = v3.14.0

# 전체 실행
all: setup start status setup-kafka-all deploy-namespace-elk deploy-pv deploy-config deploy-elasticsearch deploy-kibana create-elasticsearch-index

# minikube 재실행시
prepare: start status setup-kafka-all deploy-namespace-elk deploy-pv deploy-config deploy-elasticsearch deploy-kibana create-elasticsearch-index

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
	@echo "make forward-kafka     - Kafka 포트 포워딩 시작 (9092)"
	@echo "make forward-ui        - Kafka UI 포트 포워딩 시작 (8080)"
	@echo "make start-consumer    - 테스트 컨슈머 시작"

# Kafka와 UI 모두 설치
setup-kafka-all: deploy-namespace-kafka setup-kafka setup-ui setup-kafka-connect
	@echo "=== Kafka, UI, Connector 모두 설치 완료 ==="

# Kafka와 UI 모두 삭제
delete-kafka-all: clean-namespace-kafka delete-kafka delete-ui setup-kafka-connect
	@echo "=== Kafka, UI, Connector 모두 삭제 완료 ==="

# Minikube 데이터 디렉토리 준비
prepare-data-dir:
	@echo "=== 데이터 디렉토리 준비 ==="
	minikube ssh "sudo mkdir -p /data/kafka-1 && sudo chown -R 1000:1000 /data/kafka-1"

# Kafka 네임스페이스 생성
deploy-namespace-kafka:
	@echo "📦 Creating Kafka namespace..."
	kubectl apply -f infra/kafka/namespace.yaml
	@echo '✅ Namespace "kafka" creation complete.'

# ELK 네임스페이스 정리
clean-namespace-kafka:
	@echo "🧹 Cleaning up kafka namespace..."
	kubectl delete -f infra/kafka/namespace.yaml
	@echo '✅ Namespace "kafka" cleanup complete.'

# Kafka 설치
setup-kafka: prepare-data-dir
	@echo "=== Kafka 설치 ==="
	kubectl apply -f infra/kafka/kafka.local.yaml
	@echo "Kafka 파드가 준비될 때까지 기다리는 중..."
	kubectl wait --for=condition=ready pod -l app=kafka -n kafka --timeout=120s
	@echo "Kafka가 성공적으로 설치되었습니다!"

# Kafka 삭제
delete-kafka:
	@echo "=== Kafka 삭제 ==="
	kubectl delete -f infra/kafka/kafka.local.yaml
	@echo "Kafka가 삭제되었습니다."

# Kafka UI 설치
setup-ui:
	@echo "=== Kafka UI 설치 ==="
	kubectl apply -f infra/kafka/kafka-ui.yaml
	@echo "Kafka UI 파드가 준비될 때까지 기다리는 중..."
	kubectl wait --for=condition=ready pod -l app=kafka-ui -n kafka --timeout=60s
	@echo "Kafka UI가 성공적으로 설치되었습니다!"
	@echo "접속 URL: http://localhost:8080 (포트 포워딩 필요)"

# Kafka UI 삭제
delete-ui:
	@echo "=== Kafka UI 삭제 ==="
	kubectl delete -f infra/kafka/kafka-ui.yaml
	@echo "Kafka UI가 삭제되었습니다."

# Kafka Connect 설치
setup-kafka-connect:
	@echo "=== Kafka Connect 설치 ==="
	kubectl apply -f infra/kafka/kafka-connect.yaml
	@echo "Kafka Connect 파드가 준비될 때까지 기다리는 중..."
	kubectl wait --for=condition=ready pod -l app=kafka-connect -n kafka --timeout=120s
	@echo "Kafka Connect가 성공적으로 설치되었습니다!"

# Kafka Connect 삭제
delete-kafka-connect:
	@echo "=== Kafka Connect 삭제 ==="
	kubectl delete -f infra/kafka/kafka-connect.yaml
	@echo "Kafka Connect가 삭제되었습니다."

# 토픽 생성
create-topic:
	@echo "=== 'upbit-btc-data' 토픽 생성 ==="
	kubectl run kafka-client --rm -it --image=confluentinc/cp-kafka:7.7.0 --restart=Never -- kafka-topics --bootstrap-server kafka-external:9092 --create --topic test-btc-data --partitions 1 --replication-factor 1

# Kafka 포트 포워딩 (백그라운드로 실행)
forward-kafka:
	@echo "=== Kafka 포트 포워딩 시작 (9092) ==="
	@echo "포트 포워딩을 중지하려면 'pkill -f \"port-forward svc/kafka-external\"' 명령어를 사용하세요."
	nohup kubectl port-forward -n kafka svc/kafka-external 9092:9092 > /dev/null 2>&1 &
	@echo "Kafka 포트 포워딩이 시작되었습니다."

# Kafka UI 포트 포워딩 (백그라운드로 실행)
forward-ui:
	@echo "=== Kafka UI 포트 포워딩 시작 (8080) ==="
	@echo "포트 포워딩을 중지하려면 'pkill -f \"port-forward svc/kafka-ui\"' 명령어를 사용하세요."
	nohup kubectl port-forward -n kafka svc/kafka-ui 8080:8080 > /dev/null 2>&1 &
	@echo "Kafka UI 포트 포워딩이 시작되었습니다. http://localhost:8080로 Kafka UI에 접속할 수 있습니다."

# Kafka Connect 포트 포워딩 (백그라운드로 실행)
forward-kafka-connect:
	@echo "=== Kafka Connect 포트 포워딩 시작 (8083) ==="
	@echo "포트 포워딩을 중지하려면 'pkill -f \"port-forward svc/kafka-connect\"' 명령어를 사용하세요."
	nohup kubectl port-forward -n kafka svc/kafka-connect 8083:8083 > /dev/null 2>&1 &
	@echo "Kafka Connect 포트 포워딩이 시작되었습니다. http://localhost:8083로 Kafka Connect에 접속할 수 있습니다."

# Kafka Connector (es sink 생성)
create-es-sink-connector:
	@echo "=== ES Sink Connector를 생성합니다. (Kafka Connect 포트 포워딩 필요!) ==="
	curl -X POST -H "Content-Type: application/json" --data @./infra/kafka/es-sink-connector.json http://localhost:8083/connectors
	@echo "=== ES Sink Connector 생성 완료되었습니다. ==="

# Kafka Connector (es sink 생성)
delete-es-sink-connector:
	@echo "=== ES Sink Connector를 제거합니다. (Kafka Connect 포트 포워딩 필요!) ==="
	curl  -X DELETE http://localhost:8083/connectors/elasticsearch-sink
	@echo "=== ES Sink Connector 제거 완료되었습니다. ==="

#-----------------------------------------------------------------------------
# ELK 관련 타겟들
#-----------------------------------------------------------------------------

# ELK 모두 설치
setup-elk-all: deploy-namespace-elk deploy-pv deploy-config deploy-elasticsearch deploy-kibana
	@echo "=== ELK 모두 설치 완료 ==="

# ELK 네임스페이스 생성
deploy-namespace-elk:
	@echo "📦 Creating ELK namespace..."
	kubectl apply -f infra/elk/namespace.yaml
	@echo '✅ Namespace "elk" creation complete.'

# Elasticsearch PV 배포
deploy-pv:
	@echo "💾 Deploying Elasticsearch PV..."
	kubectl apply -f infra/elk/elasticsearch-pv.yaml
	@echo '✅ PV deployment complete.'

# Elasticsearch ConfigMap 배포
deploy-config:
	@echo "⚙️ Deploying Elasticsearch ConfigMap..."
	kubectl apply -f infra/elk/elasticsearch-config.yaml
	@echo '✅ ConfigMap deployment complete.'

# Elasticsearch 배포
deploy-elasticsearch:
	@echo "🔧 Deploying Elasticsearch..."
	kubectl apply -f infra/elk/elasticsearch.yaml
	@echo "⏳ Waiting for Elasticsearch to be ready..."
	kubectl wait --for=condition=ready pod -l app=elasticsearch --timeout=300s
	@echo '✅ Elasticsearch deployment complete.'

# Kibana 배포
deploy-kibana:
	@echo "🔧 Deploying Kibana..."
	kubectl apply -f infra/elk/kibana.yaml
	@echo "⏳ Waiting for Kibana to be ready..."
	kubectl wait --for=condition=ready pod -l app=kibana --timeout=300s
	@echo '✅ Kibana deployment complete.'

# ELK 네임스페이스 정리
clean-namespace:
	@echo "🧹 Cleaning up ELK namespace..."
	kubectl delete -f infra/elk/namespace.yaml
	@echo '✅ Namespace cleanup complete.'

# Elasticsearch PV 정리
clean-pv:
	@echo "🧹 Cleaning up Elasticsearch PV..."
	kubectl delete -f infra/elk/elasticsearch-pv.yaml
	@echo '✅ PV cleanup complete.'

# Elasticsearch ConfigMap 정리
clean-config:
	@echo "🧹 Cleaning up Elasticsearch ConfigMap..."
	kubectl delete -f infra/elk/elasticsearch-config.yaml
	@echo '✅ ConfigMap cleanup complete.'

# Elasticsearch 리소스 정리
clean-elasticsearch:
	@echo "🧹 Cleaning up Elasticsearch resources..."
	kubectl delete -f infra/elk/elasticsearch.yaml
	@echo '✅ Elasticsearch cleanup complete.'

# Kibana 리소스 정리
clean-kibana:
	@echo "🧹 Cleaning up Kibana resources..."
	kubectl delete -f infra/elk/kibana.yaml
	@echo '✅ Kibana cleanup complete.'

# Elasticsearch 인덱스 생성
create-elasticsearch-index:
	@echo "=== Elasticsearch 범용 인덱스 생성 ==="
	kubectl exec -it -n elk $$(kubectl get pods -n elk -l app=elasticsearch -o name | cut -d/ -f2) -- \
    curl -X PUT "localhost:9200/upbit-btc-data" -H "Content-Type: application/json" -d'{ \
        "settings": { \
            "number_of_shards": 1, \
            "number_of_replicas": 0 \
        }, \
        "mappings": { \
            "dynamic": true, \
            "date_detection": true \
        } \
    }'
	@echo "인덱스가 생성되었습니다."

# ES 포트 포워딩
port-forward-es:
	@echo "=== ES 포트 포워딩 시작 (9200) ==="	
	@echo "포트 포워딩을 중지하려면 'pkill -f \"port-forward -n elk svc/elasticsearch\"' 명령어를 사용하세요."
	@echo "🔌 Starting port forwarding for ES..."
	nohup kubectl port-forward -n elk svc/elasticsearch 9200:9200 > /dev/null 2>&1 &
	@echo "ES 포트 포워딩이 시작되었습니다."

# Kibana 포트 포워딩
port-forward-kibana:
	@echo "=== Kafka 포트 포워딩 시작 (5601) ==="	
	@echo "포트 포워딩을 중지하려면 'pkill -f \"port-forward -n elk svc/kibana\"' 명령어를 사용하세요."
	@echo "🔌 Starting port forwarding for Kibana..."
	nohup kubectl port-forward -n elk svc/kibana 5601:5601 > /dev/null 2>&1 &
	@echo "Kibana 포트 포워딩이 시작되었습니다. localhost:5601 Kafka에 접속할 수 있습니다."

# Help command
es-help:
	@echo "Available commands:"
	@echo "  make all        - Install all tools and deploy ELK stack"
	@echo "  make prepare    - Restart Minikube and redeploy ELK stack"
	@echo "  make setup      - Install all required tools"
	@echo "  make start      - Start Minikube cluster"
	@echo "  make status     - Check cluster status"
	@echo "  make deploy-namespace-elk    - Create ELK namespace"
	@echo "  make deploy-pv          - Deploy Elasticsearch PV"
	@echo "  make deploy-config      - Deploy Elasticsearch ConfigMap"
	@echo "  make deploy-elasticsearch - Deploy Elasticsearch"
	@echo "  make deploy-kibana       - Deploy Kibana"
	@echo "  make clean-namespace    - Clean up ELK namespace"
	@echo "  make clean-pv          - Clean up Elasticsearch PV"
	@echo "  make clean-config      - Clean up Elasticsearch ConfigMap"
	@echo "  make clean-elasticsearch - Clean up Elasticsearch"
	@echo "  make clean-kibana       - Clean up Kibana"
	@echo "  make port-forward-es   - Start port forwarding for ES"
	@echo "  make port-forward-kibana   - Start port forwarding for Kibana"
