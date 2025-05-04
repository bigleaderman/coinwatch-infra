# coinwatch-infra
coinwatch application의 인프라 관련 자료들을 모아놓은 repository입니다.

## 디렉토리 구조

```
project-root/
├── infra/
│   ├── kafka.local.yaml
│   └── kafka-ui.yaml
│   └── elk/
│       ├── elasticsearch.yaml        # Elasticsearch 배포 설정
│       ├── kibana.yaml              # Kibana 배포 설정
│       ├── elasticsearch-pv.yaml    # Elasticsearch PV 설정
│       ├── elasticsearch-config.yaml # Elasticsearch ConfigMap 설정
│       ├── namespace.yaml           # ELK 네임스페이스 설정
│       └── generate_test_data.sh    # 테스트 데이터 생성 스크립트
├── Makefile
└── README.md
```

# 로컬 개발 환경 구축 가이드

이 가이드는 로컬 환경에서 **Minikube**를 사용하여 **ELK 스택**을 설정하고 관리하는 방법을 설명합니다. 이 과정은 **Docker**, **Minikube**, **kubectl** 등이 설치되어 있는 macOS 환경을 기준으로 작성되었습니다.

## 요구 사항

이 가이드에 따라 로컬 환경을 설정하기 위해 필요한 도구는 다음과 같습니다:

- **Homebrew**: macOS용 패키지 관리 도구
- **Docker Desktop**: 로컬에서 컨테이너를 실행할 수 있는 환경
- **Minikube**: 로컬 Kubernetes 클러스터
- **kubectl**: Kubernetes 클러스터 관리 도구
- **Make**: 빌드 자동화 도구 (macOS 기본 제공)

## 설치 순서

### 1. 전체 설치 (권장)

모든 도구를 설치하고 ELK 스택을 배포하려면:

```bash
make all
```

이 명령어는 다음 작업을 순차적으로 실행합니다:
1. 모든 필수 도구 설치 (Homebrew, kubectl, Minikube, Docker)
2. Minikube 클러스터 시작
3. ELK 네임스페이스 생성
4. Elasticsearch PV 배포
5. Elasticsearch ConfigMap 배포
6. Elasticsearch 배포
7. Kibana 배포
8. 테스트 데이터 생성 및 인덱싱
9. 클러스터 상태 확인

### 2. 재시작 (Minikube 재시작 후)

```bash
make kubectl
```

### 3. Minikube 설치 및 클러스터 시작

Minikube는 로컬에서 Kubernetes 클러스터를 실행할 수 있도록 해줍니다. Docker 드라이버를 사용하여 클러스터를 시작하려면 아래 명령어를 실행하세요.

```bash
make minikube
make start
```

Minikube 클러스터가 성공적으로 시작되면 `minikube status` 명령어로 상태를 확인할 수 있습니다.

### 4. Docker Desktop 설치

Docker Desktop은 컨테이너 환경을 로컬에서 제공해줍니다. Docker Desktop을 설치하고 실행하려면 아래 명령어를 실행하세요.

```bash
make docker
```

설치 후 Docker Desktop을 수동으로 실행하고, 정상적으로 동작하는지 확인하세요.

### 5. Helm 설치

Helm은 Kubernetes에서 애플리케이션을 관리하는 도구입니다. Helm을 설치하려면 아래 명령어를 실행하세요.

```bash
make helm
```

설치 후 `helm version` 명령어로 Helm 버전을 확인할 수 있습니다.

### 6. Kafka KRaft 모드 설치 (Zookeeper 없음)

KRaft 모드는 Zookeeper 없이 Kafka를 실행하는 방식입니다. 이 방식을 사용하려면 아래 명령어를 실행하세요.

```bash
# Kafka KRaft 모드 설치
make setup-kafka

# Kafka UI 설치 (선택사항)
make setup-ui

# 또는 한 번에 둘 다 설치
make setup-kafka-all
```

### 7. 클러스터 상태 확인

