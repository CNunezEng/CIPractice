#!/bin/bash

# ============================
# Jenkins Master + Single Agent Setup (Git Bash Safe)
# ============================

set -e

# --- CONFIGURATION ---
MASTER_IMAGE="my-jenkins-master"
AGENT_IMAGE="my-jenkins-agent"
NETWORK_NAME="jenkins"
JENKINS_HOME="$(pwd)/jenkins-data"
SSH_PUBKEY="$(pwd)/jenkins.pub"
AGENT_NAME="jenkins-agent-1"
LOG_DIR="$(pwd)/logs"
MASTER_DOCKERFILE="JenkinsContainer/dockerfile"
AGENT_DOCKERFILE="AgentContainer/dockerfile"

# --- CREATE LOG DIRECTORY ---
mkdir -p "$LOG_DIR"

# --- VERIFY DOCKERFILES EXIST ---
if [ ! -f "$MASTER_DOCKERFILE" ]; then
    echo "ERROR: Jenkins Master Dockerfile not found at $MASTER_DOCKERFILE"
    exit 1
fi

if [ ! -f "$AGENT_DOCKERFILE" ]; then
    echo "ERROR: Jenkins Agent Dockerfile not found at $AGENT_DOCKERFILE"
    exit 1
fi

echo "Dockerfiles verified."

# --- CLEANUP ---
echo "Cleaning up previous Jenkins containers and network..."
docker stop jenkins-master "$AGENT_NAME" >/dev/null 2>&1 || true
docker rm jenkins-master "$AGENT_NAME" >/dev/null 2>&1 || true
docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true

# --- CREATE NETWORK ---
docker network create "$NETWORK_NAME" >/dev/null 2>&1
echo "Docker network '$NETWORK_NAME' ready."

# --- BUILD IMAGES ---
echo ""
echo "Building Jenkins Master..."
if ! docker build --progress=plain -t "$MASTER_IMAGE" -f "$MASTER_DOCKERFILE" . > "$LOG_DIR/master-build.log" 2>&1; then
    echo "ERROR: Failed to build Jenkins Master. Check logs/master-build.log"
    exit 1
fi

echo ""
echo "Building Jenkins Agent..."
if ! docker build --progress=plain -t "$AGENT_IMAGE" -f "$AGENT_DOCKERFILE" . > "$LOG_DIR/agent-build.log" 2>&1; then
    echo "ERROR: Failed to build Jenkins Agent. Check logs/agent-build.log"
    exit 1
fi

# --- START MASTER ---
echo ""
echo "Starting Jenkins Master..."
docker run -d --name jenkins-master \
    --network "$NETWORK_NAME" \
    -p 8080:8080 -p 50000:50000 \
    -v "$JENKINS_HOME:/var/jenkins_home" \
    "$MASTER_IMAGE" > "$LOG_DIR/master-run.log" 2>&1

echo "Waiting 30 seconds for Jenkins Master to initialize..."
sleep 30

# --- START AGENT (FIXED VERSION) ---
echo ""
echo "Starting agent: $AGENT_NAME..."
docker run -d --name "$AGENT_NAME" \
    --network "$NETWORK_NAME" \
    -e JENKINS_AGENT_SSH_PUBKEY="$(cat "$SSH_PUBKEY")" \
    "$AGENT_IMAGE" > "$LOG_DIR/agent-run.log" 2>&1

echo "Waiting 10 seconds for agent to register..."
sleep 10

# --- SHOW INITIAL PASSWORD ---
INITIAL_PASSWORD=$(docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || true)

echo ""
echo "Jenkins Web UI: http://localhost:8080"

if [ -z "$INITIAL_PASSWORD" ]; then
    echo "WARNING: Initial password not ready yet. Check logs."
else
    echo "Initial Admin Password: $INITIAL_PASSWORD"
fi

# --- SHOW AGENT INFO ---
echo ""
echo "Agent Name   | IP Address"
echo "-------------+----------------"

AGENT_IP=$(docker inspect -f "{{.NetworkSettings.Networks.$NETWORK_NAME.IPAddress}}" "$AGENT_NAME" 2>/dev/null || echo "ERROR")
echo "$AGENT_NAME   | $AGENT_IP"

echo ""
echo "Jenkins setup complete. Logs stored in $LOG_DIR"