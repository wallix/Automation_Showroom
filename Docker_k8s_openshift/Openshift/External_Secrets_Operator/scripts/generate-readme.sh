#!/usr/bin/env bash

# ==============================================================================
# External Secrets Operator README Generator
# ==============================================================================
# This script generates a comprehensive README.md for the ESO configuration
# ==============================================================================

set -euo pipefail

# Configuration
OUTPUT_FILE="${OUTPUT_FILE:-README.md}"
INCLUDE_EXAMPLES="${INCLUDE_EXAMPLES:-true}"
INCLUDE_TROUBLESHOOTING="${INCLUDE_TROUBLESHOOTING:-true}"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate comprehensive README.md for External Secrets Operator configuration.

OPTIONS:
    -h, --help              Show this help
    -o, --output FILE       Output file (default: $OUTPUT_FILE)
    --no-examples           Skip examples section
    --no-troubleshooting    Skip troubleshooting section
    
ENVIRONMENT VARIABLES:
    OUTPUT_FILE             Output file path
    INCLUDE_EXAMPLES        Include examples (true/false)
    INCLUDE_TROUBLESHOOTING Include troubleshooting (true/false)

EOF
}

generate_readme() {
    cat << 'EOF' > "$OUTPUT_FILE"
# External Secrets Operator with WALLIX Bastion Integration

This repository contains a complete configuration setup for External Secrets Operator (ESO) integrated with WALLIX Bastion for enterprise-grade secret management in Kubernetes/OpenShift environments.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)

## 🔍 Overview

External Secrets Operator (ESO) automates the synchronization of secrets from external systems into Kubernetes secrets. This configuration provides seamless integration with WALLIX Bastion, enabling:

- **Automated Secret Sync**: Pull secrets from WALLIX Bastion into Kubernetes
- **Webhook Provider**: Custom HTTP integration with WALLIX API
- **Multiple Account Support**: Handle various account formats (account@target@domain)
- **Real-time Updates**: Automatic secret refresh and synchronization
- **Enterprise Security**: Production-ready RBAC and security configurations

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Kubernetes    │    │ WALLIX Bastion  │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│  │  Secret   │  │◄───┤ │ K8s Secret  │ │    │ │Target Passwd│ │
│  │   Usage   │  │    │ │             │ │    │ │   Storage   │ │
│  └───────────┘  │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    │        ▲        │    │        ▲        │
                       │        │        │    │        │        │
                       │ ┌─────────────┐ │    │        │        │
                       │ │ExternalSecret│ │    │        │        │
                       │ │             │ │    │        │        │
                       │ └─────────────┘ │    │        │        │
                       │        ▲        │    │        │        │
                       │        │        │    │        │        │
                       │ ┌─────────────┐ │    │        │        │
                       │ │SecretStore  │ │◄───┼────────┘        │
                       │ │(Webhook)    │ │    │                 │
                       │ └─────────────┘ │    │                 │
                       │        ▲        │    │                 │
                       │        │        │    │                 │
                       │ ┌─────────────┐ │    │                 │
                       │ │    ESO      │ │    │                 │
                       │ │ Controller  │ │    │                 │
                       │ └─────────────┘ │    │                 │
                       └─────────────────┘    └─────────────────┘
```

## ✅ Prerequisites

### Software Requirements

- **Kubernetes/OpenShift**: v1.20+ or OpenShift 4.6+
- **kubectl/oc**: Latest version
- **External Secrets Operator**: v0.9.8+
- **WALLIX Bastion**: API v3.12+

### Access Requirements

- Cluster admin privileges for ESO installation
- WALLIX Bastion API access with credentials
- Network connectivity from cluster to WALLIX Bastion

### WALLIX Configuration

- API user with appropriate permissions
- Target accounts configured in WALLIX
- Network access to WALLIX API endpoint (typically port 443)

## 🚀 Quick Start

### 1. Install External Secrets Operator

```bash
# Apply the installation manifests
kubectl apply -f install/namespace.yaml
kubectl apply -f install/rbac.yaml
kubectl apply -f install/operator-install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=external-secrets -n external-secrets-system --timeout=300s
```

### 2. Configure WALLIX Credentials

```bash
# Create WALLIX credentials secret
kubectl create secret generic wallix-bastion-credentials \
  --from-literal=username='your-api-user' \
  --from-literal=password='your-api-password' \
  --from-literal=host='your-wallix-host' \
  --from-literal=port='443' \
  -n external-secrets-system
