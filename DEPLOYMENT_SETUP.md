# Ubuntu 배포 설정 가이드

## 🚀 자동 배포 개요

`main` 브랜치에 push하면 **Ubuntu 서버에서 자동으로 배포됩니다.**

---

## 📦 빠른 시작 (Ubuntu 서버에서 한 번만 설정)

### 1단계: Self-hosted Runner 설정

GitHub 저장소 → Settings → Actions → Runners에서 제공하는 명령어 실행:

```bash
# 1. Runner 디렉토리 생성 및 다운로드
mkdir -p ~/actions-runner
cd ~/actions-runner
curl -o actions-runner-linux-x64-2.321.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-linux-x64-2.321.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.321.0.tar.gz

# 2. Runner 설정 및 등록 (GitHub에서 제공하는 토큰 사용)
./config.sh --url https://github.com/YOUR_USERNAME/home --token YOUR_TOKEN

# 3. Runner 서비스로 설치 (자동 재시작 설정)
sudo ./svc.sh install
sudo ./svc.sh start

# 4. 상태 확인
sudo ./svc.sh status
```

### 2단계: 배포 디렉토리 준비

```bash
mkdir -p ~/app
chmod 755 ~/app
```

### 3단계: 배포! (자동)

```bash
git add .
git commit -m "배포: 내용 수정"
git push origin main
```

---

## 🔧 배포 프로세스 흐름

```
로컬 PC (Windows)
    ↓
git push origin main
    ↓
GitHub Actions 자동 실행
  ├─ Checkout 코드
  ├─ Java 25 설정
  ├─ Gradle 빌드
  └─ Bash 배포 스크립트 실행
    ↓
Ubuntu Self-hosted Runner
  ├─ JAR 파일 검색
  ├─ 기존 프로세스 중지 (pkill)
  ├─ JAR 파일을 ~/app/home.jar로 복사
  ├─ nohup으로 백그라운드 실행
  └─ 로그 저장 (~/app/app.log)
    ↓
배포 완료! ✓
```

---

## 🐧 Ubuntu에서 수동 배포 (테스트용)

### 빌드 + 배포

```bash
cd ~/your_project_directory
chmod +x deploy.sh
./deploy.sh --build
```

### JAR만 배포 (빌드 생략)

```bash
./deploy.sh
```

### 배포 스크립트 출력 예시

```
==========================================
  Ubuntu 배포 스크립트 시작
==========================================

[2/4] 배포 디렉토리 확인...
✓ 디렉토리 확인: /home/ubuntu/app

[3/4] JAR 파일 검색 중...
✓ JAR 파일 찾음: home-0.0.1-SNAPSHOT.jar

[4/4] 배포 진행 중...
  → 기존 프로세스 중지...
    (실행 중인 프로세스 없음)
  → JAR 파일 복사 중...
    ✓ 복사 완료: /home/ubuntu/app/home.jar
  → 애플리케이션 시작 중...
    ✓ 애플리케이션 시작됨

==========================================
✓ 배포 완료!
==========================================
앱 실행 위치: /home/ubuntu/app/home.jar
로그 위치: /home/ubuntu/app/app.log
로그 확인: tail -f /home/ubuntu/app/app.log
프로세스 확인: ps aux | grep home.jar
앱 중지: pkill -f home.jar
```

---

## 🔍 배포 후 확인

### 실시간 로그 보기

```bash
tail -f ~/app/app.log
```

### 최근 로그 확인

```bash
tail -n 100 ~/app/app.log
```

### 프로세스 확인

```bash
ps aux | grep home.jar
# 또는
pgrep -a -f home.jar
```

### 포트 확인 (기본값: 9090)

```bash
# 9090 포트 사용 확인
sudo lsof -i :9090

# 또는
sudo netstat -tlnp | grep 9090

# 앱 정상 작동 확인
curl http://localhost:9090
```

---

## 🛑 앱 제어

### 앱 중지

```bash
pkill -f home.jar
```

### 앱 재시작

```bash
./deploy.sh
```

### 백그라운드에서 수동 실행

```bash
nohup java -jar ~/app/home.jar > ~/app/app.log 2>&1 &
```

### 포그라운드에서 실행 (종료할 때까지 로그 표시)

```bash
java -jar ~/app/home.jar
```

---

## ⚙️ 선택 사항: systemd 서비스로 자동 관리

### 서비스 파일 생성

```bash
sudo nano /etc/systemd/system/home.service
```

내용:

```ini
[Unit]
Description=Home Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/app
ExecStart=/usr/bin/java -jar /home/ubuntu/app/home.jar
Restart=on-failure
RestartSec=10
StandardOutput=append:/home/ubuntu/app/app.log
StandardError=append:/home/ubuntu/app/app.log

[Install]
WantedBy=multi-user.target
```

### 서비스 활성화

```bash
sudo systemctl daemon-reload
sudo systemctl enable home
sudo systemctl start home
sudo systemctl status home
```

### 서비스 로그 확인

```bash
sudo journalctl -u home -f
```

### 서비스 제어

```bash
# 시작
sudo systemctl start home

# 중지
sudo systemctl stop home

# 재시작
sudo systemctl restart home
```

---

## 🚨 문제 해결

### 1. Runner가 오프라인 상태

```bash
cd ~/actions-runner
sudo ./svc.sh restart
```

### 2. 배포 실패 (권한 문제)

```bash
# 디렉토리 권한 확인
ls -ld ~/app

# 필요시 권한 변경
chmod 755 ~/app
```

### 3. JAR 파일을 찾을 수 없음

```bash
# 먼저 빌드 실행
./gradlew build

# 그 후 배포
./deploy.sh
```

### 4. 포트 9090 이미 사용 중

포트 변경: `src/main/resources/application.properties`

```properties
server.port=8081
```

### 5. Java 버전 확인/설치

```bash
# 버전 확인
java -version

# 필요시 Java 25 설치
sudo apt update
sudo apt install openjdk-25-jdk
```

### 6. 프로세스 살펴보기

```bash
# 전체 Java 프로세스 보기
ps aux | grep java

# home.jar 프로세스만 보기
ps aux | grep home.jar

# 프로세스 상세 정보
ps -ef | grep home.jar
```

---

## 📝 배포 체크리스트

- [ ] Ubuntu 서버에 Self-hosted Runner 등록 완료
- [ ] `~/app` 디렉토리 생성 완료
- [ ] GitHub에 `deploy.sh` 스크립트 커밋 완료
- [ ] `main` 브랜치에 push하면 GitHub Actions 실행됨
- [ ] 배포 후 로그 확인: `tail -f ~/app/app.log`
- [ ] 앱 접속 테스트: `curl http://localhost:9090`

---

## 📚 파일 구조

```
your-project/
├── .github/
│   └── workflows/
│       └── Deploy.yml           # GitHub Actions 자동 배포 설정
├── deploy.sh                    # Ubuntu 수동 배포 스크립트
├── deploy.ps1                   # Windows 수동 배포 스크립트
├── DEPLOYMENT_SETUP.md          # 이 파일
└── src/
    └── main/
        └── resources/
            └── application.properties   # 포트 설정 등
```

---

## 🎯 다음 단계

1. Ubuntu 서버에서 Self-hosted Runner 설정 완료
2. `main` 브랜치에 코드 수정 후 push
3. GitHub Actions 탭에서 배포 상황 확인
4. Ubuntu 서버에서 `tail -f ~/app/app.log`로 로그 확인
5. `curl http://localhost:9090`으로 앱 정상 작동 확인

**배포 완료! 🎉**