Minikube 클러스터 상태를 확인하고, 현재 실행 중인 모든 Pod를 조회하려면 아래 명령어를 실행하세요.

```bash
make status
```

## Kafka KRaft 모드 사용 가이드

KRaft 모드의 Kafka는 Zookeeper 없이 더 간단하게 운영할 수 있습니다. 다음은 KRaft 모드 Kafka를 사용하는 방법입니다.

### Kafka KRaft 설정 및 관리

```bash
# Kafka KRaft와 UI 모두 설치
make setup-kafka-all

# 포트 포워딩 시작
make forward-port  # Kafka (9092)
make forward-ui    # Kafka UI (8080)

# 토픽 생성
make create-topic

# 테스트 컨슈머 시작
make start-consumer

# 삭제
make delete-kafka      # Kafka만 삭제
make delete-ui         # UI만 삭제
make delete-kafka-all  # 모두 삭제
```

### Kafka UI 접속

Kafka UI는 웹 브라우저를 통해 Kafka 클러스터를 관리할 수 있는 도구입니다.

1. 포트 포워딩 시작:
   ```bash
   make forward-ui
   ```

2. 웹 브라우저에서 다음 URL 접속:
   ```
   http://localhost:8080
   ```

## Makefile 설명

이 `Makefile`은 로컬 환경을 자동으로 설정하고 관리하는 데 사용됩니다. 주요 타겟 및 명령어는 다음과 같습니다:

### 주요 타겟

- **brew**: Homebrew 설치
- **kubectl**: kubectl 설치
- **minikube**: Minikube 설치 및 클러스터 시작
- **docker**: Docker Desktop 설치
- **helm**: Helm 설치
- **start**: Minikube 클러스터 시작
- **setup-kafka**: Kafka KRaft 모드 설치 (Zookeeper 없음)
- **setup-ui**: Kafka UI 설치
- **setup-kafka-all**: Kafka KRaft와 UI 모두 설치
- **forward-port**: Kafka 포트 포워딩 (9092)
- **forward-ui**: Kafka UI 포트 포워딩 (8080)
- **create-topic**: Kafka 토픽 생성
- **flink**: Flink 설치 (Bitnami Helm 차트 사용)
- **status**: Minikube 클러스터 상태 확인

### 설치 관련 설정

`setup` 타겟은 필요한 모든 도구를 설치합니다:

```bash

make setup
```

### Minikube 클러스터 준비

`prepare` 타겟은 이미 Minikube 클러스터가 실행 중인 경우 Kafka와 Flink를 설치하고, 클러스터 상태를 확인하는 역할을 합니다:

```bash
make prepare
```

### 전체 실행

`all` 타겟은 모든 단계를 한 번에 실행합니다:

```
make all
```

## 주의사항

- **Minikube와 Docker**: Minikube를 Docker 드라이버로 실행할 때 Docker Desktop이 실행 중이어야 합니다.
- **포트 충돌**: Kafka와 Zookeeper가 사용하는 포트(예: 9092, 2181)가 다른 서비스와 충돌하지 않도록 확인하세요.
- **리소스**: `values.yaml` 파일을 통해 Kafka, Zookeeper, Flink의 리소스를 설정할 수 있습니다. 필요에 따라 리소스를 조정하세요.
- **macOS Docker 드라이버**: macOS에서 Docker 드라이버를 사용할 때는 네트워크 이슈가 발생할 수 있습니다. 이 경우 포트 포워딩을 사용하세요.


# 자동 - 로컬환경 구성 가이드(Minikube)

### 📝 사용 방법.

1. 터미널에서 해당 디렉토리로 이동합니다.
2. 원하는 타겟 실행:

```bash
make all          # 전체 설치 및 클러스터 실행
make kubectl      # kubectl만 설치
make docker       # Docker만 설치
make helm         # helm 설치
make start        # Minikube 클러스터 실행
make setup-kafka  # Kafka KRaft 모드 설치
make setup-ui     # Kafka UI 설치
make forward-port # Kafka 포트 포워딩
```