```

### 3. Create SecretStore

```bash
# Apply SecretStore configuration
kubectl apply -f secretstore/wallix-secretstore.yaml
```

### 4. Create Your First ExternalSecret

```bash
# Apply an example ExternalSecret
kubectl apply -f externalsecrets/database-secret.yaml
```

### 5. Verify Installation

```bash
# Run connection test
./scripts/test-connection.sh

# Validate secrets
./scripts/validate-secrets.sh
```

## 📁 Directory Structure

```
.
├── install/                    # ESO installation manifests
│   ├── namespace.yaml         # External Secrets namespace
│   ├── rbac.yaml             # RBAC configuration
│   └── operator-install.yaml # ESO deployment and CRDs
│
├── secretstore/               # SecretStore configurations
│   ├── wallix-credentials.yaml # WALLIX credentials secret
│   └── wallix-secretstore.yaml # SecretStore definitions
│
├── externalsecrets/           # ExternalSecret examples
│   ├── database-secret.yaml  # Database credentials
│   ├── application-secret.yaml # Application secrets
│   └── tls-certificate.yaml  # TLS certificates
│
├── examples/                  # Usage examples
│   ├── deployment-example.yaml # Deployment with secrets
│   └── configmap-example.yaml # ConfigMap examples
│
├── scripts/                   # Utility scripts
│   ├── test-connection.sh     # Connection testing
│   ├── validate-secrets.sh    # Secret validation
│   ├── cleanup.sh            # Resource cleanup
│   └── monitor.sh            # Monitoring script
│
└── README.md                  # This file
```

## 📦 Installation

### Step 1: Namespace and RBAC

The External Secrets Operator requires its own namespace and appropriate RBAC permissions.

```bash
# Create namespace
kubectl apply -f install/namespace.yaml

# Apply RBAC configuration
kubectl apply -f install/rbac.yaml
```

### Step 2: Install External Secrets Operator

```bash
# Install CRDs and operator
kubectl apply -f install/operator-install.yaml

# Verify installation
kubectl get pods -n external-secrets-system
```

### Step 3: Configure WALLIX Credentials

Create a secret containing WALLIX Bastion credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wallix-bastion-credentials
  namespace: external-secrets-system
type: Opaque
stringData:
  username: "your-api-username"
  password: "your-api-password"
  host: "your-wallix-host.example.com"
  port: "443"
```

### Step 4: Create SecretStore

Apply the SecretStore configuration to establish connection to WALLIX Bastion:

```bash
kubectl apply -f secretstore/wallix-secretstore.yaml
```

## ⚙️ Configuration

### SecretStore Configuration

The SecretStore defines how ESO connects to WALLIX Bastion:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: wallix-bastion-store
spec:
  provider:
    webhook:
      url: "https://{{ .host }}:{{ .port }}/api/targetpasswords/checkout/{{ .remoteRef.key }}"
      method: GET
      headers:
        Accept: "application/json"
        X-Auth-User: "{{ .authUser }}"
        X-Auth-Key: "{{ .authKey }}"
      secrets:
      - name: authUser
        secretRef:
          name: wallix-bastion-credentials
          key: username
      - name: authKey
        secretRef:
          name: wallix-bastion-credentials
          key: password
      result:
        jsonPath: "$.password"
