@echo off
REM ============================
REM Jenkins Master + Single Agent Setup with Full Logs
REM ============================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- CONFIGURATION ---
SET MASTER_IMAGE=my-jenkins-master
SET AGENT_IMAGE=my-jenkins-agent
SET NETWORK_NAME=jenkins
SET JENKINS_HOME=%cd%\jenkins-data
SET SSH_PUBKEY=%cd%\jenkins.pub
SET AGENT_NAME=jenkins-agent-1
SET LOG_DIR=%cd%\logs
SET MASTER_DOCKERFILE=JenkinsContainer\dockerfile
SET AGENT_DOCKERFILE=AgentContainer\dockerfile

REM --- CREATE LOG DIRECTORY ---
IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"

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

REM --- BUILD IMAGES WITH FULL LOGS ---
echo.
echo Building Jenkins Master...
docker build --progress=plain -t %MASTER_IMAGE% -f "%MASTER_DOCKERFILE%" . > "%LOG_DIR%\master-build.log" 2>&1
IF ERRORLEVEL 1 (
    echo ERROR: Failed to build Jenkins Master. Check "%LOG_DIR%\master-build.log".
    pause
    exit /b 1
)

echo.
echo Building Jenkins Agent...
docker build --progress=plain -t %AGENT_IMAGE% -f "%AGENT_DOCKERFILE%" . > "%LOG_DIR%\agent-build.log" 2>&1
IF ERRORLEVEL 1 (
    echo ERROR: Failed to build Jenkins Agent. Check "%LOG_DIR%\agent-build.log".
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
    %MASTER_IMAGE% > "%LOG_DIR%\master-run.log" 2>&1

echo Waiting 30 seconds for Jenkins Master to initialize...
timeout /t 30 >nul

REM --- START SINGLE AGENT ---
echo.
echo Starting agent: !AGENT_NAME!...
docker run -d --name !AGENT_NAME! ^
    --network %NETWORK_NAME% ^
    -e JENKINS_AGENT_SSH_PUBKEY="%SSH_PUBKEY%" ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    %AGENT_IMAGE% > "%LOG_DIR%\agent-run.log" 2>&1

    docker run -d --name jenkins-agent-1 ^
    --network jenkins ^
    -e JENKINS_AGENT_SSH_PUBKEY="jenkins.pub" ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    my-jenkins-agent

echo Waiting 10 seconds for agent to register...
timeout /t 10 >nul

REM --- SHOW INITIAL PASSWORD ---
SET INITIAL_PASSWORD=
FOR /F "tokens=*" %%p IN ('docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword 2^>nul') DO SET INITIAL_PASSWORD=%%p

echo.
echo Jenkins Web UI: http://localhost:8080
IF "!INITIAL_PASSWORD!"=="" (
    echo WARNING: Initial password not ready yet. Check logs in "%LOG_DIR%".
) ELSE (
    echo Initial Admin Password: !INITIAL_PASSWORD!
)

REM --- SHOW AGENT INFO ---
echo.
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
echo Jenkins setup complete. Full logs stored in "%LOG_DIR%".
pause