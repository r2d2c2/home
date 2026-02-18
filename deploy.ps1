# 배포 스크립트 (Windows PowerShell)
# 사용 방법: .\deploy.ps1

param(
    [switch]$Build = $false
)

# 색상 정의
function Write-Success {
    Write-Host $args -ForegroundColor Green
}

function Write-Error-Custom {
    Write-Host $args -ForegroundColor Red
}

function Write-Info {
    Write-Host $args -ForegroundColor Cyan
}

Write-Info "=========================================="
Write-Info "  배포 스크립트 시작"
Write-Info "=========================================="

# 빌드 실행 여부 확인
if ($Build) {
    Write-Info "`n[1/4] Gradle 빌드 중..."
    $buildResult = & .\gradlew.bat build
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "빌드 실패!"
        exit 1
    }
    Write-Success "✓ 빌드 완료"
}

# 배포 디렉토리 생성
Write-Info "`n[2/4] 배포 디렉토리 확인..."
$appDir = "$HOME/app"
if (!(Test-Path $appDir)) {
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    Write-Success "✓ 디렉토리 생성: $appDir"
}
else {
    Write-Success "✓ 디렉토리 존재: $appDir"
}

# JAR 파일 검색
Write-Info "`n[3/4] JAR 파일 검색 중..."
$jarFile = Get-ChildItem -Path "build/libs" -Filter "*.jar" | Where-Object { $_.Name -notlike "*plain*" } | Select-Object -First 1

if ($null -eq $jarFile) {
    Write-Error-Custom "오류: build/libs에서 JAR 파일을 찾을 수 없습니다"
    Write-Info "먼저 빌드를 실행하세요: .\deploy.ps1 -Build"
    exit 1
}

Write-Success "✓ JAR 파일 찾음: $($jarFile.Name)"

# 기존 프로세스 중지
Write-Info "`n[4/4] 배포 진행 중..."
Write-Host "  → 기존 프로세스 중지..."

$javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*home.jar*" }
if ($null -ne $javaProcesses) {
    $javaProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "    ✓ 프로세스 중지 완료"
}
else {
    Write-Host "    (실행 중인 프로세스 없음)"
}

# JAR 파일 복사
Write-Host "  → JAR 파일 복사 중..."
Copy-Item -Path $jarFile.FullName -Destination "$appDir/home.jar" -Force
Write-Host "    ✓ 복사 완료: $appDir/home.jar"

# 애플리케이션 시작
Write-Host "  → 애플리케이션 시작 중..."
Start-Process java -ArgumentList "-jar", "$appDir/home.jar" -NoNewWindow
Start-Sleep -Seconds 3

# 완료 메시지
Write-Success "`n=========================================="
Write-Success "✓ 배포 완료!"
Write-Success "=========================================="
Write-Info "애플리케이션 주소: http://localhost:8080"
Write-Info "종료하려면: Ctrl+C"
Write-Info ""