```

### Account Specifier Format

WALLIX accounts are specified using the format: `account@target@domain`

Examples:
- `root@local@debian` - Root account on local debian target
- `postgres@dbserver@prod` - PostgreSQL account on production database
- `admin@webserver@staging` - Admin account on staging web server

EOF

    if [[ "$INCLUDE_EXAMPLES" == "true" ]]; then
        cat << 'EOF' >> "$OUTPUT_FILE"

## 📚 Usage Examples

### Database Credentials

Sync PostgreSQL credentials from WALLIX:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: postgres-credentials
  namespace: production
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: wallix-bastion-store
    kind: SecretStore
  
  target:
    name: postgres-secret
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        POSTGRES_URL: "postgresql://postgres:{{ .password }}@postgres:5432/myapp"
        POSTGRES_PASSWORD: "{{ .password }}"
        POSTGRES_USER: "postgres"
  
  data:
  - secretKey: password
    remoteRef:
      key: "postgres@dbserver@prod"
```

### Application Secrets

Sync application secrets for microservices:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: webapp-secrets
  namespace: production
spec:
  refreshInterval: 30m
  secretStoreRef:
    name: wallix-bastion-store
    kind: SecretStore
  
  target:
    name: webapp-secret
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        JWT_SECRET: "{{ .jwt_secret }}"
        SESSION_KEY: "{{ .session_key }}"
        API_TOKEN: "{{ .api_token }}"
  
  data:
  - secretKey: jwt_secret
    remoteRef:
      key: "webapp@appserver@prod"
  - secretKey: session_key
    remoteRef:
      key: "session@appserver@prod"
  - secretKey: api_token
    remoteRef:
      key: "api@gateway@prod"
```

### TLS Certificates

Manage TLS certificates from WALLIX:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: tls-certificates
  namespace: production
spec:
  refreshInterval: 24h
  secretStoreRef:
    name: wallix-bastion-store
    kind: SecretStore
  
  target:
    name: webapp-tls
    creationPolicy: Owner
    template:
      type: kubernetes.io/tls
      data:
        tls.crt: "{{ .certificate }}"
        tls.key: "{{ .private_key }}"
  
  data:
  - secretKey: certificate
    remoteRef:
      key: "cert@webserver@prod"
  - secretKey: private_key
    remoteRef:
      key: "key@webserver@prod"
```

### Using Secrets in Deployments

Example of consuming synced secrets in a Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: webapp:latest
        env:
        - name: POSTGRES_URL
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_URL
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: webapp-secret
              key: JWT_SECRET
        volumeMounts:
        - name: tls-certs
          mountPath: "/etc/ssl/certs"
          readOnly: true
      volumes:
      - name: tls-certs
        secret:
          secretName: webapp-tls
```

EOF
    fi

    if [[ "$INCLUDE_TROUBLESHOOTING" == "true" ]]; then
        cat << 'EOF' >> "$OUTPUT_FILE"

## 📊 Monitoring

### Built-in Monitoring

Use the provided monitoring script for continuous health checks:

```bash
# Basic monitoring
./scripts/monitor.sh

# Monitor all namespaces with verbose output
./scripts/monitor.sh -a -v

# Monitor with webhook alerts (Slack, Teams, etc.)
./scripts/monitor.sh -w "https://hooks.slack.com/services/..."

# Generate health report
./scripts/monitor.sh report
```

### Key Metrics to Monitor

- **ESO Pod Health**: External Secrets Operator pod status
- **SecretStore Status**: WALLIX connectivity and authentication
- **ExternalSecret Status**: Individual secret synchronization status
- **Refresh Times**: Last successful secret refresh timestamps
- **Error Rates**: Failed synchronization attempts

### Alerting

The monitoring script supports webhook alerts for:
- ESO pod failures
- WALLIX connectivity issues
- Stale secrets (not refreshed within threshold)
- ExternalSecret synchronization failures

## 🔧 Troubleshooting

### Common Issues

#### 1. ESO Pods Not Running

```bash
# Check pod status
kubectl get pods -n external-secrets-system

# Check pod logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets

# Check events
kubectl get events -n external-secrets-system --sort-by='.firstTimestamp'
```

#### 2. WALLIX Connection Issues

```bash
# Test WALLIX connectivity
./scripts/test-connection.sh

