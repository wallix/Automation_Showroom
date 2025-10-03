# WALLIX Bastion - Simple Integration with Kubernetes/OpenShift

## 📋 Overview

This solution provides **simple and reliable** methods to integrate WALLIX Bastion with Kubernetes/OpenShift, **without complex external dependencies**.

> **💡 Self-Signed Certificates**: All examples include the `-k` (insecure) option for `curl` as WALLIX Bastion uses a self-signed certificate by default. For production, configure a valid certificate or add the CA to the container.

## ✅ Advantages of this Approach

- ✅ **Simple**: No external operator to install
- ✅ **Reliable**: Proven and maintainable solutions
- ✅ **Secure**: Secrets stored in memory, no persistent storage
- ✅ **Compatible**: Works on OpenShift and vanilla Kubernetes
- ✅ **Production-ready**: Ready to use immediately

## 🚀 Available Solutions

### 1. Init Container (Recommended)

**Use case**: Retrieve secrets at pod startup

**How it works**:

- An init container runs before the application
- Retrieves the secret from WALLIX Bastion via API
- Stores the secret in a shared volume (memory)
- The application reads the secret from the volume

**File**: `examples/init-container-wallix.yaml`

```bash
kubectl apply -f examples/init-container-wallix.yaml
```

### 2. CronJob Synchronization

**Use case**: Automatic secret synchronization and rotation

**How it works**:

- A CronJob runs periodically (e.g., every 15 min)
- Retrieves secrets from WALLIX Bastion
- Creates/updates Kubernetes secrets
- Applications use standard Kubernetes secrets

**File**: `examples/cronjob-wallix-sync.yaml`

```bash
kubectl apply -f examples/cronjob-wallix-sync.yaml
```

## 📚 Quick Start

### Prerequisites

1. Functional Kubernetes/OpenShift cluster
2. Network access to WALLIX Bastion
3. WALLIX API key with checkout permissions

### Step 1: Configuration

```bash
# Create secret with WALLIX API credentials
kubectl create secret generic wallix-api-credentials \
  --from-literal=api-user='admin' \
  --from-literal=api-key='YOUR_WALLIX_API_KEY' \
  -n default
```

### Step 2: Choose a Solution

#### Option A: Init Container

```bash
# 1. Edit the file examples/init-container-wallix.yaml
# Replace:
# - your-bastion.example.com → Your WALLIX Bastion URL
# - admin@db-postgres@prod.local → Your key (format: account@target@domain)

# 2. Apply
kubectl apply -f examples/init-container-wallix.yaml

# 3. Verify
kubectl get pods
kubectl logs <pod-name> -c fetch-wallix-password
```

#### Option B: CronJob

```bash
# 1. Edit the file examples/cronjob-wallix-sync.yaml
# Replace:
# - your-bastion.example.com → Your WALLIX Bastion URL
# - WALLIX keys in the ConfigMap sync.sh

# 2. Apply
kubectl apply -f examples/cronjob-wallix-sync.yaml

# 3. Test manually
kubectl create job --from=cronjob/wallix-secret-sync test-sync
kubectl logs -f job/test-sync

# 4. Verify created secrets
kubectl get secrets
```

## 🔧 WALLIX Bastion Configuration

### Key Format

**Format**: `account@target@domain`

**Examples**:

```ini
admin@db-postgres@prod.local
root@mysql-server@staging.local
apiuser@external-api@prod.local
deploy@gitserver@dev.local
```

### API Endpoint

```ini
GET /api/targetpasswords/checkout/{account}@{target}@{domain}

Headers:
  X-Auth-User: <api-username>
  X-Auth-Key: <your-api-key>
  Content-Type: application/json

Response:
{
  "password": "the-password"
}
```

### Manual Testing

#### **Method 1: With configuration file (recommended)**

```bash
# Copy the example
cp scripts/wallix-config.env.example scripts/wallix-config.env

# Edit with your values
vi scripts/wallix-config.env

# Test
./scripts/test-wallix-api.sh scripts/wallix-config.env
```

