# 배포 설정 가이드

## 자동 배포 구성

`main` 브랜치에 push하면 자동으로 배포됩니다.

### 설정 옵션

#### 옵션 1: Root 권한 없이 (권장 - 가장 간단)
현재 runner를 실행하는 사용자로 직접 배포하는 방식입니다.

**서버 설정 (최소한):**

1. **배포 디렉토리 준비** (runner 사용자가 소유)
```bash
mkdir -p ~/app
# 예: /home/runner/app
```

2. **배포 워크플로우는 자동으로:**
   - 빌드된 JAR를 `~/app/home.jar`로 복사
   - 기존 프로세스 중지 (있으면)
   - 새 JAR 시작

**장점:** 권한 설정 간단, sudo 불필요, 빠른 배포

---

#### 옵션 2: systemd 서비스 사용 (안정적)
systemd로 관리하되, sudo 암호 없이 설정

**1단계: 서비스 파일 생성** (한 번만)

루트 권한으로 `/etc/systemd/system/home.service` 생성:

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

**2단계: sudoers 설정** (한 번만)

```bash
sudo visudo

# 다음 줄 추가 (runner 사용자명 확인 필수):
runner ALL=(ALL) NOPASSWD: /bin/systemctl restart home
```

**3단계: 서비스 활성화** (한 번만)

```bash
sudo systemctl daemon-reload
sudo systemctl enable home
sudo systemctl start home
```

**4단계: 배포 디렉토리 준비** (한 번만)

```bash
mkdir -p ~/app
# 서비스가 runner 사용자로 실행되므로 권한 설정 불필요
```

---

### 현재 권장 설정: 옵션 1 (Root 권한 없음)

**Deploy.yml 수정:**

### 배포 프로세스

1. 로컬에서 코드 수정 후 `main` 브랜치에 push
2. GitHub Actions가 자동으로:
   - 코드 체크아웃
   - Java 25 설치
   - Gradle build 실행
   - 빌드된 JAR를 `/home/app/home.jar`로 복사
   - `home` 서비스 재시작

### 배포 상태 확인

```bash
# 서비스 상태 확인
sudo systemctl status home

# 서비스 로그 확인
sudo journalctl -u home -f
```

### 문제 해결

**JAR 파일이 복사되지 않는 경우:**
- `/home/app` 디렉토리 권한 확인
- runner 사용자 권한 확인

**서비스 재시작 실패:**
- sudoers 설정 재확인
- `sudo systemctl restart home` 수동 실행 테스트

**배포 후 앱이 시작되지 않는 경우:**
- `sudo journalctl -u home -f`로 로그 확인
- Java 25 설치 확인
- 포트 충돌 확인 (기본값: 9090)