# Check SecretStore status
kubectl describe secretstore wallix-bastion-store -n production

# Verify credentials
kubectl get secret wallix-bastion-credentials -n external-secrets-system -o yaml
```

#### 3. ExternalSecret Not Syncing

```bash
# Check ExternalSecret status
kubectl describe externalsecret <name> -n <namespace>

# Check ExternalSecret logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets

# Validate secret content
./scripts/validate-secrets.sh -n <namespace>
```

#### 4. Secret Not Updated

```bash
# Force refresh by updating annotation
kubectl annotate externalsecret <name> -n <namespace> \
  external-secrets.io/force-refresh=$(date +%s)

# Check refresh interval
kubectl get externalsecret <name> -n <namespace> -o yaml | grep refreshInterval

# Monitor refresh status
watch kubectl get externalsecret <name> -n <namespace>
```

### Debugging Commands

```bash
# Get all ESO resources
kubectl get externalsecrets,secretstores --all-namespaces

# Check WALLIX API directly
curl -k -u "username:password" \
  "https://wallix-host:443/api/targetpasswords/checkout/account@target@domain"

# Validate JSON parsing
echo '{"password": "test123"}' | jq -r '.password'

# Test webhook manually
curl -k -X GET \
  -H "Accept: application/json" \
  -u "username:password" \
  "https://wallix-host:443/api/targetpasswords/checkout/account@target@domain"
```

### Log Analysis

```bash
# ESO controller logs
kubectl logs -n external-secrets-system deployment/external-secrets \
  --tail=100 --follow

# Filter for specific ExternalSecret
kubectl logs -n external-secrets-system deployment/external-secrets \
  | grep "externalsecret-name"

# Check for authentication errors
kubectl logs -n external-secrets-system deployment/external-secrets \
  | grep -i "auth\|401\|403"
```

### Performance Tuning

1. **Refresh Intervals**: Adjust based on secret change frequency
2. **Timeout Settings**: Configure appropriate timeouts for WALLIX API
3. **Resource Limits**: Set appropriate CPU/memory limits for ESO pods
4. **Batch Operations**: Group related secrets to reduce API calls

## 🔒 Security Considerations

### Credential Management

- Store WALLIX credentials in Kubernetes secrets
- Use RBAC to restrict access to credential secrets
- Rotate WALLIX API credentials regularly
- Monitor credential usage and access patterns

### Network Security

- Use TLS for all WALLIX API communication
- Implement network policies to restrict ESO traffic
- Consider using service mesh for additional security
- Monitor network traffic to WALLIX endpoints

### Secret Protection

- Use appropriate secret types (Opaque, TLS, etc.)
- Implement secret encryption at rest
- Regular secret rotation through WALLIX
- Monitor secret access and usage

### RBAC Configuration

- Minimal permissions for ESO service accounts
- Namespace isolation for different environments
- Regular RBAC audits and reviews
- Separate credentials for different environments

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Environment

```bash
# Set up test environment
kubectl create namespace eso-test

# Run tests
./scripts/test-connection.sh -n eso-test
./scripts/validate-secrets.sh -n eso-test

# Clean up
./scripts/cleanup.sh -n eso-test
```

### Testing Guidelines

- Test all SecretStore configurations
- Validate ExternalSecret templates
- Verify RBAC permissions
- Test error scenarios and recovery
- Performance testing with multiple secrets

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Check WALLIX Bastion documentation
- Review External Secrets Operator documentation
- Check Kubernetes/OpenShift logs and events

EOF
    fi

    echo "README.md generated successfully: $OUTPUT_FILE"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --no-examples)
                INCLUDE_EXAMPLES="false"
                shift
                ;;
            --no-troubleshooting)
                INCLUDE_TROUBLESHOOTING="false"
                shift
                ;;
            -*)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
            *)
                echo "Unexpected argument: $1" >&2
                usage
                exit 1
                ;;
        esac
    done
    
    generate_readme
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi