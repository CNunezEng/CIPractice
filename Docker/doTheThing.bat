@echo off
REM ============================
REM Jenkins Master + Single Agent Setup (Clean & Verified)
REM ============================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- CONFIGURATION ---
SET MASTER_IMAGE=my-jenkins-master
SET AGENT_IMAGE=my-jenkins-agent
SET NETWORK_NAME=jenkins
SET JENKINS_HOME=%cd%\jenkins-data
SET SSH_PUBKEY=%cd%\jenkins.pub
SET AGENT_NAME=jenkins-agent-1
SET MASTER_DOCKERFILE=JenkinsContainer\dockerfile
SET AGENT_DOCKERFILE=AgentContainer\dockerfile

REM --- VERIFY DOCKERFILES EXIST ---
IF NOT EXIST "%MASTER_DOCKERFILE%" (
    echo ERROR: Jenkins Master Dockerfile not found at "%MASTER_DOCKERFILE%".
    pause
    exit /b 1
)
IF NOT EXIST "%AGENT_DOCKERFILE%" (
    echo ERROR: Jenkins Agent Dockerfile not found at "%AGENT_DOCKERFILE%".
    pause
    exit /b 1
)
echo Dockerfiles verified.

REM --- CLEANUP previous runs ---
echo Cleaning up previous Jenkins containers and network...
docker stop jenkins-master !AGENT_NAME! >nul 2>&1
docker rm jenkins-master !AGENT_NAME! >nul 2>&1
docker network rm %NETWORK_NAME% >nul 2>&1

REM --- CREATE NETWORK ---
docker network create %NETWORK_NAME% >nul 2>&1
echo Docker network "%NETWORK_NAME%" ready.

REM --- BUILD IMAGES ---
echo.
echo Building Jenkins Master...
docker build -t %MASTER_IMAGE% -f "%MASTER_DOCKERFILE%" .
IF ERRORLEVEL 1 (
    echo ERROR: Failed to build Jenkins Master. Check Dockerfile syntax.
    pause
    exit /b 1
)

echo.
echo Building Jenkins Agent...
docker build -t %AGENT_IMAGE% -f "%AGENT_DOCKERFILE%" .
IF ERRORLEVEL 1 (
    echo ERROR: Failed to build Jenkins Agent. Check Dockerfile syntax.
    pause
    exit /b 1
)

REM --- START MASTER ---
echo.
echo Starting Jenkins Master...
docker run -d --name jenkins-master ^
    --network %NETWORK_NAME% ^
    -p 8080:8080 -p 50000:50000 ^
    -v "%JENKINS_HOME%:/var/jenkins_home" ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    %MASTER_IMAGE%

echo Waiting 30 seconds for Jenkins Master to initialize...
timeout /t 30 >nul

REM --- START SINGLE AGENT ---
echo.
echo Starting agent: !AGENT_NAME!...
docker run -d --name !AGENT_NAME! ^
    --network %NETWORK_NAME% ^
    -e JENKINS_AGENT_SSH_PUBKEY="%SSH_PUBKEY%" ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    %AGENT_IMAGE%

echo Waiting 10 seconds for agent to register...
timeout /t 10 >nul

REM --- SHOW INITIAL PASSWORD ---
SET INITIAL_PASSWORD=
FOR /F "tokens=*" %%p IN ('docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword 2^>nul') DO SET INITIAL_PASSWORD=%%p

echo.
echo Jenkins Web UI: http://localhost:8080
IF "!INITIAL_PASSWORD!"=="" (
    echo WARNING: Initial password not ready yet. Check container logs.
) ELSE (
    echo Initial Admin Password: !INITIAL_PASSWORD!
)
echo.

REM --- SHOW AGENT INFO ---
echo Agent Name   ^| IP Address
echo ----------------+----------------
FOR /F "delims=" %%a IN ('docker inspect -f "{{.NetworkSettings.Networks.%NETWORK_NAME%.IPAddress}}" !AGENT_NAME! 2^>nul') DO (
    IF "%%a"=="" (
        echo !AGENT_NAME!   ^| ERROR
    ) ELSE (
        echo !AGENT_NAME!   ^| %%a
    )
)

echo.
echo Jenkins setup complete. Master + one agent ready.
pause