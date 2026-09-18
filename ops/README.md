# Jenkins 자동 배포

이 설정은 `main`을 1분마다 확인하고 변경이 있을 때 테스트, JAR 빌드,
배포, `home.service` 재시작, HTTP 상태 확인을 수행합니다.
폴링 주기 외에 대기열과 빌드 시간이 추가됩니다. 배포 실패 시 이전 JAR가
있으면 복구를 시도하고 Jenkins 작업은 실패로 표시합니다.
재시작 동안 짧은 서비스 중단이 있으며, 현재 H2 메모리 DB 데이터는 재시작 시 사라집니다.

## 1. 저장소 반영 및 서버 준비 (한 번)

현재 변경 파일은 `/home/gim/home`의 로컬 작업 트리에 있습니다.
연결된 GitHub 앱은 쓰기 요청에 403을 반환했으므로 원격 저장소는 아직 바뀌지 않았습니다.
GitHub 쓰기 인증이 된 터미널에서 다음과 같이 반영합니다.

```bash
cd /home/gim/home
git diff
git add Jenkinsfile ops .github/workflows/Deploy.yml
git commit -m "Configure Jenkins build and systemd deployment"
git push origin main
```

HTTPS push에 인증이 필요하면 해당 터미널의 GitHub 인증 수단을 사용하세요.
원격 `main`이 먼저 변경되어 push가 거부되면 변경을 통합한 뒤 다시 push하고 강제 push는 하지 마세요.

이 저장소의 변경을 `main`에 반영한 뒤 앱을 실행할 서버에서:

```bash
cd /home/gim/home
sudo bash ops/setup-server.sh
```

Java 25, Git, curl, Python 3, flock, systemd, Jenkins의 `jenkins` OS 계정이 필요합니다.
스크립트는 앱 전용 `home-app` 사용자를 만들고 `/opt/home-app`을 Jenkins에
할당합니다. 앱 데이터 경로는 `/var/lib/home-app`이고 서비스는 Java 25를
가리키는 `/usr/bin/java`를 사용합니다. Jenkins에는 `home.service`의
restart/stop 명령만 암호 없이 실행하도록 허용합니다.
서비스를 부팅 시 실행하도록 등록하지만 첫 JAR 배포 전에는 시작하지 않습니다.
기존 `home.service`가 있으면 덮어쓰지 않고 중단합니다.

## 2. Jenkins 실행 노드

Jenkins 관리 → Nodes에서 **이 앱 서버에서 `jenkins` 사용자로 실행되는 노드**에
`home-deploy` 라벨을 붙이고 실행 수(Executors)를 1 이상으로 설정합니다.
노드에 Java 25가 설치되어 있어야 합니다. 다른 서버의 노드에 이 라벨을 붙이면 안 됩니다.

현재 확인한 서버는 기본 노드의 실행 수가 0이고 `start` 노드의 Remote root directory가
`0`입니다. `start`를 사용할 경우 `/var/lib/jenkins/agent`처럼 쓰기 가능한 절대 경로로
수정하고, 노드 화면의 실행 방법에 따라 이 서버에서 에이전트를 연결해 Online 상태를 확인하세요.
에이전트 비밀키는 저장소에 기록하지 마세요.

개인 서버에서 간단하게 먼저 연결하려면 Built-In Node의 실행 수를 1로,
라벨을 `home-deploy`로 설정해 사용할 수 있습니다. 이 경우 빌드는 Jenkins 컨트롤러에서
실행됩니다. 별도 에이전트 사용 시 기본 노드의 실행 수는 0으로 유지합니다.

## 3. Pipeline 작업 생성

Jenkins에서 New Item → 이름 `home-deploy` → **Pipeline**을 선택합니다.

| 항목 | 값 |
| --- | --- |
| Definition | Pipeline script from SCM |
| SCM | Git |
| Repository URL | `https://github.com/r2d2c2/home.git` |
| Credentials | 공개 저장소이므로 비워 두기 |
| Branch Specifier | `*/main` |
| Script Path | `Jenkinsfile` |

저장 후 **Build Now를 한 번 실행**합니다. 첫 실행에서 Jenkinsfile의 폴링 설정이 등록됩니다.
그 뒤 `main`에 push하면 변경 감지 → 빌드/테스트 → 배포가 자동으로 진행됩니다.
테스트 실패 시 배포 단계는 실행되지 않습니다. 다른 브랜치 push는 배포하지 않습니다.
중복 배포를 막기 위해 기존 GitHub Actions `Deploy.yml`은 제거했습니다.
기존 `deploy.sh`는 이 Jenkins 파이프라인에서 사용하지 않습니다.

## 4. 확인

```bash
systemctl status home.service --no-pager
curl --fail http://127.0.0.1:9090/actuator/health
sudo journalctl -u home.service -n 100 --no-pager
```

Jenkins 콘솔에서 Build and test, Archive, Deploy가 성공했는지 확인합니다.
이후 실제 변경을 `main`에 push해 **수동 실행 없이** 새 빌드가 시작되는지 확인합니다.
복구는 JAR만 대상으로 하며 데이터베이스 변경을 되돌리지 않습니다.

## 즉시 실행하는 웹훅으로 전환 (선택)

현재 Jenkins 설정 주소는 `http://100.116.31.96:8080/`이므로 GitHub에서 직접 접근 가능한
공개 주소가 확인되지 않았습니다. 기본 폴링 방식은 외부 인바운드 접속이 필요 없습니다.

공개 HTTPS 주소를 준비한 경우 Jenkins GitHub 플러그인의 웹훅 설정과 공유 비밀값을 구성하고,
GitHub 저장소 Settings → Webhooks에 `https://<Jenkins주소>/github-webhook/`를 등록합니다.
Content type은 `application/json`, 이벤트는 Push를 선택합니다.
그 뒤 Jenkinsfile의 `pollSCM('* * * * *')`를 `githubPush()`로 변경하고 한 번 실행합니다.
GitHub의 Recent Deliveries와 실제 push로 작동을 확인합니다.

참고: [Jenkins Pipeline 문법](https://www.jenkins.io/doc/book/pipeline/syntax/),
[Jenkins GitHub 플러그인](https://plugins.jenkins.io/github/).
