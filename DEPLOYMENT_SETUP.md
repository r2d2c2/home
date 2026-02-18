# 배포 설정 가이드

## 자동 배포 구성

`main` 브랜치에 push하면 **Linux 서버에서 자동으로 배포됩니다.**

### 📌 중요 사항

- **GitHub Actions는 Linux 환경에서 실행됩니다** (현재 Windows 로컬 환경과 다름)
- **Self-hosted runner는 Linux 서버에 구성되어야 합니다**
- Windows 환경에서의 테스트는 추가 설정이 필요합니다

---

## 설정 옵션

### 옵션 1: Root 권한 없이 (권장 - 가장 간단)
현재 runner를 실행하는 사용자로 직접 배포하는 방식입니다.

**Linux 서버 설정:**

```bash
# 배포 디렉토리 생성
mkdir -p ~/app
```

**배포 프로세스:**
- GitHub에 push → GitHub Actions 자동 실행
- Linux 서버에서:
  - Gradle 빌드 실행
  - JAR 파일 검색
  - 기존 Java 프로세스 중지
  - JAR 파일을 `~/app/home.jar`로 복사
  - 새 JAR 시작

**장점:** 권한 설정 간단, sudo 불필요

---

### 옵션 2: systemd 서비스 사용 (안정적)
systemd로 관리하되, sudo 암호 없이 설정

**Linux 서버 설정 (한 번만):**

#### 1단계: systemd 서비스 파일 생성

```bash
sudo vim /etc/systemd/system/home.service
```

파일 내용:
```ini
[Unit]
Description=Home Application
After=network.target

[Service]
Type=simple
User=runner
WorkingDirectory=/home/runner/app
ExecStart=/usr/bin/java -jar /home/runner/app/home.jar
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### 2단계: sudoers 설정

```bash
sudo visudo

# 다음 줄 추가:
runner ALL=(ALL) NOPASSWD: /bin/systemctl restart home
```

#### 3단계: 서비스 활성화

```bash
sudo systemctl daemon-reload
sudo systemctl enable home
sudo systemctl start home
```

#### 4단계: 배포 디렉토리 준비

```bash
mkdir -p ~/app
```

---

## 배포 방법

### GitHub에서 배포

1. 로컬에서 코드 수정
2. `main` 브랜치에 커밋 및 push:
   ```bash
   git add .
   git commit -m "Update: 배포 내용"
   git push origin main
   ```
3. GitHub Actions가 자동으로 배포 시작
4. Actions 탭에서 배포 상태 확인

### 배포 확인

**옵션 1 선택 시:**
```bash
# 애플리케이션 실행 확인
curl http://localhost:9090
# 또는 구성한 포트
```

**옵션 2 선택 시:**
```bash
# 서비스 상태 확인
sudo systemctl status home

# 로그 확인
sudo journalctl -u home -f
```

---

## 문제 해결

### 배포가 시작되지 않음
- **확인 사항:**
  - GitHub 저장소에 Self-hosted Runner 등록 되었는지 확인
  - Runner가 온라인 상태인지 확인
  - `.github/workflows/Deploy.yml` 파일 문법 확인

### Java 프로세스 시작 실패
- **로그 확인 (옵션 2):**
  ```bash
  sudo journalctl -u home -e
  ```
- **수동 시작 테스트:**
  ```bash
  java -jar ~/app/home.jar
  ```

### 포트 충돌
- **포트 확인:**
  ```bash
  # Linux
  sudo lsof -i :9090
  # 또는
  sudo netstat -tlnp | grep java
  ```
- **application.properties 수정:**
  ```properties
  server.port=9090
  ```

---

## 배포 워크플로우 구조

```
로컬 PC (Windows)
    ↓
GitHub Repository (main 브랜치 push)
    ↓
GitHub Actions (자동 실행)
    ├─ Checkout 코드
    ├─ Java 25 설정
    ├─ Gradle 빌드
    └─ 빌드 결과 출력 (Actions 로그)
    ↓
Linux Self-hosted Runner
    ├─ 빌드 결과 다운로드
    ├─ 기존 프로세스 중지
    ├─ JAR 파일 복사
    └─ 새 애플리케이션 시작
    ↓
배포 완료 ✓
```

