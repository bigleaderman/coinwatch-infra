# coinwatch-infra
coinwatch application의 인프라 관련 자료들을 모아놓은 repository입니다.

# 자동 - 로컬환경 구성 가이드(Minikube)

### 📝 사용 방법.

1. 터미널에서 해당 디렉토리로 이동합니다.
2. 원하는 타겟 실행:

```bash
make all          # 전체 설치 및 클러스터 실행
make kubectl      # kubectl만 설치
make docker       # Docker만 설치
make start        # Minikube 클러스터 실행
```

------

### ⚠️ 참고 사항

- Docker Desktop 설치 후에는 수동으로 앱을 실행해줘야 합니다 (`Applications` 폴더에서 실행 또는 Spotlight).
- Homebrew가 이미 설치되어 있다면 `make brew`는 생략해도 무방합니다.



## Makefile

```yaml
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

```





# 수동 - 로컬환경 구성 가이드(Minikube)

## ✅ 사전 확인

- 운영체제: macOS (Apple Silicon, M1 또는 M2 칩)

## 1. **Homebrew 설치 및 환경설정**

Homebrew는 macOS에서 필수 패키지를 설치할 수 있는 패키지 관리자입니다.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

## 2. **Kubectl 설치 (Kubernetes CLI)**

```bash
brew install kubectl
```

설치 확인:

```bash
kubectl version --client
```

------

## 3. **Minikube 설치**

```bash
brew install minikube
```

설치 확인:

```bash
minikube version
```

------

## 4. **가상화 드라이버 설치 (Apple Silicon에 적합한 방법)**

### 🧩 Apple Silicon에서는 기본적으로 **`docker` 드라이버** 사용 권장

→ **Docker Desktop 설치 필요**

```bash
brew install --cask docker
```

설치 후:

- Docker 앱 실행
- 메뉴바에서 "Docker Desktop is running" 상태 확인

> 📝 Docker Desktop은 M1/M2 칩에서 ARM 아키텍처에 최적화된 버전을 제공합니다.

------

## 5. **Minikube 클러스터 생성**

```bash
minikube start --driver=docker --cpus=6 --memory=7g
```

성공적으로 실행되면: 아래의 내용의 둘중에 하나가 나오게 됨

```bash
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default 
🏄  끝났습니다! kubectl이 "minikube" 클러스터와 "default" 네임스페이스를 기본적으로 사용하도록 구성되었습니다.
```



------

## 6. **동작 확인**

### 클러스터 상태 확인

```bash
minikube status
```

# Branch 전략

### 브랜치는 **브랜치(main)** + **기능 브랜치로 구분**

### 🔹 기본 브랜치 구성

| 브랜치             | 설명                                     |
| ------------------ | ---------------------------------------- |
| `main` or `master` | 🚀 실제 배포되는 최종 버전 (배포 시 사용) |
| `feature/*`        | ✨ 새로운 기능 개발 브랜치                |

🔧 예시 브랜치 흐름

```bash
main
  ├─ feature/login-page
  └─ feature/btc-streaming
```

## ✅ 2. 커밋 컨벤션 (Commit Convention)

### ✍️ 기본 형식 (Conventional Commits)

```bash
<타입>: <변경사항 요약>
```

| 타입       | 설명                             |
| ---------- | -------------------------------- |
| `feat`     | ✨ 새로운 기능 추가               |
| `fix`      | 🐞 버그 수정                      |
| `docs`     | 📝 문서 수정                      |
| `style`    | 💄 코드 포맷팅, 세미콜론 누락 등  |
| `refactor` | 🔨 코드 리팩토링 (기능 변화 없음) |
| `test`     | ✅ 테스트 추가 또는 수정          |
| `chore`    | 🔧 빌드, 설정 파일 등 수정        |
| `perf`     | 🚀 성능 개선                      |

### 🔧 커밋 예시

```bash
feat: 실시간 비트코인 데이터 차트 추가
fix: 스트리밍 연결 오류 수정
refactor: 데이터 파싱 로직 정리
docs: README에 프로젝트 설명 추가
```

