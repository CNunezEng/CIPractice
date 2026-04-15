@echo off
REM ============================
REM Jenkins Master + Single Agent Restart
REM ============================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- CONFIGURATION ---
SET NETWORK_NAME=jenkins
SET AGENT_NAME=jenkins-agent-1
SET MASTER_NAME=jenkins-master

REM --- CLEANUP previous containers (if any) ---
echo Stopping any running Jenkins containers...
docker stop %MASTER_NAME% %AGENT_NAME% >nul 2>&1

echo Removing old containers...
docker rm %MASTER_NAME% %AGENT_NAME% >nul 2>&1

REM --- CREATE NETWORK if missing ---
docker network inspect %NETWORK_NAME% >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Docker network "%NETWORK_NAME%" not found. Creating...
    docker network create %NETWORK_NAME% >nul 2>&1
) ELSE (
    echo Docker network "%NETWORK_NAME%" exists.
)

REM --- START MASTER ---
echo.
echo Starting Jenkins Master...
docker run -d --name %MASTER_NAME% ^
    --network %NETWORK_NAME% ^
    -p 8080:8080 -p 50000:50000 ^
    -v "%cd%\jenkins-data:/var/jenkins_home" ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    my-jenkins-master

echo Waiting 20 seconds for Jenkins Master to initialize...
timeout /t 20 >nul

REM --- START SINGLE AGENT ---
echo.
echo Starting agent: %AGENT_NAME%...
docker run -d --name %AGENT_NAME% ^
    --network %NETWORK_NAME% ^
    -e JENKINS_AGENT_SSH_PUBKEY="%cd%\jenkins.pub" ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    my-jenkins-agent

echo Waiting 10 seconds for agent to register...
timeout /t 10 >nul

REM --- SHOW INITIAL PASSWORD ---
SET INITIAL_PASSWORD=
FOR /F "tokens=*" %%p IN ('docker exec %MASTER_NAME% cat /var/jenkins_home/secrets/initialAdminPassword 2^>nul') DO SET INITIAL_PASSWORD=%%p

echo.
echo Jenkins Web UI: http://localhost:8080
IF "!INITIAL_PASSWORD!"=="" (
    echo WARNING: Initial password not ready yet. Check logs.
) ELSE (
    echo Initial Admin Password: !INITIAL_PASSWORD!
)

REM --- SHOW AGENT INFO ---
echo.
echo Agent Name   ^| IP Address
echo ----------------+----------------
FOR /F "delims=" %%a IN ('docker inspect -f "{{.NetworkSettings.Networks.%NETWORK_NAME%.IPAddress}}" %AGENT_NAME% 2^>nul') DO (
    IF "%%a"=="" (
        echo %AGENT_NAME%   ^| ERROR
    ) ELSE (
        echo %AGENT_NAME%   ^| %%a
    )
)

echo.
echo Jenkins master + agent restarted successfully.
pause