------

### ⚠️ 참고 사항

- Docker Desktop 설치 후에는 수동으로 앱을 실행해줘야 합니다 (`Applications` 폴더에서 실행 또는 Spotlight).
- Homebrew가 이미 설치되어 있다면 `make brew`는 생략해도 무방합니다.
- macOS에서 포트 포워딩이 필요한 경우 `make forward-port`와 `make forward-ui`를 사용하세요.


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

이 명령어는 다음 작업을 순차적으로 실행합니다:
1. Minikube 클러스터 시작
2. ELK 네임스페이스 생성
3. Elasticsearch PV 배포
4. Elasticsearch ConfigMap 배포
5. Elasticsearch 배포
6. Kibana 배포
7. 테스트 데이터 생성 및 인덱싱
8. 클러스터 상태 확인

### 3. 수동 설치 (선택적)

필요한 경우 각 단계를 수동으로 실행할 수 있습니다:

1. 기본 도구 설치:
   ```bash
   make setup
   ```

2. Minikube 클러스터 시작:
   ```bash
   make start
   ```

3. ELK 네임스페이스 생성:
   ```bash
   make deploy-namespace
   ```

4. Elasticsearch PV 배포:
   ```bash
   make deploy-pv
   ```

5. Elasticsearch ConfigMap 배포:
   ```bash
   make deploy-config
   ```

6. ELK 스택 배포:
   ```bash
   make deploy-elasticsearch
   make deploy-kibana
   ```

7. 테스트 데이터 생성:
   ```bash
   make reindex-elasticsearch
   ```

8. Kibana 접근:
   ```bash
   make port-forward-kibana
   ```
   그 후 웹 브라우저에서 `http://localhost:5601`로 접속합니다.

## 사용 가능한 명령어

- `make all`: 모든 도구 설치 및 ELK 스택 배포
- `make prepare`: Minikube 재시작 및 ELK 스택 재배포
- `make setup`: 기본 도구 설치 (Homebrew, kubectl, Minikube, Docker)
- `make start`: Minikube 클러스터 시작
- `make status`: 클러스터 상태 확인
- `make deploy-namespace`: ELK 네임스페이스 생성
- `make deploy-pv`: Elasticsearch PV 배포
- `make deploy-config`: Elasticsearch ConfigMap 배포
- `make deploy-elasticsearch`: Elasticsearch 배포
- `make deploy-kibana`: Kibana 배포
- `make clean-namespace`: ELK 네임스페이스 정리
- `make clean-pv`: Elasticsearch PV 정리
- `make clean-config`: Elasticsearch ConfigMap 정리
- `make clean-elasticsearch`: Elasticsearch 리소스 정리
- `make clean-kibana`: Kibana 리소스 정리
- `make reindex-elasticsearch`: 테스트 데이터 생성 및 인덱싱
- `make port-forward-kibana`: Kibana 포트 포워딩 시작
- `make help`: 사용 가능한 명령어 목록 표시

## 문제 해결

문제가 발생한 경우:

1. 클러스터 상태 확인:
   ```bash
   make status
   ```

2. Pod 로그 확인:
   ```bash
   kubectl logs <pod-name> -n elk
   ```

3. Pod가 CrashLoopBackOff 상태인 경우:
   ```bash
   make clean-elasticsearch
   make clean-kibana
   make clean-pv
   make clean-config
   make deploy-pv
   make deploy-config
   make deploy-elasticsearch
   make deploy-kibana
   ```

## 참고 사항

- 이 설정은 제한된 리소스의 Minikube에 최적화되어 있습니다
- 테스트 데이터는 실시간 암호화폐 거래 패턴을 모방하여 생성됩니다
- Kibana는 "test-data*" 인덱스 패턴으로 구성되어 있습니다
- Elasticsearch 데이터는 PV를 통해 영구적으로 저장됩니다
- ConfigMap을 통해 Elasticsearch의 설정을 관리합니다


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
