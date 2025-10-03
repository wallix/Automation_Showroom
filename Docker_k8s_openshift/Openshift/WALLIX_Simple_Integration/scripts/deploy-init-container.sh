#!/bin/bash
# WALLIX Init Container Quick Deployment Script
# Usage: ./deploy-init-container.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  WALLIX Bastion - Init Container Deployment  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"

# Configuration
read -p "WALLIX Bastion URL: " -r BASTION_URL
read -p "WALLIX API username: " -r WALLIX_API_USER
read -p "WALLIX API Key: " -rs WALLIX_API_KEY
echo
read -p "WALLIX key (format account@target@domain): " -r TARGET_KEY
read -p "Kubernetes namespace [default]: " -r NAMESPACE
NAMESPACE=${NAMESPACE:-default}
read -p "Application name [myapp]: " -r APP_NAME
APP_NAME=${APP_NAME:-myapp}

echo -e "\n${YELLOW}Configuration:${NC}"
echo "  Bastion:   $BASTION_URL"
echo "  API User:  $WALLIX_API_USER"
echo "  Namespace: $NAMESPACE"
echo "  App:       $APP_NAME"
echo "  Key:       $TARGET_KEY"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed${NC}"
    exit 1
fi

# Create namespace if needed
echo -e "\n${YELLOW}[1/3] Creating namespace...${NC}"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace ready${NC}"

# Create API secret
echo -e "\n${YELLOW}[2/3] Creating WALLIX API secret...${NC}"
kubectl create secret generic wallix-api-credentials \
    --from-literal=api-user="$WALLIX_API_USER" \
    --from-literal=api-key="$WALLIX_API_KEY" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Secret created${NC}"

# Create deployment
echo -e "\n${YELLOW}[3/3] Deploying application...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
    spec:
      initContainers:
      - name: fetch-wallix-secret
        image: curlimages/curl:latest
        command:
          - sh
          - -c
          - |
            set -e
            echo "Fetching secret from WALLIX Bastion..."
            PASSWORD=\$(curl -k -s -f \\
              -H "X-Auth-User: \$WALLIX_API_USER" \\
              -H "X-Auth-Key: \$WALLIX_API_KEY" \\
              -H "Content-Type: application/json" \\
              "\$BASTION_URL/api/targetpasswords/checkout/\$TARGET_KEY" \\
              | jq -r '.password')
            
            if [ -z "\$PASSWORD" ] || [ "\$PASSWORD" = "null" ]; then
              echo "ERROR: Failed to fetch password"
              exit 1
            fi
            
            echo "\$PASSWORD" > /secrets/password
            echo "Secret successfully fetched"
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
          value: "$TARGET_KEY"
        volumeMounts:
        - name: secrets
          mountPath: /secrets
      
      containers:
      - name: app
        image: busybox:latest
        command:
          - sh
          - -c
          - |
            export SECRET_PASSWORD=\$(cat /secrets/password)
            echo "Application starting with loaded secret..."
            echo "Password length: \$(echo -n \$SECRET_PASSWORD | wc -c) characters"
            # Your application logic here
            sleep 3600
        volumeMounts:
        - name: secrets
          mountPath: /secrets
          readOnly: true
      
      volumes:
      - name: secrets
        emptyDir:
          medium: Memory
EOF

echo -e "${GREEN}✓ Deployment created${NC}"

# Show status
echo -e "\n${YELLOW}Deployment Status:${NC}"
kubectl get deployment "$APP_NAME" -n "$NAMESPACE"
kubectl get pods -l app="$APP_NAME" -n "$NAMESPACE"

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Deployment completed successfully!   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "\n${BLUE}Useful commands:${NC}"
echo "  # View pod status"
echo "  kubectl get pods -l app=$APP_NAME -n $NAMESPACE"
echo ""
echo "  # View init container logs"
echo "  kubectl logs -l app=$APP_NAME -n $NAMESPACE -c fetch-wallix-secret"
echo ""
echo "  # View application logs"
echo "  kubectl logs -l app=$APP_NAME -n $NAMESPACE -c app"
echo ""
echo "  # Delete deployment"
echo "  kubectl delete deployment $APP_NAME -n $NAMESPACE"
