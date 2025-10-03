#!/bin/bash
# WALLIX Bastion API Test Script
# Usage: 
#   ./test-wallix-api.sh                           # Interactive mode
#   ./test-wallix-api.sh config.env                # With config file
#   API_USER=admin API_KEY=xxx ./test-wallix-api.sh  # Environment variables

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== WALLIX Bastion API Test ===${NC}\n"

# Load from config file if provided
if [ -n "$1" ] && [ -f "$1" ]; then
    echo -e "${YELLOW}Loading configuration from: $1${NC}"
    # shellcheck source=/dev/null
    source "$1"
    echo ""
fi

# Configuration with environment variables or interactive prompts
if [ -z "$BASTION_URL" ]; then
    read -p "WALLIX Bastion URL (e.g., https://bastion.example.com): " -r BASTION_URL
fi

if [ -z "$API_USER" ]; then
    read -p "WALLIX API username (e.g., admin): " -r API_USER
fi

if [ -z "$API_KEY" ]; then
    read -p "WALLIX API Key: " -rs API_KEY
    echo
fi

if [ -z "$SECRET_KEY" ]; then
    read -p "Key to retrieve (format account@target@domain): " -r SECRET_KEY
fi

echo -e "${YELLOW}Configuration:${NC}"
echo "  Bastion URL: $BASTION_URL"
echo "  API User:    $API_USER"
echo "  Secret Key:  $SECRET_KEY"
echo "  API Key:     $(echo "$API_KEY" | cut -c1-10)..."

# Test 1: Connectivity
echo -e "\n${YELLOW}[1/3] Testing connectivity...${NC}"
if curl -k -s -o /dev/null -w "%{http_code}" "$BASTION_URL" | grep -q "200\|302\|401\|403"; then
    echo -e "${GREEN}✓ Bastion accessible${NC}"
else
    echo -e "${RED}✗ Cannot reach Bastion${NC}"
    exit 1
fi

# Test 2: Authentication
echo -e "\n${YELLOW}[2/3] Testing authentication...${NC}"
RESPONSE=$(curl -k -s -w "\n%{http_code}" \
    -H "X-Auth-User: $API_USER" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    "$BASTION_URL/api/targetpasswords/checkout/$SECRET_KEY")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Authentication successful${NC}"
else
    echo -e "${RED}✗ Authentication error (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
    exit 1
fi

# Test 3: Retrieve secret
echo -e "\n${YELLOW}[3/3] Retrieving secret...${NC}"
PASSWORD=$(echo "$BODY" | jq -r '.password' 2>/dev/null)

if [ -n "$PASSWORD" ] && [ "$PASSWORD" != "null" ]; then
    echo -e "${GREEN}✓ Secret retrieved successfully${NC}"
    echo -e "\n${GREEN}Result:${NC}"
    echo "  Password: $(echo "$PASSWORD" | cut -c1-5)... ($(echo "$PASSWORD" | wc -c) characters)"
else
    echo -e "${RED}✗ Unable to retrieve secret${NC}"
    echo "Raw response: $BODY"
    exit 1
fi

# Generate Kubernetes config
echo -e "\n${YELLOW}Kubernetes Configuration:${NC}"
cat <<EOF

# Secret with API credentials
apiVersion: v1
kind: Secret
metadata:
  name: wallix-api-credentials
  namespace: default
type: Opaque
stringData:
  api-user: "$API_USER"
  api-key: "$API_KEY"

# Usage example (Init Container)
env:
- name: WALLIX_API_USER
  valueFrom:
    secretKeyRef:
      name: wallix-api-credentials
      key: api-user
- name: WALLIX_API_KEY
  valueFrom:
    secretKeyRef:
      name: wallix-api-credentials
      key: api-key
- name: BASTION_URL
  value: "$BASTION_URL"
- name: TARGET_KEY
  value: "$SECRET_KEY"
EOF

echo -e "\n${GREEN}=== Test completed successfully ===${NC}"
