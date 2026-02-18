#!/bin/bash
# Ubuntu 배포 스크립트
# 사용 방법: chmod +x deploy.sh && ./deploy.sh

set -e  # 에러 발생시 스크립트 중지

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=========================================="
echo -e "  Ubuntu 배포 스크립트 시작"
echo -e "==========================================${NC}\n"

# 빌드 실행 여부 확인
if [ "$1" == "-b" ] || [ "$1" == "--build" ]; then
    echo -e "${CYAN}[1/4] Gradle 빌드 중...${NC}"
    bash ./gradlew build
    if [ $? -ne 0 ]; then
        echo -e "${RED}빌드 실패!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ 빌드 완료${NC}\n"
fi

# 배포 디렉토리 생성
echo -e "${CYAN}[2/4] 배포 디렉토리 확인...${NC}"
APP_DIR="$HOME/app"
mkdir -p "$APP_DIR"
echo -e "${GREEN}✓ 디렉토리 확인: $APP_DIR${NC}\n"

# JAR 파일 검색
echo -e "${CYAN}[3/4] JAR 파일 검색 중...${NC}"
JAR_FILE=$(ls -1 build/libs/*.jar 2>/dev/null | grep -v plain | head -1)

if [ -z "$JAR_FILE" ]; then
    echo -e "${RED}오류: build/libs에서 JAR 파일을 찾을 수 없습니다${NC}"
    echo -e "${CYAN}먼저 빌드를 실행하세요: ./deploy.sh --build${NC}"
    exit 1
fi

JAR_NAME=$(basename "$JAR_FILE")
echo -e "${GREEN}✓ JAR 파일 찾음: $JAR_NAME${NC}\n"

# 배포 진행
echo -e "${CYAN}[4/4] 배포 진행 중...${NC}"
echo -e "  → 기존 프로세스 중지..."

# 기존 Java 프로세스 중지
if pgrep -f "home.jar" > /dev/null; then
    pkill -f "home.jar" || true
    sleep 2
    echo -e "    ${GREEN}✓ 프로세스 중지 완료${NC}"
else
    echo -e "    (실행 중인 프로세스 없음)"
fi

echo -e "  → JAR 파일 복사 중..."
cp "$JAR_FILE" "$APP_DIR/home.jar"
chmod +x "$APP_DIR/home.jar"
echo -e "    ${GREEN}✓ 복사 완료: $APP_DIR/home.jar${NC}"

echo -e "  → 애플리케이션 시작 중..."
nohup java -jar "$APP_DIR/home.jar" > "$APP_DIR/app.log" 2>&1 &
sleep 3
echo -e "    ${GREEN}✓ 애플리케이션 시작됨${NC}"

# 완료 메시지
echo ""
echo -e "${GREEN}=========================================="
echo -e "✓ 배포 완료!"
echo -e "==========================================${NC}"
echo -e "${CYAN}앱 실행 위치: $APP_DIR/home.jar"
echo -e "로그 위치: $APP_DIR/app.log"
echo -e "로그 확인: tail -f $APP_DIR/app.log"
echo -e "프로세스 확인: ps aux | grep home.jar"
echo -e "앱 중지: pkill -f home.jar${NC}"
echo ""

