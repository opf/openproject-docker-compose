#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Antigravity Integrated Stack...${NC}"

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# 0. Gateway Password Setup
if [ -z "$GATEWAY_PASSWORD" ]; then
  echo -e "${BLUE}No GATEWAY_PASSWORD set. Using default: 'antigravity'${NC}"
  export GATEWAY_PASSWORD="antigravity"
fi

# Generate Bcrypt hash for Caddy (using docker to avoid local dependencies)
# We use caddy itself to hash the password
echo -e "${BLUE}Generating Gateway Password Hash...${NC}"
# Pull caddy image if not present (lightweight)
docker pull caddy:alpine > /dev/null 2>&1
GATEWAY_PASSWORD_HASH=$(docker run --rm caddy:alpine caddy hash-password --plaintext "$GATEWAY_PASSWORD")

# Fallback if hash generation failed
if [ -z "$GATEWAY_PASSWORD_HASH" ]; then
  echo -e "${BLUE}Hash generation failed. Using default hash for 'antigravity'.${NC}"
  GATEWAY_PASSWORD_HASH='$2a$14$cojdzwdxqMy.kC0FgoXOte.prm0GDkWA9w8rhdQm/a7oKuWBjtLp6'
fi

export GATEWAY_PASSWORD_HASH

# 1. Start the tunnel first to generate the URL
echo -e "${BLUE}Starting Cloudflare Tunnel...${NC}"
docker-compose -f docker-compose.stack.yml up -d tunnel

# 2. Wait for the URL to appear in the logs
echo -e "${BLUE}Waiting for Cloudflare Tunnel URL (this may take a few seconds)...${NC}"
TUNNEL_URL=""
while [ -z "$TUNNEL_URL" ]; do
  sleep 2
  # Extract URL from logs
  TUNNEL_URL=$(docker-compose -f docker-compose.stack.yml logs tunnel 2>&1 | grep -o "https://.*\.trycloudflare\.com" | tail -n 1)
done

# Remove https:// prefix for configuration
DOMAIN=${TUNNEL_URL#"https://"}

echo -e "${GREEN}Tunnel URL found: $TUNNEL_URL${NC}"

# 3. Update .env file
echo -e "${BLUE}Updating configuration with new URL...${NC}"
if [ -f .env ]; then
  sed -i "s|^OPENPROJECT_HOST__NAME=.*|OPENPROJECT_HOST__NAME=$DOMAIN|" .env
  sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" .env
  # Update Gateway User/Pass if not present
  if ! grep -q "GATEWAY_USER=" .env; then
    echo "GATEWAY_USER=admin" >> .env
  fi
else
  echo "Error: .env file not found!"
  exit 1
fi

# 4. Start the rest of the services
echo -e "${BLUE}Starting Integrated Stack services...${NC}"
# Pass the hash as an env var to the compose command
GATEWAY_PASSWORD_HASH="$GATEWAY_PASSWORD_HASH" docker-compose -f docker-compose.stack.yml up -d --remove-orphans --build

echo -e "${GREEN}----------------------------------------------------------------${NC}"
echo -e "${GREEN}Antigravity Stack is up and running!${NC}"
echo -e "${GREEN}Access it here: $TUNNEL_URL${NC}"
echo -e "${GREEN}Gateway Login: admin / $GATEWAY_PASSWORD${NC}"
echo -e "${GREEN}----------------------------------------------------------------${NC}"