#### **Method 2: With environment variables**

```bash
BASTION_URL="https://bastion.example.com" \
API_USER="admin" \
API_KEY="your-key" \
SECRET_KEY="admin@server@domain" \
./scripts/test-wallix-api.sh
```

#### **Method 3: Interactive mode**

```bash
./scripts/test-wallix-api.sh
# The script will prompt for each value
```

## 📊 Solution Comparison

| Feature | Init Container | CronJob |
|---------|---------------|---------|
| **Use Case** | Secret at pod startup | Periodic rotation |
| **Complexity** | Low | Medium |
| **Rotation** | Manual (pod restart) | Automatic |
| **Dependencies** | None | kubectl |
| **Network** | At startup only | Periodic |
| **Best for** | Static apps | Dynamic secrets |

## 🚨 Troubleshooting

### Init Container: "Failed to fetch password"

```bash
# 1. Verify API key
kubectl get secret wallix-api-credentials -o jsonpath='{.data.api-key}' | base64 -d

# 2. Test API manually
curl -k -v \
  -H "X-Auth-User: $(kubectl get secret wallix-api-credentials -o jsonpath='{.data.api-user}' | base64 -d)" \
  -H "X-Auth-Key: $(kubectl get secret wallix-api-credentials -o jsonpath='{.data.api-key}' | base64 -d)" \
  "https://bastion.example.com/api/targetpasswords/checkout/account@domain@target"

# 3. View init container logs
kubectl logs <pod-name> -c fetch-wallix-password
kubectl describe pod <pod-name>
```

### CronJob: Not running

```bash
# Verify CronJob
kubectl get cronjob wallix-secret-sync
kubectl describe cronjob wallix-secret-sync

# Force manual execution
kubectl create job --from=cronjob/wallix-secret-sync manual-test
kubectl logs -f job/manual-test

# Verify RBAC permissions
kubectl auth can-i create secrets --as=system:serviceaccount:default:wallix-secret-sync
```

### Self-signed SSL certificate

```bash
# Add -k option to curl in manifests
curl -k -H "X-Auth-User: ..." -H "X-Auth-Key: ..." "https://..."

# Or add CA to container (recommended for production)
```

## 📁 Project Structure

```ini
WALLIX_Simple_Integration/
├── README.md                           # This file
├── examples/
│   ├── init-container-wallix.yaml      # Init container pattern
│   ├── cronjob-wallix-sync.yaml        # CronJob synchronization
│   └── test-wallix-connection.yaml     # Connection test pod
└── scripts/
    ├── README.md                       # Scripts documentation
    ├── test-wallix-api.sh             # API test script
    ├── deploy-init-container.sh       # Automated deployment
    └── wallix-config.env.example      # Configuration template
```

## 🔒 Security

- ✅ Secrets stored in memory (`emptyDir` with `medium: Memory`)
- ✅ No persistent storage of passwords
- ✅ Kubernetes RBAC for secret access
- ✅ API credentials in Kubernetes secrets
- ⚠️ Use `-k` only for dev/test (self-signed certs)
- ✅ For production: Configure valid certificates

## 🎯 Production Recommendations

1. **Certificates**: Use valid TLS certificates (remove `-k`)
2. **RBAC**: Limit service account permissions
3. **Rotation**: Configure appropriate CronJob schedule
4. **Monitoring**: Add health checks and alerts
5. **Backup**: Document credential recovery procedures

## 📚 Additional Resources

- [WALLIX Bastion API Documentation](https://doc.wallix.com/en/index.html)
- [Kubernetes Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Kubernetes CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

## 🤝 Contributing

Contributions are welcome! Please ensure:

- All examples use generic/template values
- Documentation is in English
- Code follows Kubernetes best practices
- Never commit real credentials

## 📝 License

This project is part of the WALLIX Automation Showroom.
